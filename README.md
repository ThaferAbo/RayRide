# RayRide

RayRide is a Flutter-based tourist transfer booking application focused on Antalya. It was developed as a university course project and demonstrates passenger booking, driver trip handling, and admin dashboard workflows for airport and hotel transfers.

## Features

- Sign in and sign up screens
- Passenger transfer search flow
- Pickup and dropoff selection for Antalya transfer locations
- Ride and transfer selection flow
- Driver dashboard with pending requests and active trip simulation
- Admin dashboard with overview statistics and recent activity
- Admin trip management demo
- Driver status management demo
- User search, filtering, suspend, and reactivate demo actions
- Pricing controls with fare preview
- Route and driver movement simulation
- Dark themed responsive user interface

## Tech Stack

- Flutter
- Dart
- HTTP requests for backend authentication
- Secure/shared local storage for session and user data
- Flutter Map and LatLng-related packages for map and route features
- Frontend demo service layer for RayRide-specific operational workflows

## Project Structure

```text
lib/
  models/        Data models used by the Flutter app
  screens/       Passenger, driver, admin, authentication, and trip screens
  services/      Authentication, trip simulation, routing, and demo admin services
  widgets/       Reusable UI components
Backend/         Provided course backend used where applicable
assets/          Application assets
```

## How To Run

Install Flutter dependencies:

```bash
flutter pub get
```

Run the Flutter app:

```bash
flutter run
```

For web testing, a fixed local port can be used:

```bash
flutter run -d web-server --web-hostname localhost --web-port 3000
```

## Demo Notes

Some operational data is simulated for presentation. This includes RayRide-specific admin users, drivers, trips, pricing, and dashboard activity.

Backend authentication can be used if the provided course backend is running. Admin, driver, and trip operations are demonstrated through the Flutter app's demo service layer.

## Group Information

- Project name: RayRide
- Project type: University course project
- Group number: 09
