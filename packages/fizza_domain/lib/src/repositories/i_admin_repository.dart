import 'package:dartz/dartz.dart';
import 'package:fizza_core/fizza_core.dart';
import '../entities/admin_dashboard_entity.dart';
import '../entities/driver_entity.dart';
import '../entities/safety_report_entity.dart';
import '../entities/system_config_entity.dart';

abstract class IAdminRepository {
  // Dashboard
  Future<Either<Failure, AdminDashboardEntity>> getDashboardStats();
  
  // Driver Management
  Future<Either<Failure, List<DriverEntity>>> getPendingDrivers();
  Future<Either<Failure, Unit>> approveDriver(String driverId);
  Future<Either<Failure, Unit>> rejectDriver(String driverId, String reason);
  
  // Complaints Management
  Future<Either<Failure, List<SafetyReportEntity>>> getPendingComplaints();
  Future<Either<Failure, Unit>> resolveComplaint(String reportId, String resolutionNotes);
  
  // Financials (Simplified for now)
  Future<Either<Failure, Map<String, dynamic>>> getFinancialReport({required DateTime startDate, required DateTime endDate});

  // System Configuration
  Future<Either<Failure, SystemConfigEntity>> getSystemConfig();
  Future<Either<Failure, Unit>> updateSystemConfig(SystemConfigEntity config);
}
