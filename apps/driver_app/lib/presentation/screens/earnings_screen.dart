import 'package:flutter/material.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:get_it/get_it.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  final _driverRepo = GetIt.I<IDriverRepository>();
  final String _driverId = 'test_driver_id';
  
  DriverEntity? _driver;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final result = await _driverRepo.getDriverProfile(_driverId);
    if (mounted) {
      setState(() {
        _driver = result.fold((l) => null, (r) => r);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _driver == null
              ? const Center(child: Text('Could not load earnings'))
              : _driver!.totalEarnings == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.attach_money, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No earnings yet.'),
                          Text('Complete trips to see your income here.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  const Text('Total Earnings', style: TextStyle(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'SAR ${_driver!.totalEarnings.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                  const Divider(height: 32),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Trips Completed: ${_driver!.totalRides}'),
                                      // Add more stats if available
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
