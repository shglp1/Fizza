import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class FamilyEvent extends Equatable {
  const FamilyEvent();
  @override
  List<Object> get props => [];
}

class LoadFamilyMembers extends FamilyEvent {
  final String userId;
  const LoadFamilyMembers(this.userId);
  @override
  List<Object> get props => [userId];
}

class AddFamilyMember extends FamilyEvent {
  final FamilyMemberEntity member;
  const AddFamilyMember(this.member);
  @override
  List<Object> get props => [member];
}

class UpdateFamilyMember extends FamilyEvent {
  final FamilyMemberEntity member;
  const UpdateFamilyMember(this.member);
  @override
  List<Object> get props => [member];
}

class DeleteFamilyMember extends FamilyEvent {
  final String memberId;
  const DeleteFamilyMember(this.memberId);
  @override
  List<Object> get props => [memberId];
}

// States
abstract class FamilyState extends Equatable {
  const FamilyState();
  @override
  List<Object> get props => [];
}

class FamilyInitial extends FamilyState {}
class FamilyLoading extends FamilyState {}
class FamilyLoaded extends FamilyState {
  final List<FamilyMemberEntity> members;
  const FamilyLoaded(this.members);
  @override
  List<Object> get props => [members];
}
class FamilyError extends FamilyState {
  final String message;
  const FamilyError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
@injectable
class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final IFamilyRepository _repository;

  FamilyBloc(this._repository) : super(FamilyInitial()) {
    on<LoadFamilyMembers>(_onLoadFamilyMembers);
    on<AddFamilyMember>(_onAddFamilyMember);
    on<UpdateFamilyMember>(_onUpdateFamilyMember);
    on<DeleteFamilyMember>(_onDeleteFamilyMember);
  }

  Future<void> _onLoadFamilyMembers(LoadFamilyMembers event, Emitter<FamilyState> emit) async {
    emit(FamilyLoading());
    final result = await _repository.getFamilyMembers(event.userId);
    result.fold(
      (failure) => emit(FamilyError(failure.message)),
      (members) => emit(FamilyLoaded(members)),
    );
  }

  Future<void> _onAddFamilyMember(AddFamilyMember event, Emitter<FamilyState> emit) async {
    emit(FamilyLoading());
    final result = await _repository.addFamilyMember(event.member);
    result.fold(
      (failure) => emit(FamilyError(failure.message)),
      (_) => add(LoadFamilyMembers(event.member.parentId)),
    );
  }

  Future<void> _onUpdateFamilyMember(UpdateFamilyMember event, Emitter<FamilyState> emit) async {
    emit(FamilyLoading());
    final result = await _repository.updateFamilyMember(event.member);
    result.fold(
      (failure) => emit(FamilyError(failure.message)),
      (_) => add(LoadFamilyMembers(event.member.parentId)),
    );
  }

  Future<void> _onDeleteFamilyMember(DeleteFamilyMember event, Emitter<FamilyState> emit) async {
    // Note: We need parentId to reload. 
    // Ideally the event should carry parentId or we store it in state.
    // For now, assuming we can't easily reload without parentId.
    // I'll emit error or just success without reload if I don't have parentId.
    // But wait, if I have loaded members, I know the parentId.
    if (state is FamilyLoaded) {
      final parentId = (state as FamilyLoaded).members.first.parentId;
      emit(FamilyLoading());
      final result = await _repository.deleteFamilyMember(event.memberId);
      result.fold(
        (failure) => emit(FamilyError(failure.message)),
        (_) => add(LoadFamilyMembers(parentId)),
      );
    }
  }
}
