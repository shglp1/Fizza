# FIZZA Product Source of Truth (v3.3)

**Status Date:** Dec 7, 2025
**Scope:** Product/UX Analysis of Actual Backend Implementation & Policy Alignment

This document serves as the **Master Source of Truth** for the FIZZA product behavior. It translates the current backend logic (Domain, Data, Cloud Functions) into user-centric stories, features, and flows. It defines exactly what the system *is* today, complying with the client's operational, financial, and technical policies.

---

## 1. System Nature: Fixed Subscription Service

**CRITICAL POLICY:** FIZZA is **NOT** an on-demand ride-hailing app (like Uber/Careem).
*   **Model:** Fixed Monthly Subscription.
*   **Trip:** Guaranteed daily round trip (Home ↔ School/Work).
*   **Driver:** **Fixed per subscription**. The same driver serves the user for the entire month.
*   **No Daily Search:** There is NO "Searching for driver..." step before every ride. Assignment happens *once* at subscription purchase.
*   **Re-assignment:** Only happens in emergencies (breakdown, vacation).

---

## 2. User Stories

### **2.1 The User (Parent/Student)**
**Persona:** A busy parent or a university student who needs reliable, daily transportation.
*   **Goal:** "I want to pay once a month to have a dedicated driver pick up my kids at 7:00 AM every day."
*   **Expectation:** I expect the *same* driver (Abu Ahmed) to show up daily. I don't want to book a ride every morning.
*   **Daily Flow:** Open app -> See "Driver Abu Ahmed is assigned" -> View Trip Status -> (Optional) Report Safety Issue.

### **2.2 The Driver**
**Persona:** A car owner seeking steady, predictable income.
*   **Goal:** "I want a fixed schedule of 4-5 students to pick up every morning so I know my exact route and income."
*   **Expectation:** I expect to see a list of "My Students" for the month. I don't want to chase random trip requests.
*   **Daily Flow:** Go Online -> View "Today's Passenger List" -> Start Trip -> Drop off all -> Complete Trip -> Check Earnings.

### **2.3 The Admin**
**Persona:** The Operations Manager.
*   **Goal:** "I want to manage pricing, approve drivers, and resolve complaints."
*   **Expectation:** I need to see if the business is profitable (Revenue vs Driver Cost) and ensure safety.

---

## 3. Subscription Plans & Renewal

### **3.1 Plans**
The system supports the following plan structures in `UserSubscriptionEntity` and `SystemConfig`:
1.  **Monthly (Base)**: Standard 30-day access.
2.  **3 Months**: 10% Discount.
3.  **6 Months**: 20% Discount.
4.  **Family Plan**: Multiple beneficiaries (siblings) linked to one parent.
5.  **Female-Only**: Premium option for a guaranteed female driver.

### **3.2 Renewal Policy**
*   **Auto-Renew**: **Enabled by default**.
*   **Cancellation Window**: User can disable auto-renew up to **5 days** before the current period ends.
*   **Implementation**: `UserSubscriptionEntity.autoRenew` flag.

---

## 4. Pricing Model (Cost-Based)

**Policy:** Pricing is calculated based on costs, not arbitrary demand.
**Formula:** `Price = (Driver Cost + App Overhead) + Profit Margin (10-20%)`

*   **Driver Cost**: Salary + Fuel + Maintenance + Depreciation + Insurance.
*   **App Overhead**: Server costs + Support + Ops + Payment Fees (1.5-2.5%).

*Note: The backend `SystemConfig` contains fields for these costs (`salaryPerDriver`, `fuelPrice`, etc.) to allow the Admin to adjust the base fare and commission dynamically.*

---

## 5. Wallet & Payments

### **5.1 v3.3 Status (Current)**
*   **Internal Wallet**: The core source of truth for payments.
*   **Top-Up**: **Mocked**. Users click "Top Up" and balance is added instantly (for testing).
*   **Payment Methods**: No real gateway (Apple Pay/Mada) is connected yet.
*   **No Cash**: Cash payments are strictly prohibited.

### **5.2 v4.0 Vision (Future)**
*   Integration with **Moyasar/Tap** for real Apple Pay & Mada transactions.
*   Refunds will be processed back to the original payment method (or Wallet).

---

## 6. Static Map UX (No Real-Time Tracking)

**Policy:** v3.3 does **NOT** have live GPS tracking.

### **6.1 User App - Active Trip Screen**
*   **Static Map**: A placeholder map image or a static Google Map view centered on the route.
*   **Driver Info**: Photo, Name, Car Model, Plate Number.
*   **Status**: Text indicator: "Driver Assigned" -> "On the Way" -> "Arrived" -> "Trip Started".
*   **No Moving Car**: The user will *not* see a car icon moving in real-time.

### **6.2 Driver App - Active Trip Screen**
*   **Passenger List**: List of names to pick up (e.g., "Ali, Sara, Ahmed").
*   **Locations**: Static list of Pickup and Dropoff points.
*   **Tags**: "Female Only", "Child Seat", "VIP".
*   **Action**: "Start Trip" / "Complete Trip" buttons.

---

## 7. Notifications & Alerts

**Policy:** v3.3 does **NOT** use Push Notifications (FCM).

### **7.1 Fallback UI (v3.3)**
Since push notifications are missing, the app relies on **In-App States**:

| Event | Target | Future Notification Text | v3.3 Fallback UI |
| :--- | :--- | :--- | :--- |
| **Trip Started** | User | "Your trip has started." | Status change on Home / Active Trip screen |
| **Trip Completed** | User | "Your trip is complete." | Status text + loyalty points updated in the app |
| **Driver No-Show** | User | "Your driver did not arrive. We’re handling it." | Manual support + compensation (admin workflow) |
| **Subscription Expiring** | User | "Your subscription ends in 5 days." | Banner on Home / Subscription details |
| **Wallet Top-Up** | User | "Your wallet has been topped up." | In-app snackbar: "Balance updated." |

### **7.2 Future (v4.0)**
*   `INotificationService` is defined in code but currently does nothing (No-op).
*   Future: Integrate Firebase Cloud Messaging (FCM) for real-time alerts.

---

## 8. In-App Chat & Support

**Policy:** Not implemented in v3.3.

*   **No Chat**: Parents cannot text drivers.
*   **No Voice**: No in-app calling.
*   **Future**: `IChatService` will be added to allow secure communication without sharing phone numbers.

---

## 9. Cancel Subscription – Policy & Flow

### **9.1 Policy**
*   **Pre-Start Cancellation**: If cancelled *before* the start date -> **Full Refund** to Wallet.
*   **Active Cancellation**: If cancelled *during* the month -> **No Refund**. Auto-renew is disabled.
*   **Emergency**: For medical/emergency cancellations, User must contact Admin (Support) for manual processing.

### **9.2 UX Flow**
1.  User taps "Cancel Subscription".
2.  **Dialog**:
    *   *If Not Started*: "You will receive a full refund to your wallet."
    *   *If Active*: "Your subscription will remain active until [End Date] but will not renew. No refund is applicable."
3.  **Action**: User confirms.
4.  **Result**: Status updates to `cancelled` (if pre-start) or `autoRenew: false` (if active).

---

## 10. Error States & Fallback Behavior

| Context | Error Condition | User-Visible Message |
| :--- | :--- | :--- |
| **Subscription** | No driver in 10km radius | "NO_DRIVER_AVAILABLE: We could not find a driver in your area. Please try again later." |
| **Subscription** | Female-only requested but none found | "NO_FEMALE_DRIVER_AVAILABLE: No female drivers are currently available. You can try again later or disable the female-only option." |
| **Trip** | Network/Server Error | "Could not complete trip. Please check your connection." |
| **Config** | Invalid System Config | (Admin Only) "System Configuration Error. Check database." |

---

## 11. Empty States

### **User App**
*   **No Subscription**: "No active subscription. Browse plans to get started."
*   **No Trips**: "No trips scheduled for today."
*   **No Wallet History**: "No transactions yet." (Button: "Top up wallet")
*   **Safety Reports**: "You haven’t reported any issues yet."

### **Driver App**
*   **Offline**: "You are offline. Go Online to see trips." (Button: "Go online")
*   **No Trips**: "No trips assigned for today."
*   **No Earnings**: "No earnings yet. Complete trips to see your income here."

### **Admin Panel**
*   **No Drivers**: "No drivers waiting for approval."
*   **No Complaints**: "No new safety reports. You’re all caught up."
*   **No Analytics**: "No analytics yet. Stats will appear after the first full day of trips."

---

## 12. Future Vision (v4.0)

*   **Real-Time Tracking**: Live car movement on map.
*   **Real Payments**: Apple Pay / Mada integration.
*   **Smart Routing**: AI-optimized pickup order.
*   **Chat System**: Direct Parent-Driver communication.
