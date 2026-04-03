# SocialApp MVP — Feature Overview

## Authentication & Accounts

- User registration with username, email, and password
- Login and logout
- Session-based authentication
- All app features require login

---

## Feed

- Scrollable feed of posts from all users
- Create posts with text and optional image/video media
- Like and unlike posts with real-time count updates
- Paginated feed with "Load more" for infinite scrolling
- Each post displays author info, timestamp, media preview, and engagement counts

---

## Stories

- Users can post stories that auto-expire after 24 hours
- Stories appear as a row of circular avatars at the top of the feed
- Tap to open a full-screen story viewer
- Stories auto-advance and can be closed manually

---

## Reels (Short Videos)

- Full-screen vertical video feed with snap-scroll behavior
- Two tabs: "For You" (ranked by engagement) and "Following" (from people you follow)
- Upload reels with video file and caption
- Like reels with real-time count updates
- Engagement-based ranking: likes, comments, views, and recency all factor in

---

## Explore & Discovery

- Search for users by username or display name with real-time results
- "Suggested for You" section showing users you don't follow yet, ranked by popularity
- Follow or unfollow users directly from search results and suggestions

---

## User Profiles

- View any user's profile: cover photo, avatar, display name, username, bio, and location
- Stats display: followers, following, and post count
- Tap stats to view follower/following lists with the ability to follow/unfollow from the list
- User's posts displayed in a photo grid
- Edit your own profile: display name, bio, location, avatar, and cover photo

---

## Notifications

- Notifications for follows, likes, comments, mentions, and messages
- Unread notifications highlighted with a distinct background
- Notifications auto-marked as read when viewed
- Relative timestamps (e.g., "5m ago", "2h ago")
- Unread count badge shown in navigation

---

## Messaging

- Direct messages and group conversations
- Conversation list showing last message preview, timestamp, and unread count
- Real-time message delivery
- Image sharing within chats
- Typing indicators (shows when the other person is typing)
- Read receipts (single check for sent, double check for read)
- Auto-scroll to the latest message
- Unread count badge shown in navigation

---

## Voice & Video Calls

- Initiate voice or video calls with other users
- Incoming call screen with accept and decline options
- Active call controls: mute, camera toggle (video calls), end call
- Video calls show remote video full-screen with a local video picture-in-picture
- Voice calls display caller avatar with visual pulse animation
- Live call duration timer
- Call state management: ringing, active, ended, declined

---

## Navigation & Layout

- **Mobile**: bottom navigation bar with five tabs — Home, Reels, Create Post, Messages, Profile
- **Desktop**: left sidebar with search bar, navigation links, "Create Post" button, and user info
- **Desktop (large screens)**: right panel with stories and suggested users
- Responsive design that adapts across mobile, tablet, and desktop
- RTL (right-to-left) language support

---

## Social Features

- Follow and unfollow users
- Follower and following counts updated in real-time
- Like posts and reels
- Follow actions generate notifications for the recipient
- User suggestions based on follower count

---

## Design

- Dark theme throughout the app
- Two-font system: Sora for headings, DM Sans for body text
- Green as the primary accent color, gold for create/publish actions
- Mobile-first responsive design
- Smooth transitions and optimistic UI updates for instant feedback
