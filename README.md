# TLU Calendar (Miho's Version)

TLU Calendar is an unofficial scheduling and academic management application built for students of Thuy Loi University (TLU). It provides an intuitive interface to access course schedules, exam timetables, academic grades, and course registration.

This repository is a comprehensive refactor of the original application, focusing on modernizing the UI/UX, improving application performance, and implementing robust offline capabilities.

## Key Features

- **Schedule Management**: View weekly course timetables and exam schedules with offline caching.
- **Academic Grades & Analytics**: Access semester grades, analyze academic performance over time, and simulate future GPA goals.
- **Quick Access Tools**: Course registration and grade tracking available directly from the Today screen.
- **Customizable Experience**: Full system-level light and dark mode support with dynamic theming.
- **Personal Notes**: Attach personal notes to specific course sessions and exams directly on the calendar.

## Comprehensive Refactoring Journey

This project has undergone significant architectural and visual improvements to provide a more stable and aesthetically pleasing experience. The changes span across several core domains of the application.

### 1. Modernized User Interface (UI/UX)
- **Apple HIG & ForUI Integration**: The entire application interface was redesigned using the `forui` package to adhere to Apple's Human Interface Guidelines.
- **Liquid Glass Tab Bar**: Implemented a floating, translucent tab bar for seamless bottom navigation.
- **Setup Wizard**: Introduced a comprehensive onboarding flow for first-time users to configure credentials and preferences easily.
- **Dynamic Theming**: Removed all hardcoded colors. The application now strictly uses `Theme.of(context).colorScheme` to ensure perfect contrast and visual hierarchy in both Light and Dark modes.
- **Typography & Layout**: Redesigned course cards, timeline items, and exam schedules to display critical information (e.g., start/end times, locations) more clearly with improved padding and visual boundaries.

### 2. Robust Caching & Offline Mode
- **Database-Backed Storage**: Replaced rudimentary caching with a structured SQLite database (`DatabaseHelper`). Course schedules, exam data, and grades are now stored locally.
- **Offline-First Approach**: The application immediately loads data from the local database upon launch, ensuring instant access even without an active internet connection.
- **Smart Refreshing**: Integrated pull-to-refresh mechanisms across all major screens.
- **Secure Session Management**: Ensured that logging out completely clears all cached local data to maintain user privacy.

### 3. Core Logic & Bug Fixes
- **Semester Auto-Detection**: Fixed a critical bug in the TLU API parsing where the application would incorrectly default to "Chuẩn đầu ra" (Exit Requirements) instead of the main academic semester. The logic now strictly filters and prioritizes standard semesters.
- **Calendar Marker Accuracy**: Resolved ghosting issues with calendar note indicators by implementing composite primary keys.
- **Scroll View Optimizations**: Eliminated "invisible scroll" bugs by replacing static oversized paddings with dynamic `SliverSafeArea` configurations, ensuring content naturally scrolls behind the translucent tab bar.
- **Platform Compatibility**: Fixed initialization crashes on desktop/Linux environments caused by unsupported notification plugins.

### 4. Advanced Grade Analytics
- **GPA Simulation**: Added a new analytics dashboard that allows students to view their GPA progression, set graduation goals, and manually simulate how upcoming grades will affect their final cumulative GPA.

### 5. Developer Tools & CI/CD
- **Developer Mode**: Built a hidden developer menu (accessible by tapping the version number in settings 5 times) to view application logs and manage backup/restore operations.
- **Automated Builds**: Streamlined the `.github/workflows/release_main.yaml` CI/CD pipeline. The repository now automatically compiles and publishes a ready-to-install Android APK on GitHub Releases whenever new code is merged to the main branch.

## Credits & Acknowledgments

This refactor was built upon the foundation of the original TLU Calendar project.
- **Original Author**: nekkochan0x0007
- **Original Source**: https://gitlab.com/nekkochan0x0007/tlucalendar

- **Refactor Authors**: Nguyen Duy Thanh & Dang Quang Hien (Miho)
