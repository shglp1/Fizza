import 'package:flutter/material.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:get_it/get_it.dart';

class DriverActiveTripScreen extends StatefulWidget {
  final TripEntity trip;

  const DriverActiveTripScreen({super.key, required this.trip});

  @override
  State<DriverActiveTripScreen> createState() => _DriverActiveTripScreenState();
}

class _DriverActiveTripScreenState extends State<DriverActiveTripScreen> {
  final _tripRepo = GetIt.I<ITripRepository>();
  late String _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.trip.status;
  }

  Future<void> _startTrip() async {
    setState(() => _isLoading = true);
    final result = await _tripRepo.startTrip(widget.trip.id);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (l) => _showError(l.message),
      (_) => setState(() => _status = 'in_progress'),
    );
  }

  Future<void> _completeTrip() async {
    setState(() => _isLoading = true);
    // Mock distance/duration for now
    final result = await _tripRepo.completeTrip(widget.trip.id, 5.0, 15.0);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (l) => _showError('Could not complete the trip. Please check your connection and try again.'),
      (_) {
        setState(() => _status = 'completed');
        Navigator.pop(context); // Go back to home
      },
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Current Trip')),
      body: Column(
        children: [
          // Static Map
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[300],
              child: const Center(
                child: Text('Static Map (No Live GPS)', style: TextStyle(color: Colors.black54)),
              ),
            ),
          ),
          
          // Details
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  Wrap(
                    spacing: 8,
                    children: [
                      if (widget.trip.isFemaleDriverRequested)
                        const Chip(label: Text('Female Only'), backgroundColor: Colors.pinkAccent),
                      if (widget.trip.isAssistantRequested)
                        const Chip(label: Text('Assistant Req'), backgroundColor: Colors.orangeAccent),
                      // Add other tags based on add-ons if available in TripEntity
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Locations
                  ListTile(
                    leading: const Icon(Icons.my_location, color: Colors.green),
                    title: const Text('Pickup'),
                    subtitle: Text(widget.trip.pickupLocation.address),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: const Text('Dropoff'),
                    subtitle: Text(widget.trip.dropoffLocation.address),
                  ),
                  
                  const Spacer(),
                  
                  // Buttons
                  if (_status == 'scheduled' || _status == 'driver_assigned')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: _isLoading ? null : _startTrip,
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('Start Trip', style: TextStyle(color: Colors.white)),
                      ),
                    )
                  else if (_status == 'in_progress')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        onPressed: _isLoading ? null : _completeTrip,
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('Complete Trip', style: TextStyle(color: Colors.white)),
                      ),
                    )
                  else
                    const Center(child: Text('Trip Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
