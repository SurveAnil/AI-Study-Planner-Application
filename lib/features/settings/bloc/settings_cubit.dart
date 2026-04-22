import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/settings_repository.dart';

// ─── State ──────────────────────────────────────────────────────────────

class SettingsState extends Equatable {
  final UserSettings settings;
  final bool isLoading;
  final String? errorMessage;

  const SettingsState({
    this.settings = const UserSettings(),
    this.isLoading = false,
    this.errorMessage,
  });

  SettingsState copyWith({
    UserSettings? settings,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [settings, isLoading, errorMessage];
}

// ─── Cubit ──────────────────────────────────────────────────────────────

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit({required SettingsRepository repository})
      : _repository = repository,
        super(const SettingsState());

  Future<void> loadSettings() async {
    emit(state.copyWith(isLoading: true));

    final result = await _repository.loadSettings();
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (settings) => emit(state.copyWith(
        settings: settings,
        isLoading: false,
        errorMessage: null,
      )),
    );
  }

  Future<void> updateGoal(int hours) async {
    final updated = state.settings.copyWith(dailyGoalHours: hours);
    await _saveSettings(updated);
  }

  Future<void> toggleDarkMode() async {
    final updated = state.settings.copyWith(
      darkModeEnabled: !state.settings.darkModeEnabled,
    );
    await _saveSettings(updated);
  }

  Future<void> toggleNLP(bool enabled) async {
    final updated = state.settings.copyWith(nlpInputEnabled: enabled);
    await _saveSettings(updated);
  }

  Future<void> togglePrediction(bool enabled) async {
    final updated = state.settings.copyWith(
      performancePredictionEnabled: enabled,
    );
    await _saveSettings(updated);
  }

  Future<void> toggleWeakSubjectDetection(bool enabled) async {
    final updated = state.settings.copyWith(
      weakSubjectDetectionEnabled: enabled,
    );
    await _saveSettings(updated);
  }

  Future<void> updateAiModel(String model) async {
    final updated = state.settings.copyWith(aiModel: model);
    await _saveSettings(updated);
  }

  Future<void> toggleUseCustomApi(bool enabled) async {
    final updated = state.settings.copyWith(useCustomApi: enabled);
    await _saveSettings(updated);
  }

  Future<void> updateOpenRouterApiKey(String key) async {
    final updated = state.settings.copyWith(openRouterApiKey: key);
    await _saveSettings(updated);
  }

  Future<void> _saveSettings(UserSettings settings) async {
    final result = await _repository.updateSettings(settings);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(state.copyWith(settings: settings, errorMessage: null)),
    );
  }
}
