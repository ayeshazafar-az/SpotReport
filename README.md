# SpotClear 🚓

**AI-Powered Highway Incident & Vehicle Clearance System**

SpotClear is a digital, location-based mobile and web application designed for highway safety authorities (like NHMP/PHP). It modernizes the manual accident clearance slip process by utilizing Google Gemini AI for instant vehicle damage triage, and Supabase for real-time verification across checkpoints and citizen portals.

---

## ✨ Key Features

### 👮‍♂️ For Patrol Officers
* **On-Spot Logging:** Capture vehicle damage photos and instantly log incident details directly from the highway.
* **Auto-GPS Tagging:** Automatically fetches high-accuracy location coordinates for incident mapping.
* **AI Damage Triage:** Integrates Google Gemini Vision AI to automatically analyze damage photos, generate summaries, and assign severity levels (e.g., Minor, Severe).
* **Digital Clearance Slips:** Generates a unique, verifiable Incident Code (e.g., `INC-2026-1234`) on the spot.

### 🛣️ For Checkpoint & Toll Operators
* **Instant Verification:** Search by Vehicle Registration Number (e.g., `ICT-1234`) to verify active clearance slips.
* **Visual Confirmation:** View the original damage photo and AI summary to ensure the vehicle matches the authorized report.

### 📱 For Citizens & Drivers
* **Slip Tracking:** Log in with a registered phone number to view all active and past vehicle clearance slips.
* **Digital Repair Proof:** Upload photos of post-repair vehicle conditions to instantly update the vehicle's status to "Repaired" and clear the record.

---

## 🛠 Tech Stack

* **Frontend:** Flutter (Cross-platform Web & Mobile)
* **Backend as a Service:** Supabase (PostgreSQL Database, Auth, Storage)
* **Artificial Intelligence:** Google Gemini API (Generative AI Image Analysis)
* **Location Services:** Geolocator
* **State Management:** Riverpod

---

## 🗄️ Database Schema Overview

The system utilizes a relational PostgreSQL database hosted on Supabase:

* **`profiles`**: Stores user data, linked to Supabase Auth.
  * Columns: `id` (UUID), `full_name`, `phone_number`, `cnic`, `role` (officer/citizen), `badge_number`, `department`.
* **`incidents`**: Stores incident reports and AI metadata.
  * Columns: `id`, `incident_code`, `officer_id` (FK), `vehicle_number`, `driver_cnic`, `driver_phone`, `cause_category`, `description`, `damage_photos` (Array), `highway_name`, `latitude`, `longitude`, `ai_damage_summary`, `ai_severity`, `repair_status`.
* **Storage Bucket**: `damage_photos` (Publicly readable bucket for evidence and repair uploads).

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.19+)
* A [Supabase](https://supabase.com/) account and project
* A [Google AI Studio](https://aistudio.google.com/) API Key for Gemini

### 1. Clone the Repository
```bash
git clone [https://github.com/your-username/spot_report.git](https://github.com/your-username/spot_report.git)
cd spot_report

```

### 2. Install Dependencies

```bash
flutter pub get

```

### 3. Environment Variables (Secrets)

Create a `.env` file in the root directory (same level as `pubspec.yaml`) and add your project keys. **Do not use quotation marks.**

```env
SUPABASE_URL=[https://your-project.supabase.co](https://your-project.supabase.co)
SUPABASE_ANON_KEY=your_supabase_anon_key
GEMINI_API_KEY=your_google_gemini_api_key

```

*(Note: Ensure `.env` is listed in your `.gitignore` to prevent secret leakage).*

### 4. Supabase Setup

Execute the following SQL scripts in your Supabase SQL Editor:

1. Create the `profiles` and `incidents` tables.
2. Setup Row-Level Security (RLS) policies for testing or production.
3. Create a new public storage bucket named `damage_photos`.
4. Configure upload/select policies for the `damage_photos` bucket.

### 5. Run the Application

Because the application injects environment variables securely at compile time, you must run the app using the `--dart-define-from-file` flag:

**Run on Web (Chrome):**

```bash
flutter run --dart-define-from-file=.env -d chrome

```

**Run on Mobile (Android/iOS emulator):**

```bash
flutter run --dart-define-from-file=.env

```

---

## 📂 Project Structure

```text
lib/
├── core/
│   └── constants.dart         # Secure environment variable bindings
├── models/
│   ├── incident_model.dart    # Data mapping for Incident tickets
│   └── profile_model.dart     # Data mapping for User profiles
├── services/
│   ├── gemini_service.dart    # Google AI integration for damage analysis
│   └── supabase_service.dart  # Database CRUD, Auth, and Storage ops
├── views/
│   ├── auth_screen.dart       # Login & Registration gateway
│   ├── checkpoint_screen.dart # Vehicle lookup for toll operators
│   ├── citizen_screen.dart    # Citizen portal for repair uploads
│   └── report_screen.dart     # Officer portal for incident logging
└── main.dart                  # App entry point, Theme & Navigation Wrapper

```

```
