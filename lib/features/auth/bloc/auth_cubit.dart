import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';

// ─── State ──────────────────────────────────────────────────────────────

class ProfileState extends Equatable {
  final UserProfile? user;
  final bool isSetup;
  final bool isLoading;
  final String? errorMessage;

  const ProfileState({
    this.user,
    this.isSetup = false,
    this.isLoading = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    UserProfile? user,
    bool? isSetup,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isSetup: isSetup ?? this.isSetup,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [user, isSetup, isLoading, errorMessage];
}

// ─── Cubit ──────────────────────────────────────────────────────────────

class AuthCubit extends Cubit<ProfileState> {
  final AuthRepository _repository;

  AuthCubit({required AuthRepository repository})
      : _repository = repository,
        super(const ProfileState());

  Future<void> checkProfile() async {
    emit(state.copyWith(isLoading: true));

    final result = await _repository.isProfileSetup();
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (isSetup) => emit(state.copyWith(isSetup: isSetup, isLoading: false)),
    );
  }

  Future<void> setupProfile(ProfileSetupData data) async {
    emit(state.copyWith(isLoading: true));

    final result = await _repository.setupProfile(data);
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        user: user,
        isSetup: true,
        isLoading: false,
        errorMessage: null,
      )),
    );
  }

  Future<void> loadProfile() async {
    emit(state.copyWith(isLoading: true));

    final result = await _repository.loadProfile();
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        user: user,
        isSetup: user != null,
        isLoading: false,
        errorMessage: null,
      )),
    );
  }
}
