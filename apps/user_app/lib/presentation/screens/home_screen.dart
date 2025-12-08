import 'package:flutter/material.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'active_trip_screen.dart';
import 'subscription_details_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final _subscriptionRepo = GetIt.I<ISubscriptionRepository>();
  final _tripRepo = GetIt.I<ITripRepository>();
  // Hardcoded user ID for MVP
  final String _userId = 'test_user_id'; 

  Future<Map<String, dynamic>> _fetchData() async {
    final subResult = await _subscriptionRepo.getCurrentSubscription(_userId);
    final tripsResult = await _tripRepo.getTripHistory(_userId);

    return {
      'subscription': subResult.fold((l) => null, (r) => r),
      'trips': tripsResult.fold((l) => <TripEntity>[], (r) => r),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FIZZA Home')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final subscription = snapshot.data?['subscription'] as UserSubscriptionEntity?;
          final allTrips = snapshot.data?['trips'] as List<TripEntity>? ?? [];
          
          // Filter for today's trips
          final today = DateTime.now();
          final todaysTrips = allTrips.where((t) {
            return t.scheduledTime.year == today.year &&
                   t.scheduledTime.month == today.month &&
                   t.scheduledTime.day == today.day;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubscriptionSection(context, subscription),
                const SizedBox(height: 24),
                const Text('Today\'s Trips', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTripsList(context, todaysTrips),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionSection(BuildContext context, UserSubscriptionEntity? subscription) {
    if (subscription == null || !subscription.isActive) {
      return Card(
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('No active subscription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('You don’t have an active subscription yet.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to plans
                },
                child: const Text('Browse plans'),
              ),
            ],
          ),
        ),
      );
    }

    // Check expiry
    final daysLeft = subscription.endDate.difference(DateTime.now()).inDays;
    final showBanner = daysLeft <= 5;

    return Column(
      children: [
        if (showBanner)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.orange[100],
            child: Text(
              'Subscription ends in $daysLeft days – renew now',
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        Card(
          elevation: 4,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SubscriptionDetailsScreen(subscription: subscription)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(subscription.planType.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Beneficiary: ${subscription.beneficiaryId ?? "Me"}'),
                  const SizedBox(height: 4),
                  Text('Valid until: ${DateFormat('MMM dd, yyyy').format(subscription.endDate)}'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTripsList(BuildContext context, List<TripEntity> trips) {
    if (trips.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No trips scheduled for today.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.directions_car),
            title: Text('Trip to ${trip.dropoffLocation.address}'), // Assuming LocationEntity has address
            subtitle: Text(DateFormat('hh:mm a').format(trip.scheduledTime)),
            trailing: Chip(
              label: Text(trip.status),
              backgroundColor: _getStatusColor(trip.status),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserActiveTripScreen(trip: trip)),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green[100]!;
      case 'in_progress': return Colors.blue[100]!;
      case 'cancelled': return Colors.red[100]!;
      default: return Colors.grey[200]!;
    }
  }
}
