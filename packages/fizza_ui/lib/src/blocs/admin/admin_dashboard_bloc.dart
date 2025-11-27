import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class AdminDashboardEvent extends Equatable {
  const AdminDashboardEvent();
  @override
  List<Object> get props => [];
}

class LoadDashboardStats extends AdminDashboardEvent {}

class LoadFinancialReport extends AdminDashboardEvent {
  final DateTime startDate;
  final DateTime endDate;
  const LoadFinancialReport(this.startDate, this.endDate);
  @override
  List<Object> get props => [startDate, endDate];
}

// States
abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();
  @override
  List<Object> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {}
class AdminDashboardLoading extends AdminDashboardState {}
class AdminDashboardStatsLoaded extends AdminDashboardState {
  final AdminDashboardEntity stats;
  const AdminDashboardStatsLoaded(this.stats);
  @override
  List<Object> get props => [stats];
}
class AdminFinancialReportLoaded extends AdminDashboardState {
  final Map<String, dynamic> report;
  const AdminFinancialReportLoaded(this.report);
  @override
  List<Object> get props => [report];
}
class AdminDashboardError extends AdminDashboardState {
  final String message;
  const AdminDashboardError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
@injectable
class AdminDashboardBloc extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final IAdminRepository _repository;

  AdminDashboardBloc(this._repository) : super(AdminDashboardInitial()) {
    on<LoadDashboardStats>(_onLoadStats);
    on<LoadFinancialReport>(_onLoadFinancials);
  }

  Future<void> _onLoadStats(LoadDashboardStats event, Emitter<AdminDashboardState> emit) async {
    emit(AdminDashboardLoading());
    final result = await _repository.getDashboardStats();
    result.fold(
      (failure) => emit(AdminDashboardError(failure.message)),
      (stats) => emit(AdminDashboardStatsLoaded(stats)),
    );
  }

  Future<void> _onLoadFinancials(LoadFinancialReport event, Emitter<AdminDashboardState> emit) async {
    emit(AdminDashboardLoading());
    final result = await _repository.getFinancialReport(startDate: event.startDate, endDate: event.endDate);
    result.fold(
      (failure) => emit(AdminDashboardError(failure.message)),
      (report) => emit(AdminFinancialReportLoaded(report)),
    );
  }
}
