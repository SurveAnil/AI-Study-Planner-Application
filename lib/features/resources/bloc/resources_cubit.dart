import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/resources_repository.dart';

// ─── State ──────────────────────────────────────────────────────────────

class ResourcesState extends Equatable {
  final List<Resource> files;
  final String activeFilter; // all | pdf | video | ppt | practice_set
  final bool isLoading;
  final String? errorMessage;

  const ResourcesState({
    this.files = const [],
    this.activeFilter = 'all',
    this.isLoading = false,
    this.errorMessage,
  });

  ResourcesState copyWith({
    List<Resource>? files,
    String? activeFilter,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ResourcesState(
      files: files ?? this.files,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [files, activeFilter, isLoading, errorMessage];
}

// ─── Cubit ──────────────────────────────────────────────────────────────

class ResourcesCubit extends Cubit<ResourcesState> {
  final ResourcesRepository _repository;

  ResourcesCubit({required ResourcesRepository repository})
      : _repository = repository,
        super(const ResourcesState());

  Future<void> loadAll() async {
    emit(state.copyWith(isLoading: true));

    final result = await _repository.loadAll();
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (files) => emit(state.copyWith(
        files: files,
        isLoading: false,
        activeFilter: 'all',
        errorMessage: null,
      )),
    );
  }

  Future<void> filter(String type) async {
    emit(state.copyWith(isLoading: true, activeFilter: type));

    final result = type == 'all'
        ? await _repository.loadAll()
        : await _repository.filterByType(type);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (files) => emit(state.copyWith(
        files: files,
        isLoading: false,
        errorMessage: null,
      )),
    );
  }

  Future<void> addResource(Resource resource) async {
    final result = await _repository.addResource(resource);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => loadAll(),
    );
  }
}
