import 'package:flutter/material.dart';
import '../models/protein.dart';
import '../services/protein_service.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class ProteinProvider with ChangeNotifier {
  final ProteinService _proteinService = ProteinService();

  List<Protein> _proteins = [];
  List<Protein> _allProteins = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _error = '';
  String _searchQuery = '';

  // Pagination properties
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  bool _hasMoreData = true;
  List<String> _allLigandIds = [];

  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  // Getters
  List<Protein> get proteins => _proteins;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String get errorMessage => _error;
  String get searchQuery => _searchQuery;
  bool get hasMoreData => _hasMoreData;

  // Load initial proteins (first page)
  Future<void> loadProteins() async {
    _isLoading = true;
    _error = '';
    _currentPage = 0;
    _proteins.clear();
    _hasMoreData = true;
    notifyListeners();

    try {
      // Load all ligand IDs first
      await _loadAllLigandIds();

      // Load first page
      await _loadPage();
    } catch (e) {
      _error = 'Failed to load proteins: $e';
      _hasMoreData = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more proteins (next page)
  Future<void> loadMoreProteins() async {
    if (_isLoadingMore || !_hasMoreData) return;

    _isLoadingMore = true;
    _error = '';
    notifyListeners();

    try {
      await _loadPage();
    } catch (e) {
      _error = 'Failed to load more proteins: $e';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Load all ligand IDs from file
  Future<void> _loadAllLigandIds() async {
    try {
      final String fileContent = await rootBundle.loadString(
        'assets/ligands.txt',
      );
      _allLigandIds = fileContent
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      print('Loaded ${_allLigandIds.length} ligand IDs');
    } catch (e) {
      print('Error loading ligand IDs: $e');
      throw e;
    }
  }

  // Load a specific page of proteins
  Future<void> _loadPage() async {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    // Check if we have more data
    if (startIndex >= _allLigandIds.length) {
      _hasMoreData = false;
      return;
    }

    // Get ligand IDs for this page
    final pageIds = _allLigandIds.sublist(
      startIndex,
      endIndex > _allLigandIds.length ? _allLigandIds.length : endIndex,
    );

    print('Loading page $_currentPage: ${pageIds.length} proteins');

    // Fetch proteins for this page
    for (String ligandId in pageIds) {
      try {
        final protein = await _proteinService.fetchProteinById(ligandId);

        _proteins.add(protein);
        if (!_allProteins.any((p) => p.name == protein.name)) {
          _allProteins.add(protein);
        }

        // Small delay to avoid overwhelming the API
        // await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('Failed to fetch protein for $ligandId: $e');
        // Add placeholder protein
      }
    }

    _currentPage++;

    // Check if we've reached the end
    if (endIndex >= _allLigandIds.length) {
      _hasMoreData = false;
    }
  }

  Future<void> searchProteins(String query) async {
    _searchQuery = query;

    // Cancel the previous timer if it exists
    _debounceTimer?.cancel();

    // If query is empty, clear search immediately
    if (query.isEmpty) {
      await loadProteins();
      return;
    }

    // Set up a new timer
    _debounceTimer = Timer(_debounceDuration, () async {
      await _performSearch(query);
    });
  }

  // Search proteins
  Future<void> _performSearch(String query) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      var searchResults = _allProteins
          .where(
            (protein) =>
                protein.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
      if (searchResults.isEmpty) {
        final matchingIds = _allLigandIds
            .where((id) => id.toLowerCase().contains(query.toLowerCase()))
            .take(5)
            .toList();
        if (matchingIds.isNotEmpty) {
          try {
            final futureProteins = matchingIds
                .map((id) => _proteinService.fetchProteinById(id))
                .toList();
            searchResults = await Future.wait(futureProteins);
            if (searchResults.isEmpty == false) {
              for (var newProtein in searchResults) {
                if (!_allProteins.any((p) => p.name == newProtein.name)) {
                  _allProteins.add(newProtein);
                }
              }
            }
          } catch (e) {
            print('Failed to fetch some search results: $e');
            _error = 'Error during search. Please try again.';
            searchResults = [];
          }
        }
      }
      _proteins = searchResults;
      if (_proteins.isEmpty) {
        _error = 'No protein found for "$query"';
      }
      _hasMoreData = false; // Disable pagination for search results
    } catch (e) {
      _error = 'Search failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _debounceTimer?.cancel();
    loadProteins();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
