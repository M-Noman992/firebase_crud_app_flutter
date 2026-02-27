# Firebase CRUD App Flutter

A comprehensive Flutter application demonstrating Firebase CRUD operations (Storage & Firestore) for managing images, along with REST API integration and local caching.

## Features

- Upload images to Firebase Storage (Camera & Gallery)
- Full Firestore CRUD (Create, Read, Update, Delete)
- REST API integration (JSONPlaceholder)
- Offline caching with SharedPreferences
- Real-time updates using StreamBuilder
- Clean UI with BottomNavigationBar
- Firebase auto configuration using FlutterFire CLI

---

## API Integration & Local Caching

- Fetches user data from JSONPlaceholder API
- Stores data locally using SharedPreferences
- Supports offline access

---

## Firebase Storage Integration

- Pick images from:
  - Camera
  - Gallery
- Upload securely to Firebase Storage

---

## Firestore Database CRUD

- Create: Upload image with metadata
- Read: Display images in gallery
- Update: Edit image descriptions
- Delete: Remove images and records

---

## UI & Navigation

- Simple and responsive UI
- BottomNavigationBar with:
  - Users Screen (API Data)
  - Gallery Screen (Firebase Data)

---

## Real-time Data

- Uses Firestore StreamBuilder
- Auto updates UI when:
  - New image uploaded
  - Data updated
  - Data deleted

---

## Firebase Configuration

- Integrated using FlutterFire CLI
- Automatic platform setup
- No manual configuration needed

## Prerequisites & Installation

Before running this project, ensure you have:

- Flutter SDK installed
- A configured Firebase project
- Android Studio or VS Code

### Run the Project

```bash
flutter pub get
flutter run
