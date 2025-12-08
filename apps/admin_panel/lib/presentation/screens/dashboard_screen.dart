import 'package:flutter/material.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:get_it/get_it.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _adminRepo = GetIt.I<IAdminRepository>();
  final _safetyRepo = GetIt.I<ISafetyRepository>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Drivers'),
            Tab(text: 'Complaints'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DriversTab(adminRepo: _adminRepo),
          _ComplaintsTab(safetyRepo: _safetyRepo),
          _AnalyticsTab(adminRepo: _adminRepo),
        ],
      ),
    );
  }
}

class _DriversTab extends StatelessWidget {
  final IAdminRepository adminRepo;
  const _DriversTab({required this.adminRepo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, List<DriverEntity>>>(
      future: adminRepo.getPendingDrivers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading drivers'));
        }
        
        return snapshot.data!.fold(
          (l) => Center(child: Text('Error: ${l.message}')),
          (drivers) {
            if (drivers.isEmpty) {
              return const Center(
                child: Text('No drivers waiting for approval.'),
              );
            }
            return ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(drivers[index].fullName),
                subtitle: Text('Pending Approval'),
              ),
            );
          },
        );
      },
    );
  }
}

class _ComplaintsTab extends StatelessWidget {
  final ISafetyRepository safetyRepo;
  const _ComplaintsTab({required this.safetyRepo});

  @override
  Widget build(BuildContext context) {
    // Assuming getPendingReports exists or similar
    return FutureBuilder<Either<Failure, List<SafetyReportEntity>>>(
      future: safetyRepo.getSafetyReports('pending'), // Mock status filter
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return snapshot.data?.fold(
          (l) => Center(child: Text('Error: ${l.message}')),
          (reports) {
            if (reports.isEmpty) {
              return const Center(
                child: Text('No new safety reports. You’re all caught up.'),
              );
            }
            return ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(reports[index].description),
                subtitle: Text('Reported by ${reports[index].userId}'),
              ),
            );
          },
        ) ?? const Center(child: Text('No new safety reports. You’re all caught up.'));
      },
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  final IAdminRepository adminRepo;
  const _AnalyticsTab({required this.adminRepo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, Map<String, dynamic>>>(
      future: adminRepo.getGlobalStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return snapshot.data?.fold(
          (l) => const Center(child: Text('Could not load analytics. Please try again later.')),
          (stats) {
            if (stats.isEmpty) {
              return const Center(
                child: Text('No analytics yet. Stats will appear after the first full day of trips.'),
              );
            }
            return ListView(
              children: stats.entries.map((e) => ListTile(
                title: Text(e.key),
                trailing: Text(e.value.toString()),
              )).toList(),
            );
          },
        ) ?? const Center(child: Text('Could not load analytics. Please try again later.'));
      },
    );
  }
}
