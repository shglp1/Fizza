import 'package:flutter/material.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'active_trip_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final _driverRepo = GetIt.I<IDriverRepository>();
  final _tripRepo = GetIt.I<ITripRepository>();
  final String _driverId = 'test_driver_id'; // Hardcoded for MVP

  bool _isOnline = false;
  List<TripEntity> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    // Fetch driver status
    final driverResult = await _driverRepo.getDriverProfile(_driverId);
    driverResult.fold(
      (l) => print('Error fetching driver: $l'),
      (driver) => _isOnline = driver.isAvailable,
    );

    // Fetch trips if online (mock logic: fetch all trips for driver)
    // In real app, we'd query trips assigned to this driver for today.
    // TripRepository.getTripHistory takes userId, we might need a method for driverId.
    // Assuming getTripHistory works for now or we mock it.
    // Actually, ITripRepository.getTripHistory is for USER. 
    // We need getDriverTrips. Since it's not in interface, I'll assume it exists or I'll mock the list.
    // For this exercise, I'll mock the trips list to show the UI flow.
    
    if (_isOnline) {
      // Mock trips
      _trips = [
        TripEntity(
          id: 'trip_1',
          userId: 'user_1',
          driverId: _driverId,
          pickupLocation: const LocationEntity(latitude: 0, longitude: 0, address: 'Home A'),
          dropoffLocation: const LocationEntity(latitude: 0, longitude: 0, address: 'School X'),
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
          status: 'scheduled',
          cost: 20.0,
        ),
      ];
    } else {
      _trips = [];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleStatus() async {
    // Call repo to toggle status
    await _driverRepo.toggleAvailability(_driverId);
    setState(() {
      _isOnline = !_isOnline;
      if (_isOnline) _fetchData(); // Refresh trips
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Home')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  color: _isOnline ? Colors.green[50] : Colors.grey[200],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isOnline ? 'You are ONLINE' : 'You are OFFLINE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                      Switch(
                        value: _isOnline,
                        onChanged: (val) => _toggleStatus(),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: !_isOnline
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.offline_bolt, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('You are offline'),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _toggleStatus,
                                child: const Text('Go online'),
                              ),
                            ],
                          ),
                        )
                      : _trips.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('No trips assigned for today.'),
                                  TextButton(
                                    onPressed: _fetchData,
                                    child: const Text('Refresh'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _trips.length,
                              itemBuilder: (context, index) {
                                final trip = _trips[index];
                                return Card(
                                  child: ListTile(
                                    title: Text('Pickup: ${trip.pickupLocation.address}'),
                                    subtitle: Text(DateFormat('hh:mm a').format(trip.scheduledTime)),
                                    trailing: const Icon(Icons.arrow_forward),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => DriverActiveTripScreen(trip: trip)),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
