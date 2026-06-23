# Sahulat Ghar Tak - Agent Customization Guide

**Project**: A Flutter home services marketplace mobile application

## Quick Start

- **Build**: `flutter pub get && flutter build apk`
- **Run**: `flutter run`
- **Test**: `flutter test`
- **Format**: `dart format lib/`

## Architecture Overview

This app uses **Provider** for state management with a clean separation between models, providers, and UI screens.

### Data Models

#### `Service` (lib/models/service.dart)
Represents a home service offering:
- `id`: Unique service identifier
- `name`: Service name (e.g., "Electrician Services")
- `description`: Brief service description
- `startingPrice`: Base price in PKR
- `iconData`: Material Design icon for UI display

**Key point**: Services are immutable and loaded in memory by `ServiceProvider`.

#### `Booking` (lib/models/booking.dart)
Represents a customer booking with:
- `id`: Database primary key (nullable for new bookings)
- Customer info: `customerName`, `mobile`, `address`, `city`
- Service info: `serviceName`, `serviceDate`, `serviceTime`
- `notes`: Additional customer notes

**Key point**: Includes `toMap()` / `fromMap()` for SQLite serialization.

### State Management Layers

1. **Providers** (lib/providers/)
   - `ServiceProvider`: Loads 18 pre-defined services; notifies listeners when data changes
   - `BookingProvider`: Manages bookings, persists to SQLite via `DbHelper`

2. **Database** (lib/database/db_helper.dart)
   - SQLite integration for persistent booking storage
   - Called by `BookingProvider`

## Common Tasks

### Adding a New Service
Edit `ServiceProvider._loadServices()` in `lib/providers/service_provider.dart`:
```dart
Service(
  id: 19,
  name: 'New Service Name',
  description: 'Description here',
  startingPrice: 1000.0,
  iconData: Icons.icon_name,
),
```

### Adding a Booking Field
1. Add field to `Booking` class in `lib/models/booking.dart`
2. Update `toMap()` and `fromMap()` methods
3. Update SQLite schema in `DbHelper`
4. Update booking screens (`BookingScreen`, `BookingsListScreen`)

### Displaying Services
Services are accessed via `context.watch<ServiceProvider>().services` in widgets. See `lib/screens/home_screen.dart` for example.

## Project Structure

```
lib/
├── models/              # Data classes (Service, Booking)
├── providers/          # State management (ServiceProvider, BookingProvider)
├── database/           # SQLite integration (DbHelper)
├── screens/            # UI pages (Home, Booking, Categories, etc.)
├── widgets/            # Reusable UI components (ServiceCard, BannerSlider, etc.)
├── utils/              # Constants and utilities
└── main.dart           # App entry point
```

## Navigation
All screens use named routes defined in `SahulatApp.routes`. Add new routes there before pushing to them.

## Dependencies
- `provider`: State management
- `sqflite`: SQLite database
- `intl`: Internationalization (date formatting)
- `flutter_animate`: UI animations

## Important Notes
- The app initializes with `WidgetsFlutterBinding.ensureInitialized()` before running—keep database initialization before `runApp()`
- Material 3 design is enabled; use `kPrimaryColor` from `lib/utils/constants.dart` for theme consistency
- No network requests in current implementation—all data is mocked or local SQLite
