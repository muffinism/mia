1. APP NAME
MIA – Rhythm Game with Progression & Skill Rating

2. PROBLEM STATEMENT
Most mobile rhythm games today focus heavily on fast-paced gameplay and flashy visuals. However, they often lack:
- Player progress tracking and long-term engagement
- Secure login systems and cloud-based score storage
- Player rating systems that encourage continuous improvement

3. APP CONCEPT

MIA is a rhythm-based mobile game inspired by Piano Tiles, but designed with a stronger sense of progression, personalization, and competitive features.

Key components include responsive music and beatmap mechanics, addictive gameplay with various note types (normal, hold, and SLAM), Firebase-based login and cloud storage, and immersive visuals using neon glow effects and smooth transitions.

4. CORE FEATURES
- Piano-Tile Rhythm Game: Tap notes in sync with the beat. Supports normal, hold, and slam notes
- Firebase Login: Secure authentication via Google or email
- Cloud Score Storage: Player scores, ratings, and stats are saved in Firebase
- Player Rating System: Scores are converted into ranks such as Perfect, Good, OK, Miss, and SLAM
- Leaderboard (Upcoming): Global ranking system powered by Firebase
- Neon UI and Snowball Effects: Neon glowing visual style with animated effects
- Smooth Transitions: Seamless flow between start menu, gameplay, pause, and resume
- Player Performance Analytics: Displays player accuracy, longest streaks, and song-specific ratings

5. TECHNOLOGIES USED
- Flutter + Flame: UI and core game engine
- Firebase Auth: User authentication
- Firebase Firestore/RTDB: Score and progression storage
- Firebase Storage (optional): Store beatmaps or user-generated content
- ValueNotifier / StreamBuilder: Real-time state management for UI and game status

6. BUSINESS MODEL (Future Development)
- Rewarded Ads: Users can watch ads to retry, unlock new songs, or receive cosmetic items
- Premium Content Unlock: Offers exclusive songs, advanced training modes, and more stats
- Premium Leaderboard Access: Monthly competitions with virtual rewards such as skins or badges

7. WHAT MAKES IT UNIQUE?

MIA encourages long-term engagement by saving player data and allowing performance tracking. Its visually immersive design includes neon glow effects, and its SLAM note mode brings a unique mechanic not found in many similar games. The architecture is also modular, enabling future expansion into PvP battles, custom song uploads, and online community features.
