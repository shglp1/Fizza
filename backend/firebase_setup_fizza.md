# FIZZA Firebase Setup Guide

This guide details the exact steps to set up the Firebase backend for FIZZA, aligned with the **Fixed Subscription** model.

## 1. Project Creation & CLI Setup

1.  **Create Project**: Go to [Firebase Console](https://console.firebase.google.com/) and create a new project named `fizza-production` (or similar).
2.  **Enable Services**:
    *   **Authentication**: Enable **Email/Password**. (Phone Auth optional for later).
    *   **Firestore Database**: Create in **production mode**. Choose a region close to your users (e.g., `europe-west1` or `me-central1` if available).
    *   **Storage**: Enable for driver document uploads.
    *   **Functions**: Upgrade project to **Blaze Plan** (Pay as you go) to enable Cloud Functions.

3.  **Configure Flutter Apps**:
    *   Install Firebase CLI: `npm install -g firebase-tools`
    *   Login: `firebase login`
    *   Run inside the root of the monorepo:
        ```bash
        flutterfire configure
        ```
    *   Select your project.
    *   Select platforms (Android, iOS).
    *   This generates `firebase_options.dart` in `lib/` for each app. Move/Ensure it's in the correct place for `fizza_core` or individual apps.

## 2. Firestore Schema & Collections

This schema matches the Domain Entities in `packages/fizza_domain`.

### `users`
*   `uid` (Document ID)
*   `name`: string
*   `email`: string
*   `phoneNumber`: string
*   `role`: string ('user', 'driver', 'admin')
*   `fcmToken`: string

### `drivers`
*   `uid` (Document ID)
*   `name`: string
*   `phoneNumber`: string
*   `vehicleModel`: string
*   `vehiclePlate`: string
*   `vehicleYear`: number (Default: 2018)
*   `tier`: string ('standard', 'vip', 'female')
*   `commissionRate`: number (Default: 0.15)
*   `isOnline`: boolean
*   `isAvailable`: boolean
*   `isSuspended`: boolean
*   `suspensionReason`: string (optional)
*   `rating`: number
*   `ratingCount`: number
*   `totalRides`: number
*   `totalEarnings`: number
*   `location`: map { `lat`: number, `lng`: number, `heading`: number }

### `wallets`
*   `uid` (Document ID - matches userId/driverId)
*   `balance`: number
*   `currency`: string ('SAR')
*   **Subcollection**: `transactions`
    *   `id` (Auto ID)
    *   `amount`: number
    *   `type`: string ('credit', 'debit')
    *   `description`: string
    *   `timestamp`: timestamp

### `system_configs`
*   `default` (Document ID) - **Source of Truth for Logic**
    *   `pricing`: map
        *   `baseFare`: number
        *   `pricePerKm`: number
        *   `driverCommissionRate`: number (0.15)
    *   `loyalty`: map
        *   `pointsPerRide`: number (5)
        *   `pointsMonthlySub`: number (30)
        *   `pointsLongTermSub`: number (100)
        *   `pointsSafetyReport`: number (40)
        *   `pointsFemaleDriver`: number (10)
        *   `levelThresholds`: map { `bronze`: 0, `silver`: 500, `gold`: 2000 }
    *   `operational`: map
        *   `operatingStartHour`: number (6)
        *   `operatingEndHour`: number (23)
        *   `maxPickupDistanceKm`: number (10.0)

### `subscription_packages`
*   `id` (Auto ID)
*   `name`: string ('Monthly', '3 Months', etc.)
*   `price`: number
*   `durationDays`: number
*   `discountPercentage`: number
*   `isFamily`: boolean
*   `isFemaleOnly`: boolean

### `user_subscriptions`
*   `id` (Auto ID)
*   `userId`: string
*   `packageId`: string
*   `driverId`: string (Assigned Driver)
*   `startDate`: timestamp
*   `endDate`: timestamp
*   `isActive`: boolean
*   `autoRenew`: boolean
*   `renewalStatus`: string ('active', 'pending', 'cancelled')
*   `ridesRemaining`: number
*   `homeLocation`: map { `lat`, `lng` }
*   `schoolLocation`: map { `lat`, `lng` }
*   `pickupTime`: string ('07:00')
*   `returnTime`: string ('14:00')

### `trips`
*   `id` (Auto ID)
*   `driverId`: string
*   `userId`: string
*   `subscriptionId`: string
*   `status`: string ('scheduled', 'started', 'completed', 'cancelled')
*   `pickupLocation`: map
*   `dropoffLocation`: map
*   `scheduledTime`: timestamp
*   `actualDistanceKm`: number
*   `finalFare`: number
*   `driverEarnings`: number
*   `timestamp`: timestamp

### `add_ons`
*   `id` (Auto ID)
*   `name`: string
*   `price`: number
*   `isMonthly`: boolean

### `stats_daily` (Analytics)
*   `date` (Document ID: YYYY-MM-DD)
*   `totalTrips`: number
*   `totalRevenue`: number
*   `activeSubscriptions`: number
*   `avgDelayMinutes`: number

## 3. Security Rules (MVP)

Copy these into your Firestore Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    function isAdmin() {
      // In MVP, you might use a custom claim or a hardcoded list
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Users: Read own, Write own (profile updates)
    match /users/{userId} {
      allow read: if isSignedIn();
      allow write: if isOwner(userId) || isAdmin();
    }

    // Drivers: Public read (for assignment), Write own status
    match /drivers/{driverId} {
      allow read: if isSignedIn();
      allow write: if isOwner(driverId) || isAdmin();
    }

    // Wallets: STRICT - Only Admin or Cloud Functions can write balance
    match /wallets/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow write: if false; // Only via Cloud Functions
    }

    // Config: Public Read, Admin Write
    match /system_configs/{config} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Subscriptions: Read own, Write via Functions (mostly)
    match /user_subscriptions/{subId} {
      allow read: if isOwner(resource.data.userId) || isAdmin() || request.auth.uid == resource.data.driverId;
      allow write: if false; // Only via Cloud Functions (assignment)
    }

    // Trips: Driver can update status, User can read
    match /trips/{tripId} {
      allow read: if isOwner(resource.data.userId) || isOwner(resource.data.driverId) || isAdmin();
      allow update: if isOwner(resource.data.driverId) && 
                    (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'actualDistanceKm', 'actualDurationMinutes']));
      allow create: if false; // Created by system/scheduler
    }
  }
}
```

## 4. Wiring Notes for Flutter

### Direct Firestore Access (Read/Simple Write)
Use `FirebaseFirestore.instance` in your repositories for:
*   Reading `SystemConfig`.
*   Reading `Driver` profiles.
*   Reading `UserSubscription` details.
*   Listening to `RideRequests` (if using on-demand).
*   Updating Driver `isOnline` / `location`.

### Cloud Functions Calls (Complex Logic)
Use `FirebaseFunctions.instance.httpsCallable` for operations requiring business logic validation or multi-document updates.

**1. Create Subscription & Assign Driver**
*   **Function**: `assignSubscriptionToDriver`
*   **Dart Call**:
    ```dart
    final result = await FirebaseFunctions.instance.httpsCallable('assignSubscriptionToDriver').call({
      'userId': userId,
      'packageId': packageId,
      'homeLocation': {'lat': ..., 'lng': ...},
      'destinationLocation': {'lat': ..., 'lng': ...},
      'preferredPickupTime': '07:00',
      'preferredReturnTime': '14:00',
    });
    ```

**2. Complete Trip (Driver App)**
*   **Function**: `completeDailyTrip`
*   **Dart Call**:
    ```dart
    await FirebaseFunctions.instance.httpsCallable('completeDailyTrip').call({
      'tripId': tripId,
      'driverId': driverId,
      'actualDistanceKm': 12.5,
      'actualDurationMinutes': 25,
    });
    ```

**3. Admin: Recalculate Clusters**
*   **Function**: `recalculateClustersForCity`
*   **Dart Call**:
    ```dart
    await FirebaseFunctions.instance.httpsCallable('recalculateClustersForCity').call({
      'cityId': 'riyadh',
    });
    ```
