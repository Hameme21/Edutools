# EduTools - Smart Academic Calendar, Routine Sync & Campus Reminder Suite

**EduTools** is an institutional-grade academic scheduling, timetable management, and automated reminder suite built with **Flutter & Dart** alongside a companion **All-in-One Web Application** and a **Node.js University Auth Backend**.

Designed specifically for students, faculty, and administrative departments (with dedicated support for **United International University - UIU (`uiu.ac.bd`)** and institutional `.edu` domains), EduTools integrates recurring weekly class timetables with official university calendars, auto-suspends classes during exam periods and semester breaks, resolves holiday conflicts, and delivers proactive notifications.

---

## 🌟 Evolution & Architecture Overview

EduTools has grown from a local calendar viewer into an end-to-end multi-platform academic companion:

```
                      ┌─────────────────────────────────────────┐
                      │             EduTools Ecosystem            │
                      └────────────────────┬────────────────────┘
                                           │
         ┌─────────────────────────────────┼─────────────────────────────────┐
         │                                 │                                 │
         ▼                                 ▼                                 ▼
┌──────────────────┐             ┌──────────────────┐             ┌──────────────────┐
│   Flutter App    │             │  All-in-One Web  │             │ University Auth  │
│ (Android/iOS/PC) │◄───Sync────►│  (GitHub Pages)  │◄───Auth────►│  Node.js Backend │
│  Material 3 UI   │             │   index.html     │             │    Port: 3097    │
└──────────────────┘             └──────────────────┘             └──────────────────┘
```

---

## 🚀 Key Features

### 1. 📅 Interactive Gesture-Driven Dashboard & Calendar
- **Smooth Swipe Navigation**: Left/right horizontal touch gestures to cycle through months seamlessly.
- **Direct Date Inspection**: Tap any date cell to view all scheduled events, classes, and notices for that specific day without unwanted month snapping.
- **Adaptive Responsive Stat Cards**: 'Classes Today', 'Holidays Left', and 'Fee Deadlines' dynamically adapt into 1 or 2 compact horizontal spaces, eliminating layout overflows even on compact screens (320x568) and under 1.5x font accessibility scaling.
- **Next Milestone Countdown**: Live countdown badge indicating days remaining until upcoming critical academic events.

### 2. ⚡ Intelligent Academic Lifecycle & Routine Auto-Figure Engine
- **Intelligent Routine Window Auto-Figuring**:
  - When a user uploads a class routine (via `.ics`, JSON, CSV, or presets), EduTools dynamically inspects the official university academic calendar.
  - If the **current date is after classes are suspended**, EduTools automatically figures the full routine span from **Semester Begin** until **the day before class suspension / Final Examination**.
  - Provides a prompt/dialog (`RoutineDateConfigDialog` / `#routineDateModal`) allowing the user to either:
    1. **Use Auto-Figured Dates**: Keep the auto-detected trimester milestone dates.
    2. **Edit Dates Manually**: Manually choose custom Class Begin and Routine Ending dates using responsive date pickers.
- **Automatic Class Conclusion & Routine Window Enforcement**:
  - Recurring classes are active strictly within the routine window. Outside this window, classes automatically conclude and are suppressed on calendar day schedules.
- **Semester Break Recognition**:
  - The university recess between final examinations and the commencement of the next trimester is automatically recognized as an official **Semester Break Holiday** with regular classes suspended.
- **Holiday Conflict Engine**:
  - Automatically identifies overlapping classes and official holidays.
  - Dynamically marks classes as **Cancelled / No Class** on holiday dates.
  - Automatically **suppresses / silences class reminders** on holidays so students are never disturbed during university recesses.

### 3. 🛡️ University Domain Authentication & Sync
- **Domain-Restricted Access**: Verified access for **`@*.uiu.ac.bd`** / **`@uiu.ac.bd`** students and faculty (as well as general educational `.edu` and `.ac.bd` domains).
- **Zero-External-Dependency OTP Flow**: Integrated 6-digit email OTP verification backend running securely on `http://localhost:3097` (no proprietary cloud or Firebase locks).
- **Session Tokens**: Single-use cryptographic tokens ensuring authenticated access and cross-device sync.

### 4. 🔍 Robust Academic Notices & Persistent Navigation
- **Filterable Notice Feed**: Categories for Holidays & Recesses, Fee Payment Deadlines, Mid/Final Exam schedules, and Administrative milestones.
- **Real-Time Search Engine**: Search notices by keyword, title, or date without resetting the active tab or snapping back to the Dashboard.
- **Notice Action Dialogs**: Add custom personal reminders or campus notices directly within the interface.

### 5. 📂 Flexible File Import & Export (CSV, JSON, .ICS)
- **Class Routine Ingestion**: Ingest recurring schedules via standard CSV, JSON, or iCalendar (.ics) with immediate auto-figure configuration prompt.
- **Routine Schedule Window Card**: Dedicated Setup screen card displaying active start/end dates, source description, and an "Edit Window" action button.
- **Academic Calendar Ingestion**: Parse official university notices and trimester calendars.
- **Sanitized Calendar Export**: Export clean `.ics` files that exclude cancelled classes falling on holidays.
- **Pre-Configured UIU CS Presets**: Instant 1-tap demo setup for Computer Science & Engineering trimester timetables.

### 6. 🌐 All-in-One Web Companion (`index.html`)
- **Single-File Architecture**: Self-contained `index.html` (HTML + embedded CSS + embedded JS) ready for zero-configuration hosting on **GitHub Pages** (`docs/index.html` & root `index.html`).
- **Synchronized Calendar Engine**: 100% feature parity with Flutter app, including routine date auto-figuring, post-upload dialog, holiday conflict resolver, and local storage persistence.

---

## 📁 Project Directory Structure

```
educal/
├── backend/
│   ├── server.js                               # Node.js Auth & Sync Backend (Port 3097)
│   └── package.json                            # Backend dependencies (Express, CORS)
├── docs/
│   └── index.html                              # All-in-One GitHub Pages deployment bundle
├── index.html                                  # Root Web Companion (Single-file HTML/CSS/JS)
├── sample_data/
│   ├── class_schedule_sample.json              # Sample recurring class timetable (JSON)
│   ├── class_schedule_sample.csv               # Sample recurring class timetable (CSV)
│   ├── academic_calendar_sample.json           # Sample university notices & holidays (JSON)
│   └── academic_calendar_sample.csv            # Sample university notices & holidays (CSV)
├── lib/
│   ├── main.dart                               # Flutter app entrypoint & provider setup
│   ├── models/
│   │   ├── class_schedule.dart                 # Recurring class schedule model
│   │   ├── academic_notice.dart                # Notice & holiday definition model
│   │   ├── calendar_day_schedule.dart          # Merged daily schedule model & routine suppression
│   │   ├── routine_date_range.dart             # Auto-figured & custom routine window model
│   │   ├── reminder_notification.dart          # Notification reminder model
│   │   ├── student_profile.dart                # Authenticated student profile model
│   │   └── sync_status_report.dart             # Calendar sync telemetry model
│   ├── services/
│   │   ├── api_service.dart                    # HTTP client for auth & calendar sync API
│   │   ├── calendar_service.dart               # Core schedule, routine lifecycle & holiday engine
│   │   ├── file_parser_service.dart            # Multi-format ingestion (JSON, CSV, ICS)
│   │   ├── reminder_service.dart               # Notification scheduler & holiday muter
│   │   └── sample_data_service.dart            # Preloaded university timetable templates
│   ├── state/
│   │   └── calendar_state.dart                 # Central state manager (ChangeNotifier)
│   ├── theme/
│   │   └── app_theme.dart                      # Material 3 design system (Light & Dark)
│   ├── widgets/
│   │   └── educal_logo.dart                    # Scalable brand vector logo
│   └── screens/
│       ├── main_screen.dart                    # Persistent navigation shell & destination tab bar
│       ├── auth/                               # University OTP authentication screens
│       ├── dashboard/                          # Tab 1: Swipeable calendar & adaptive stats
│       ├── notices/                            # Tab 2: Notice search engine & urgency cards
│       ├── setup/                              # Tab 3: Routine ingestion & routine window dialog
│       │   └── routine_date_config_dialog.dart # Auto-figured vs manual date picker dialog
│       ├── sync/                               # Cross-platform cloud sync modal
│       └── reminders/                          # Notification center & settings dialogs
└── test/
    ├── backend_api_test.dart                   # Full-stack backend API & OTP integration tests
    ├── calendar_service_test.dart              # Holiday suppression logic unit tests
    ├── calendar_swipe_test.dart                # Touch drag gesture & month navigation tests
    ├── file_parser_service_test.dart           # Multi-format CSV/JSON/ICS parser tests
    ├── navigation_tab_persistence_test.dart    # Tab state preservation during notice search tests
    ├── responsive_layout_audit_test.dart       # Window resizing & 1.5x font scale audit tests
    ├── routine_lifecycle_autofigure_test.dart  # Routine window auto-figuring & dialog tests
    └── widget_test.dart                        # Core app shell rendering tests
```

---

## 🧪 Verification & Quality Assurance

EduTools is covered by a comprehensive automated test suite ensuring cross-platform stability:

- **Static Analysis**: `flutter analyze` passes with **0 errors, 0 warnings, 0 lints**.
- **Test Suite**: **31 / 31 tests passing (100%)**:
  1. `backend_api_test.dart`: University email auth verification, single-use OTP validation, sync status endpoints.
  2. `calendar_service_test.dart`: Holiday conflict detection, automatic class cancellation, and reminder muting.
  3. `calendar_swipe_test.dart`: Month cycling via horizontal drags and date cell selection.
  4. `file_parser_service_test.dart`: Ingestion of JSON, CSV, and ICS files; holiday exclusion in exports.
  5. `navigation_tab_persistence_test.dart`: Notice search state preservation without tab bouncing.
  6. `responsive_layout_audit_test.dart`: Zero `RenderFlex` overflows on small screens (320x568) and 1.5x font accessibility scale.
  7. `routine_lifecycle_autofigure_test.dart`: Auto-figuring routine dates post-suspension, dialog interaction, and semester break holiday verification.
  8. `widget_test.dart`: Main application bootstrap and navigation bar rendering.

---

## 🛠️ How to Run & Develop

### 1. Launch the Authentication Backend (Optional for Cloud Features)
```bash
cd backend
npm install
npm start
```
*Backend runs on `http://localhost:3097` with simulated OTP console output.*

### 2. Run the Flutter Application
```bash
# Navigate to project root
flutter pub get

# Run static analysis
flutter analyze

# Execute all tests
flutter test

# Run on your target device (Chrome, Windows desktop, Android emulator, or iOS simulator)
flutter run -d chrome
# or
flutter run -d windows
```

### 3. Run the Web Companion
Simply open `index.html` or `docs/index.html` in any modern web browser or serve with:
```bash
npx serve docs
```

---

## 📄 License
Created for academic and university scheduling enhancement. Distributed under the MIT License.
