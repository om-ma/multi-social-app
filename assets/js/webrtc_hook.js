import { Socket } from "phoenix";

const WebRTCHook = {
  mounted() {
    this.pc = null;
    this.localStream = null;
    this.channel = null;
    this.socket = null;

    const callId = this.el.dataset.callId;
    const userId = this.el.dataset.userId;
    const isCaller = this.el.dataset.isCaller === "true";
    const callType = this.el.dataset.callType || "video";
    const turnUrl = this.el.dataset.turnUrl || "";
    const turnApiKey = this.el.dataset.turnApiKey || "";

    this.callType = callType;
    this.isCaller = isCaller;

    // Build ICE servers config
    const iceServers = [{ urls: "stun:stun.l.google.com:19302" }];
    if (turnUrl) {
      iceServers.push({
        urls: turnUrl,
        username: turnApiKey,
        credential: turnApiKey,
      });
    }

    this.iceConfig = { iceServers };

    // Connect to Phoenix channel
    this.socket = new Socket("/socket", {
      params: { user_id: userId },
    });
    this.socket.connect();
    this.channel = this.socket.channel(`call:${callId}`, {});

    this.channel.on("offer", (msg) => this.handleOffer(msg));
    this.channel.on("answer", (msg) => this.handleAnswer(msg));
    this.channel.on("ice_candidate", (msg) => this.handleRemoteIce(msg));
    this.channel.on("call_ended", (_msg) => this.handleCallEnded());
    this.channel.on("call_declined", (_msg) => this.handleCallDeclined());

    this.channel
      .join()
      .receive("ok", () => {
        console.log("Joined call channel");
        this.startMedia();
      })
      .receive("error", (resp) => {
        console.error("Failed to join call channel", resp);
      });

    // Listen for LiveView events
    this.handleEvent("toggle_mute", () => this.toggleMute());
    this.handleEvent("toggle_camera", () => this.toggleCamera());
    this.handleEvent("end_call", () => this.endCall());
    this.handleEvent("accept_call", () => this.acceptCall());
    this.handleEvent("decline_call", () => this.declineCall());
  },

  async startMedia() {
    const constraints =
      this.callType === "voice"
        ? { audio: true, video: false }
        : { audio: true, video: true };

    try {
      this.localStream = await navigator.mediaDevices.getUserMedia(constraints);
      const localVideo = document.getElementById("local-video");
      if (localVideo && this.localStream) {
        localVideo.srcObject = this.localStream;
      }

      this.setupPeerConnection();

      if (this.isCaller) {
        this.createOffer();
      }
    } catch (err) {
      console.error("Failed to get media:", err);
      this.pushEvent("media_error", { error: err.message });
    }
  },

  setupPeerConnection() {
    this.pc = new RTCPeerConnection(this.iceConfig);

    // Add local tracks
    if (this.localStream) {
      this.localStream.getTracks().forEach((track) => {
        this.pc.addTrack(track, this.localStream);
      });
    }

    // Handle remote tracks
    this.pc.ontrack = (event) => {
      const remoteVideo = document.getElementById("remote-video");
      const remoteAudio = document.getElementById("remote-audio");
      if (remoteVideo && event.streams[0]) {
        remoteVideo.srcObject = event.streams[0];
      } else if (remoteAudio && event.streams[0]) {
        remoteAudio.srcObject = event.streams[0];
      }
    };

    // Handle ICE candidates
    this.pc.onicecandidate = (event) => {
      if (event.candidate) {
        this.channel.push("ice_candidate", {
          candidate: JSON.stringify(event.candidate),
        });
      }
    };

    // Handle connection state
    this.pc.onconnectionstatechange = () => {
      const state = this.pc.connectionState;
      this.pushEvent("connection_state", { state });

      if (state === "connected") {
        this.pushEvent("call_connected", {});
      } else if (state === "disconnected" || state === "failed") {
        this.pushEvent("call_disconnected", {});
      }
    };

    this.pc.oniceconnectionstatechange = () => {
      const state = this.pc.iceConnectionState;
      console.log("ICE connection state:", state);
    };
  },

  async createOffer() {
    try {
      const offer = await this.pc.createOffer();
      await this.pc.setLocalDescription(offer);
      this.channel.push("offer", { sdp: JSON.stringify(offer) });
    } catch (err) {
      console.error("Error creating offer:", err);
    }
  },

  async handleOffer(msg) {
    try {
      if (!this.pc) {
        this.setupPeerConnection();
      }
      const offer = JSON.parse(msg.sdp);
      await this.pc.setRemoteDescription(new RTCSessionDescription(offer));
      const answer = await this.pc.createAnswer();
      await this.pc.setLocalDescription(answer);
      this.channel.push("answer", { sdp: JSON.stringify(answer) });
    } catch (err) {
      console.error("Error handling offer:", err);
    }
  },

  async handleAnswer(msg) {
    try {
      const answer = JSON.parse(msg.sdp);
      await this.pc.setRemoteDescription(new RTCSessionDescription(answer));
    } catch (err) {
      console.error("Error handling answer:", err);
    }
  },

  async handleRemoteIce(msg) {
    try {
      const candidate = JSON.parse(msg.candidate);
      await this.pc.addIceCandidate(new RTCIceCandidate(candidate));
    } catch (err) {
      console.error("Error adding ICE candidate:", err);
    }
  },

  toggleMute() {
    if (this.localStream) {
      this.localStream.getAudioTracks().forEach((track) => {
        track.enabled = !track.enabled;
      });
      const muted = !this.localStream.getAudioTracks()[0]?.enabled;
      this.pushEvent("mute_toggled", { muted: !!muted });
    }
  },

  toggleCamera() {
    if (this.localStream) {
      this.localStream.getVideoTracks().forEach((track) => {
        track.enabled = !track.enabled;
      });
      const cameraOff = !this.localStream.getVideoTracks()[0]?.enabled;
      this.pushEvent("camera_toggled", { camera_off: !!cameraOff });
    }
  },

  endCall() {
    this.channel.push("call_end", {});
  },

  acceptCall() {
    this.startMedia();
  },

  declineCall() {
    this.channel.push("call_decline", {});
  },

  handleCallEnded() {
    this.cleanup();
    this.pushEvent("call_ended_remote", {});
  },

  handleCallDeclined() {
    this.cleanup();
    this.pushEvent("call_declined_remote", {});
  },

  cleanup() {
    if (this.localStream) {
      this.localStream.getTracks().forEach((track) => track.stop());
      this.localStream = null;
    }
    if (this.pc) {
      this.pc.close();
      this.pc = null;
    }
    if (this.channel) {
      this.channel.leave();
      this.channel = null;
    }
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
  },

  destroyed() {
    this.cleanup();
  },
};

export default WebRTCHook;
