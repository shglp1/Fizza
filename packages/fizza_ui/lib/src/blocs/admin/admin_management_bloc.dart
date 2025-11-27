import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class AdminManagementEvent extends Equatable {
  const AdminManagementEvent();
  @override
  List<Object> get props => [];
}

class LoadPendingDrivers extends AdminManagementEvent {}

class ApproveDriver extends AdminManagementEvent {
  final String driverId;
  const ApproveDriver(this.driverId);
  @override
  List<Object> get props => [driverId];
}

class RejectDriver extends AdminManagementEvent {
  final String driverId;
  final String reason;
  const RejectDriver(this.driverId, this.reason);
  @override
  List<Object> get props => [driverId, reason];
}

class LoadPendingComplaints extends AdminManagementEvent {}

class ResolveComplaint extends AdminManagementEvent {
  final String reportId;
  final String resolutionNotes;
  const ResolveComplaint(this.reportId, this.resolutionNotes);
  @override
  List<Object> get props => [reportId, resolutionNotes];
}

// States
abstract class AdminManagementState extends Equatable {
  const AdminManagementState();
  @override
  List<Object> get props => [];
}

class AdminManagementInitial extends AdminManagementState {}
class AdminManagementLoading extends AdminManagementState {}
class AdminPendingDriversLoaded extends AdminManagementState {
  final List<DriverEntity> drivers;
  const AdminPendingDriversLoaded(this.drivers);
  @override
  List<Object> get props => [drivers];
}
class AdminPendingComplaintsLoaded extends AdminManagementState {
  final List<SafetyReportEntity> complaints;
  const AdminPendingComplaintsLoaded(this.complaints);
  @override
  List<Object> get props => [complaints];
}
class AdminOperationSuccess extends AdminManagementState {
  final String message;
  const AdminOperationSuccess(this.message);
  @override
  List<Object> get props => [message];
}
class AdminManagementError extends AdminManagementState {
  final String message;
  const AdminManagementError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
@injectable
class AdminManagementBloc extends Bloc<AdminManagementEvent, AdminManagementState> {
  final IAdminRepository _repository;

  AdminManagementBloc(this._repository) : super(AdminManagementInitial()) {
    on<LoadPendingDrivers>(_onLoadPendingDrivers);
    on<ApproveDriver>(_onApproveDriver);
    on<RejectDriver>(_onRejectDriver);
    on<LoadPendingComplaints>(_onLoadPendingComplaints);
    on<ResolveComplaint>(_onResolveComplaint);
  }

  Future<void> _onLoadPendingDrivers(LoadPendingDrivers event, Emitter<AdminManagementState> emit) async {
    emit(AdminManagementLoading());
    final result = await _repository.getPendingDrivers();
    result.fold(
      (failure) => emit(AdminManagementError(failure.message)),
      (drivers) => emit(AdminPendingDriversLoaded(drivers)),
    );
  }

  Future<void> _onApproveDriver(ApproveDriver event, Emitter<AdminManagementState> emit) async {
    emit(AdminManagementLoading());
    final result = await _repository.approveDriver(event.driverId);
    result.fold(
      (failure) => emit(AdminManagementError(failure.message)),
      (_) {
        emit(const AdminOperationSuccess('Driver approved successfully'));
        add(LoadPendingDrivers());
      },
    );
  }

  Future<void> _onRejectDriver(RejectDriver event, Emitter<AdminManagementState> emit) async {
    emit(AdminManagementLoading());
    final result = await _repository.rejectDriver(event.driverId, event.reason);
    result.fold(
      (failure) => emit(AdminManagementError(failure.message)),
      (_) {
        emit(const AdminOperationSuccess('Driver rejected'));
        add(LoadPendingDrivers());
      },
    );
  }

  Future<void> _onLoadPendingComplaints(LoadPendingComplaints event, Emitter<AdminManagementState> emit) async {
    emit(AdminManagementLoading());
    final result = await _repository.getPendingComplaints();
    result.fold(
      (failure) => emit(AdminManagementError(failure.message)),
      (complaints) => emit(AdminPendingComplaintsLoaded(complaints)),
    );
  }

  Future<void> _onResolveComplaint(ResolveComplaint event, Emitter<AdminManagementState> emit) async {
    emit(AdminManagementLoading());
    final result = await _repository.resolveComplaint(event.reportId, event.resolutionNotes);
    result.fold(
      (failure) => emit(AdminManagementError(failure.message)),
      (_) {
        emit(const AdminOperationSuccess('Complaint resolved'));
        add(LoadPendingComplaints());
      },
    );
  }
}
