import 'package:flutter/material.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:get_it/get_it.dart';

class UserActiveTripScreen extends StatefulWidget {
  final TripEntity trip;

  const UserActiveTripScreen({super.key, required this.trip});

  @override
  State<UserActiveTripScreen> createState() => _UserActiveTripScreenState();
}

class _UserActiveTripScreenState extends State<UserActiveTripScreen> {
  final _driverRepo = GetIt.I<IDriverRepository>();
  DriverEntity? _driver;
  bool _isLoadingDriver = true;

  @override
  void initState() {
    super.initState();
    _fetchDriver();
  }

  Future<void> _fetchDriver() async {
    if (widget.trip.driverId == null) {
      setState(() => _isLoadingDriver = false);
      return;
    }

    final result = await _driverRepo.getDriverProfile(widget.trip.driverId!);
    if (mounted) {
      setState(() {
        _driver = result.fold((l) => null, (r) => r);
        _isLoadingDriver = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: Column(
        children: [
          // Static Map Container
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: Colors.grey[300],
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.map, size: 64, color: Colors.grey),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: Colors.black54,
                      child: const Text(
                        'Static Map (No Live GPS)',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Trip Info
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  Row(
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.trip.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStatusText(widget.trip.status),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  
                  // Locations
                  _buildLocationRow(Icons.home, 'Home', 'Origin'),
                  _buildDottedLine(),
                  _buildLocationRow(Icons.school, 'School/Work', 'Destination'),
                  
                  const Divider(height: 32),
                  
                  // Driver Info
                  if (_isLoadingDriver)
                    const Center(child: CircularProgressIndicator())
                  else if (_driver != null)
                    Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.person)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_driver!.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${_driver!.vehicleModel} • ${_driver!.vehiclePlate}'),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(_driver!.rating.toString()),
                      ],
                    )
                  else
                    const Text('Driver info unavailable'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String subLabel) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildDottedLine() {
    return Container(
      margin: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      height: 20,
      width: 2,
      child: Column(
        children: List.generate(4, (index) => Expanded(
          child: Container(
            width: 2,
            color: index % 2 == 0 ? Colors.grey : Colors.transparent,
          ),
        )),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed': return 'Trip Completed';
      case 'in_progress': return 'Trip in Progress';
      case 'cancelled': return 'Trip Cancelled';
      case 'driver_assigned': return 'Driver Assigned';
      default: return 'Scheduled';
    }
  }
}
