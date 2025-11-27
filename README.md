# FIZZA Monorepo

This repository contains the source code for the FIZZA platform, including the User App, Driver App, and Admin Panel.

## Structure

### Apps (`apps/`)
- **user_app**: Flutter app for parents and riders.
- **driver_app**: Flutter app for drivers.
- **admin_panel**: Flutter Web app for administration.

### Packages (`packages/`)
- **fizza_core**: Shared core utilities, extensions, and base classes.
- **fizza_domain**: Shared business logic, entities, and use cases.
- **fizza_data**: Shared data layer, repositories, and Firebase implementation.
- **fizza_ui**: Shared design system, widgets, and assets.

## Getting Started

1. **Setup Flutter**: Ensure Flutter is installed and in your PATH.
2. **Install Dependencies**:
   ```bash
   # In each app directory:
   flutter pub get
   ```
3. **Run Apps**:
   ```bash
   cd apps/user_app
   flutter run
   ```

## Architecture

The project follows Clean Architecture principles with a modular package structure.
