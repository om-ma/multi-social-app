# Manual Call Test Script

## Prerequisites

- The application is running locally (`mix phx.server`)
- Two test user accounts exist (e.g., "alice" and "bob")
- METERED_TURN_URL and METERED_API_KEY environment variables are set (optional for local testing)
- Two browser windows or tabs available (use different browsers or one incognito window to maintain separate sessions)

## Setup

1. Open Browser A and log in as "alice" at http://localhost:4000/login
2. Open Browser B and log in as "bob" at http://localhost:4000/login
3. Note the user IDs for both users from the database

## Test 1: Video Call - Full Flow

1. Create a call record (via iex or DB):
   ```elixir
   SocialApp.Calls.create_call(%{caller_id: alice_id, receiver_id: bob_id, call_type: "video"})
   ```
2. Note the returned call ID
3. In Browser A (alice/caller): navigate to http://localhost:4000/call/{call_id}
4. In Browser B (bob/receiver): navigate to http://localhost:4000/call/{call_id}
5. **Expected (Browser B):** Incoming call overlay with bob's avatar, pulse animation, Accept and Decline buttons
6. **Expected (Browser A):** Call screen showing "Ringing..." status, remote video area (black), local video PiP (showing alice's camera)
7. Click "Accept" in Browser B
8. **Expected:** Both browsers show the active call with remote video from the other party, call timer counting up
9. Test "Mute" button in either browser - verify the mute icon toggles
10. Test "Camera Toggle" button - verify the camera icon toggles and the local video freezes/unfreezes
11. Click "End Call" (red button) in either browser
12. **Expected:** Both browsers navigate to /messages

## Test 2: Voice Call

1. Create a voice call:
   ```elixir
   SocialApp.Calls.create_call(%{caller_id: alice_id, receiver_id: bob_id, call_type: "voice"})
   ```
2. Navigate both browsers to http://localhost:4000/call/{call_id}
3. Accept in Browser B
4. **Expected:** Large avatar displayed with pulse animation (no video elements), audio working
5. **Expected:** Control bar shows Mute, End Call, Speaker (no Camera toggle)
6. End the call

## Test 3: Decline Call

1. Create a new call record
2. Navigate both browsers to the call URL
3. Click "Decline" in Browser B
4. **Expected:** Both browsers navigate to /messages
5. **Verify in DB:** Call status is "declined"

## Test 4: Authorization

1. Create a call between alice and bob
2. Log in as a third user "charlie" in a new browser
3. Navigate to the call URL
4. **Expected:** Error/redirect (charlie is not a participant)

## Test 5: Call History

Verify in iex:
```elixir
SocialApp.Calls.list_call_history(alice_id)
```
Should return all calls where alice was caller or receiver, ordered by most recent first, with preloaded user data.

## Troubleshooting

- If video/audio does not work, check browser permissions for camera and microphone
- Check the browser console for WebRTC errors
- For cross-network testing, TURN server credentials must be configured
- Ensure both browsers have granted media permissions before accepting/starting the call
