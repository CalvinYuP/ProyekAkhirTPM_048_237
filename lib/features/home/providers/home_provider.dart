// lib/features/home/providers/home_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../data/models/destination_model.dart';
import '../../../../data/repositories/destination_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
});

final repositoryProvider = Provider<DestinationRepository>((ref) {
  return DestinationRepository(); // ← Tanpa parameter!
});

class HomeState {
  final List<Destination> allDestinations;
  final List<Destination> filteredDestinations;
  final String selectedCategory;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  HomeState({
    this.allDestinations = const [],
    this.filteredDestinations = const [],
    this.selectedCategory = 'Semua',
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    List<Destination>? allDestinations,
    List<Destination>? filteredDestinations,
    String? selectedCategory,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      allDestinations: allDestinations ?? this.allDestinations,
      filteredDestinations: filteredDestinations ?? this.filteredDestinations,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.watch(repositoryProvider));
});

class HomeNotifier extends StateNotifier<HomeState> {
  final DestinationRepository _repository;

  HomeNotifier(this._repository) : super(HomeState()) {
    loadDestinations();
  }

  Future<void> loadDestinations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final destinations = await _repository.getDestinations();
      state = state.copyWith(
        isLoading: false,
        allDestinations: destinations,
        filteredDestinations: destinations,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data destinasi',
      );
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void updateCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    _applyFilters();
  }

  void _applyFilters() {
    var result = state.allDestinations;
    
    // Apply category filter
    result = _repository.filterByCategory(result, state.selectedCategory);
    
    // Apply search filter
    result = _repository.searchDestinations(result, state.searchQuery);
    
    state = state.copyWith(filteredDestinations: result);
  }

  Future<void> refresh() async {
    await loadDestinations();
  }
}