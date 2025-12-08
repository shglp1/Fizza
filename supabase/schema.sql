-- Enable PostGIS for geospatial data
CREATE EXTENSION IF NOT EXISTS postgis;

-- -----------------------------------------------------------------------------
-- 1. ENUMS & TYPES
-- -----------------------------------------------------------------------------

CREATE TYPE public.user_role AS ENUM ('user', 'driver', 'admin');
CREATE TYPE public.gender AS ENUM ('male', 'female');
CREATE TYPE public.driver_tier AS ENUM ('standard', 'vip', 'female');
CREATE TYPE public.subscription_status AS ENUM ('active', 'pending', 'cancelled', 'expired', 'pending_assignment');
CREATE TYPE public.trip_status AS ENUM ('scheduled', 'driver_assigned', 'in_progress', 'completed', 'cancelled');
CREATE TYPE public.safety_report_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE public.transaction_type AS ENUM ('credit', 'debit');

-- -----------------------------------------------------------------------------
-- 2. TABLES
-- -----------------------------------------------------------------------------

-- PROFILES (Users)
-- Links to auth.users. Centralizes role management.
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role public.user_role NOT NULL DEFAULT 'user',
    full_name TEXT,
    phone_number TEXT,
    email TEXT,
    loyalty_points INT NOT NULL DEFAULT 0,
    parent_user_id UUID REFERENCES public.profiles(id), -- For family accounts
    rewarded_reports_count INT NOT NULL DEFAULT 0, -- Track monthly cap for safety rewards
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- DRIVERS
-- Extension of profiles for driver-specific data.
CREATE TABLE public.drivers (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_available BOOLEAN NOT NULL DEFAULT false,
    is_suspended BOOLEAN NOT NULL DEFAULT false,
    suspension_reason TEXT,
    vehicle_model TEXT,
    vehicle_plate TEXT,
    vehicle_year INT DEFAULT 2018,
    gender public.gender,
    tier public.driver_tier NOT NULL DEFAULT 'standard',
    current_location GEOGRAPHY(POINT, 4326),
    commission_rate NUMERIC(4, 2) NOT NULL DEFAULT 0.15,
    rating NUMERIC(3, 2) NOT NULL DEFAULT 5.00,
    rating_count INT NOT NULL DEFAULT 0,
    total_rides INT NOT NULL DEFAULT 0,
    total_earnings NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- SUBSCRIPTION PACKAGES
CREATE TABLE public.subscription_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    is_female_only BOOLEAN NOT NULL DEFAULT false,
    duration_days INT NOT NULL DEFAULT 30,
    plan_type TEXT NOT NULL DEFAULT 'monthly', -- 'monthly', '3_months', etc.
    discount_percentage INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- USER SUBSCRIPTIONS
CREATE TABLE public.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    package_id UUID NOT NULL REFERENCES public.subscription_packages(id),
    driver_id UUID REFERENCES public.drivers(id),
    beneficiary_id UUID REFERENCES public.profiles(id), -- Specific child/dependent
    parent_user_id UUID REFERENCES public.profiles(id), -- For family accounts (redundant with profile but requested)
    
    status public.subscription_status NOT NULL DEFAULT 'pending',
    renewal_status TEXT NOT NULL DEFAULT 'active', -- 'active', 'cancelled' (for renewal logic)
    
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    auto_renew BOOLEAN NOT NULL DEFAULT true,
    
    pickup_location GEOGRAPHY(POINT, 4326) NOT NULL,
    dropoff_location GEOGRAPHY(POINT, 4326) NOT NULL,
    pickup_time TIME NOT NULL, -- Recurring daily time
    return_time TIME NOT NULL, -- Recurring daily time
    
    add_on_ids TEXT[], -- Array of add-on IDs
    is_female_only BOOLEAN NOT NULL DEFAULT false,
    
    rides_used INT NOT NULL DEFAULT 0,
    extra_rides_charged INT NOT NULL DEFAULT 0,
    
    plan_type TEXT NOT NULL DEFAULT 'monthly', -- 'monthly', '3_months', etc.
    discount_amount NUMERIC(10, 2) DEFAULT 0.00,
    cancel_reason TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- TRIPS
CREATE TABLE public.trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID REFERENCES public.user_subscriptions(id),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    driver_id UUID REFERENCES public.drivers(id),
    family_member_id UUID REFERENCES public.profiles(id), -- If different from user_id
    
    status public.trip_status NOT NULL DEFAULT 'scheduled',
    
    pickup_location GEOGRAPHY(POINT, 4326) NOT NULL,
    dropoff_location GEOGRAPHY(POINT, 4326) NOT NULL,
    
    scheduled_time TIMESTAMPTZ NOT NULL,
    actual_pickup_time TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    
    cost NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    driver_earnings NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    
    actual_distance_km NUMERIC(10, 2),
    actual_duration_min NUMERIC(10, 2),
    
    is_female_driver_requested BOOLEAN NOT NULL DEFAULT false,
    is_assistant_requested BOOLEAN NOT NULL DEFAULT false,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- SAFETY REPORTS
CREATE TABLE public.safety_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    trip_id UUID REFERENCES public.trips(id),
    reported_id UUID REFERENCES public.profiles(id), -- The person being reported
    
    category TEXT, -- e.g., "Reckless Driving"
    description TEXT NOT NULL,
    evidence_paths TEXT[], -- Array of URLs
    
    status public.safety_report_status NOT NULL DEFAULT 'pending',
    
    points_awarded INT NOT NULL DEFAULT 0,
    reward_points_granted BOOLEAN NOT NULL DEFAULT false,
    
    approved_by UUID REFERENCES public.profiles(id), -- Admin ID
    approved_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- WALLETS
CREATE TABLE public.wallets (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id),
    balance NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    currency TEXT NOT NULL DEFAULT 'SAR',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- WALLET TRANSACTIONS
CREATE TABLE public.wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES public.wallets(user_id),
    amount NUMERIC(10, 2) NOT NULL,
    type public.transaction_type NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- SYSTEM CONFIGS
CREATE TABLE public.system_configs (
    key TEXT PRIMARY KEY, -- e.g., 'default'
    config JSONB NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ANALYTICS: DAILY STATS
CREATE TABLE public.stats_daily (
    date DATE PRIMARY KEY,
    total_trips INT NOT NULL DEFAULT 0,
    total_revenue NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total_delay_minutes NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    complaints_count INT NOT NULL DEFAULT 0,
    active_subscriptions INT NOT NULL DEFAULT 0,
    best_driver_id UUID REFERENCES public.drivers(id),
    worst_driver_id UUID REFERENCES public.drivers(id),
    average_delay_minutes NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ANALYTICS: GLOBAL STATS
CREATE TABLE public.stats_global (
    key TEXT PRIMARY KEY, -- e.g., 'summary'
    total_revenue NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total_trips INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- 3. INDEXES
-- -----------------------------------------------------------------------------

-- Spatial Indexes
CREATE INDEX idx_drivers_location ON public.drivers USING GIST (current_location);
CREATE INDEX idx_subs_pickup_loc ON public.user_subscriptions USING GIST (pickup_location);
CREATE INDEX idx_trips_pickup_loc ON public.trips USING GIST (pickup_location);

-- Foreign Key & Status Indexes
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_drivers_available ON public.drivers(is_available) WHERE is_available = true;
CREATE INDEX idx_subs_user_id ON public.user_subscriptions(user_id);
CREATE INDEX idx_subs_driver_id ON public.user_subscriptions(driver_id);
CREATE INDEX idx_subs_status ON public.user_subscriptions(status);
CREATE INDEX idx_trips_user_id ON public.trips(user_id);
CREATE INDEX idx_trips_driver_id ON public.trips(driver_id);
CREATE INDEX idx_trips_status ON public.trips(status);
CREATE INDEX idx_trips_scheduled_time ON public.trips(scheduled_time);
CREATE INDEX idx_wallet_tx_wallet_id ON public.wallet_transactions(wallet_id);

-- -----------------------------------------------------------------------------
-- 4. ROW LEVEL SECURITY (RLS)
-- -----------------------------------------------------------------------------

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.safety_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stats_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stats_global ENABLE ROW LEVEL SECURITY;

-- Helper Function to check role
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- POLICIES

-- Profiles
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Drivers
CREATE POLICY "Drivers are viewable by everyone" ON public.drivers FOR SELECT USING (true);
CREATE POLICY "Drivers can update own status" ON public.drivers FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can manage drivers" ON public.drivers FOR ALL USING (public.is_admin());

-- Subscription Packages
CREATE POLICY "Packages are viewable by everyone" ON public.subscription_packages FOR SELECT USING (true);
CREATE POLICY "Admins can manage packages" ON public.subscription_packages FOR ALL USING (public.is_admin());

-- User Subscriptions
CREATE POLICY "Users view own subscriptions" ON public.user_subscriptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Drivers view assigned subscriptions" ON public.user_subscriptions FOR SELECT USING (auth.uid() = driver_id);
CREATE POLICY "Admins view all subscriptions" ON public.user_subscriptions FOR SELECT USING (public.is_admin());
CREATE POLICY "Users can insert subscriptions" ON public.user_subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own subscriptions (cancel)" ON public.user_subscriptions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Admins can update subscriptions" ON public.user_subscriptions FOR UPDATE USING (public.is_admin());

-- Trips
CREATE POLICY "Users view own trips" ON public.trips FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Drivers view assigned trips" ON public.trips FOR SELECT USING (auth.uid() = driver_id);
CREATE POLICY "Admins view all trips" ON public.trips FOR SELECT USING (public.is_admin());
CREATE POLICY "Drivers can update assigned trips" ON public.trips FOR UPDATE USING (auth.uid() = driver_id);
CREATE POLICY "Admins can manage trips" ON public.trips FOR ALL USING (public.is_admin());

-- Safety Reports
CREATE POLICY "Users view own reports" ON public.safety_reports FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create reports" ON public.safety_reports FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins view all reports" ON public.safety_reports FOR SELECT USING (public.is_admin());
CREATE POLICY "Admins can update reports" ON public.safety_reports FOR UPDATE USING (public.is_admin());

-- Wallets
CREATE POLICY "Users view own wallet" ON public.wallets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins view all wallets" ON public.wallets FOR SELECT USING (public.is_admin());
-- NO UPDATE POLICY FOR USERS: Wallets updated via Edge Functions only (Service Role)

-- Wallet Transactions
CREATE POLICY "Users view own transactions" ON public.wallet_transactions FOR SELECT USING (wallet_id = auth.uid());
CREATE POLICY "Admins view all transactions" ON public.wallet_transactions FOR SELECT USING (public.is_admin());

-- System Configs
CREATE POLICY "Configs viewable by authenticated users" ON public.system_configs FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins can manage configs" ON public.system_configs FOR ALL USING (public.is_admin());

-- Analytics
CREATE POLICY "Admins view analytics" ON public.stats_daily FOR SELECT USING (public.is_admin());
CREATE POLICY "Admins view global stats" ON public.stats_global FOR SELECT USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- 5. TRIGGERS
-- -----------------------------------------------------------------------------

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', 'user');
  
  -- Create empty wallet
  INSERT INTO public.wallets (user_id) VALUES (new.id);
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_modtime BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_drivers_modtime BEFORE UPDATE ON public.drivers FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_subs_modtime BEFORE UPDATE ON public.user_subscriptions FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_trips_modtime BEFORE UPDATE ON public.trips FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
