# AI Handoff: Real Estate Sales App

## Purpose

Continue building a role-based real estate sales mobile application for an internship project. The team has six members. The current developer is the Team Lead / Backend-Auth Developer.

## Repository and current branch

- GitHub: `https://github.com/Adityaa9009/real-estate-sales-app.git`
- Local workspace: `/Users/adityaduhan/Documents/ChatGPT/Real Estate Project For Internship`
- Current branch: `feature/backend-auth`
- Stable branch: `main`
- Team integration branch: `develop`

All three branches exist on GitHub. Do not work directly on `main`.

## What has already been completed

1. GitHub CLI was authenticated as `Adityaa9009` and the workspace is connected to the repository remote named `origin`.
2. Team collaboration rules were added and pushed.
3. A shared database design was added and pushed.
4. Flutter SDK was installed successfully at `/opt/homebrew/share/flutter`.
5. A Flutter application was created in `app/` with Android, iOS, and web targets.
6. A first login UI and temporary role-routing flow were implemented.
7. Flutter tests pass with `flutter test` run inside `app/`.
8. The user reports that Firebase CLI installation is complete, but Firebase configuration has NOT started yet.

## Important commits

- `b2df452` - `chore: establish shared project architecture`
- `b89bacc` - `feat: add role-based login app foundation`

## Existing files

| File | Purpose |
|---|---|
| `README.md` | Project overview and role descriptions |
| `.gitignore` | Keeps secrets, temporary PDFs, and build files out of Git |
| `docs/TEAM_WORKFLOW.md` | Branch ownership, PR rules, and test accounts |
| `docs/DATABASE_SCHEMA.md` | Shared collection/field/status design |
| `app/lib/main.dart` | Current Flutter login screen and temporary role routing |
| `app/test/widget_test.dart` | Passing login screen widget test |
| `app/pubspec.yaml` | Flutter package configuration |

## Current app behavior

The app currently has a polished but temporary login screen.

1. User enters any email and password.
2. User chooses one of four temporary test roles: Admin, Executive, Inside Sales, or Outside Sales.
3. The app sends the user to a temporary role-specific dashboard page.
4. Sign-out returns to the login page.

This is intentional. It proves navigation and role routing before real Firebase Authentication is connected.

## Required next work: Firebase (do this first)

### 1. Verify Firebase CLI

Run:

```bash
firebase --version
```

If unavailable, the user should run in their Mac Terminal:

```bash
npm install -g firebase-tools
```

### 2. Authenticate Firebase

Run:

```bash
firebase login
```

This will require the user to approve Google/Firebase access in their browser. Do not ask the user to share passwords or access tokens.

### 3. Create a shared Firebase project

Create a development project, preferably named `real-estate-sales-app-dev`. Enable:

- Firebase Authentication - Email/Password provider
- Cloud Firestore
- Cloud Storage

Use the Firebase Spark/free plan unless the user explicitly approves billing. Do not configure production deployment yet.

### 4. Install Flutter Firebase integration

Install the FlutterFire CLI if missing:

```bash
dart pub global activate flutterfire_cli
```

From `app/`, add packages:

```bash
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
```

Configure the selected Firebase project:

```bash
flutterfire configure
```

This should create `app/lib/firebase_options.dart`. It is a configuration file, not a secret; commit it unless it contains an unexpected credential.

### 5. Replace temporary login

Replace the local test login in `app/lib/main.dart` with Firebase Authentication:

- use `Firebase.initializeApp` in `main()`;
- sign in via `FirebaseAuth.instance.signInWithEmailAndPassword`;
- fetch the `employees/{uid}` Firestore document;
- read and validate its `role` field;
- route only to the correct role dashboard;
- show a clear error for invalid password, missing employee record, inactive employee, or unauthorized role;
- on logout, call `FirebaseAuth.instance.signOut`.

Never treat a role selected in the UI as authorization. The role must come from Firestore and eventually be enforced by Firebase Security Rules.

### 6. Create test accounts and employee records

Create four Firebase Authentication email/password accounts and matching `employees` documents, using their Firebase Auth UIDs as document IDs:

| Email | Role |
|---|---|
| `admin@demo.com` | `admin` |
| `executive@demo.com` | `executive` |
| `inside@demo.com` | `inside_sales` |
| `outside@demo.com` | `outside_sales` |

Use safe demo passwords known only to the project team; never add the passwords to Git.

## Firestore source of truth

Use `docs/DATABASE_SCHEMA.md`. It defines:

- `employees`
- `customers`
- `attendance`
- `customer_assignments`
- `call_updates`
- `visits`
- `broadcast_messages`

Do not rename role values. They must stay exactly:

```text
admin
executive
inside_sales
outside_sales
```

The agreed customer lifecycle is:

```text
unassigned
→ assigned_to_inside_sales
→ interested OR not_interested
→ visit_scheduled
→ visit_in_progress
→ visit_completed
```

## Security requirements

- Employees may read only the customers, visits, and files assigned to them.
- Only Admin may access all attendance, recordings, selfies, employee data, and broadcasts.
- Only Admin/Executive can create employees and customers (final exact permissions should be reflected in rules).
- Inside Sales should receive phone numbers masked in UI; do not expose full phone numbers in broad list views.
- Storage paths for recordings/selfies must be private and protected by Firebase Storage Rules.
- UI hiding is not security: enforce authorization in Firebase Security Rules.

## Team member boundaries

| Branch | Module |
|---|---|
| `feature/backend-auth` | Authentication, roles, database, shared services, integration |
| `feature/admin-dashboard` | Admin UI, employee/customer management, attendance, broadcasts |
| `feature/executive-dashboard` | Employee/customer forms, Excel upload, Inside Sales assignment |
| `feature/inside-sales` | Calls, interest outcomes, WhatsApp handoff, visit scheduling |
| `feature/outside-sales` | Visits, recordings, selfie upload |
| `feature/qa-devops` | Tests, geofencing, screenshot/recording reliability, deployment |

Developers should branch from `develop`, push their feature branch, and open a Pull Request to `develop`. The team lead integrates only after review.

## How to verify before committing

From the app directory:

```bash
dart format lib test
flutter test
flutter run -d chrome
```

The current machine has Chrome/web support. Android SDK and full Xcode are not installed yet, so real Android/iPhone testing needs Android Studio / Xcode later. Do not block the authentication/data work on those installations.

## Commit and push procedure

From the repository root:

```bash
git status
git add <specific files>
git commit -m "feat: <short description>"
git push
```

Keep commits focused. Do not commit `.env`, service-account JSON, passwords, or generated private credentials.

