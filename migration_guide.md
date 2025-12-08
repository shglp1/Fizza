# FIZZA Migration Guide: Firebase to Supabase

This guide details the steps to migrate the FIZZA backend from Firebase to Supabase.

## 1. Prerequisites

*   [Supabase CLI](https://supabase.com/docs/guides/cli) installed.
*   [Docker](https://docs.docker.com/get-docker/) installed (for local development).
*   A new Supabase project created.

## 2. Database Setup

1.  **Login to Supabase CLI**:
    ```bash
    supabase login
    ```

2.  **Initialize Project** (if running locally):
    ```bash
    supabase init
    ```

3.  **Apply Schema**:
    Run the generated SQL schema to create tables, types, and RLS policies.
    ```bash
    supabase db reset --db-url <YOUR_DB_URL> # CAUTION: This wipes the DB
    # OR for remote project:
    supabase db push
    ```
    *Ensure `supabase/schema.sql` is placed in `supabase/migrations` or run manually via SQL Editor.*

## 3. Edge Functions Deployment

1.  **Set Environment Variables**:
    In your Supabase Dashboard > Settings > Edge Functions, add:
    *   `SUPABASE_URL`: Your project URL.
    *   `SUPABASE_SERVICE_ROLE_KEY`: Your service role key (for admin tasks).

2.  **Deploy Functions**:
    Run the following commands to deploy all functions:
    ```bash
    supabase functions deploy assign-subscription
    supabase functions deploy complete-trip
    supabase functions deploy approve-safety-report
    supabase functions deploy export-analytics
    supabase functions deploy aggregate-daily-stats
    ```

## 4. Cron Job Setup (Scheduled Tasks)

To replace the Firebase Scheduled Function `aggregateDailyStats`, we use `pg_cron` in Supabase.

1.  **Enable Extension**:
    In Supabase SQL Editor:
    ```sql
    CREATE EXTENSION IF NOT EXISTS pg_cron;
    ```

2.  **Schedule Job**:
    Run this SQL to schedule the `aggregate-daily-stats` function to run every day at midnight:
    ```sql
    SELECT cron.schedule(
      'aggregate-daily-stats',
      '0 0 * * *', -- Every day at midnight
      $$
      select
        net.http_post(
            url:='https://<PROJECT_REF>.supabase.co/functions/v1/aggregate-daily-stats',
            headers:='{"Content-Type": "application/json", "Authorization": "Bearer <SERVICE_ROLE_KEY>"}'::jsonb,
            body:='{}'::jsonb
        ) as request_id;
      $$
    );
    ```
    *Replace `<PROJECT_REF>` and `<SERVICE_ROLE_KEY>` with your actual values.*

## 5. RLS & Security Verification

*   **Users**: Can only read/update their own `profiles`, `user_subscriptions`, `trips`, `wallets`.
*   **Drivers**: Can read their own `drivers` profile and assigned `trips`/`subscriptions`.
*   **Admins**: Have full access to all tables.
*   **Public**: No table is publicly writable.

## 6. Testing Plan

### 6.1 Manual Testing
1.  **Auth**: Sign up a new user. Verify `profiles` and `wallets` rows are created automatically.
2.  **Subscription**: Call `assign-subscription` with a new user. Verify `user_subscriptions` is created and driver assigned.
3.  **Trip**: Call `complete-trip`. Verify status updates, earnings calculated, and loyalty points awarded.
4.  **Admin**: Sign in as admin. Call `approve-safety-report`. Verify points awarded and cap respected.
5.  **Analytics**: Call `export-analytics`. Verify CSV output.

### 6.2 Automated Testing
*   Use Supabase Test Helpers to write integration tests for RLS policies.
*   Write unit tests for Edge Functions using Deno test runner.

## 7. Cutover Strategy

1.  **Data Migration**:
    *   Export Firestore data to JSON.
    *   Write a script to transform JSON to SQL `INSERT` statements or CSVs.
    *   Import into Supabase using `supabase db import` or Table Editor.
2.  **DNS/Client Update**:
    *   Update Flutter app to use `supabase_flutter` SDK instead of `firebase_core`.
    *   Update API endpoints to point to Supabase Edge Functions.
3.  **Go Live**:
    *   Enable Maintenance Mode on Firebase.
    *   Perform final data sync.
    *   Switch client to Supabase.
