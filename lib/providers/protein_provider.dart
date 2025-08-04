import 'package:flutter/material.dart';
import '../models/protein.dart';
import '../services/protein_service.dart';
import 'package:flutter/services.dart'; // Add this import

class ProteinProvider with ChangeNotifier {
  final ProteinService _proteinService = ProteinService();

  List<Protein> _proteins = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _error = '';
  String _searchQuery = '';

  // Pagination properties
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  bool _hasMoreData = true;
  List<String> _allLigandIds = [];

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
    List<Protein> pageProteins = [];
    for (String ligandId in pageIds) {
      try {
        final protein = await _proteinService.fetchProteinById(ligandId);
        pageProteins.add(protein);

        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('Failed to fetch protein for $ligandId: $e');
        // Add placeholder protein
        pageProteins.add(
          Protein(
            name: ligandId,
            formula: 'Unknown',
            complete_name: 'Protein data could not be retrieved',
            atomCount: 0,
          ),
        );
      }
    }

    // Add new proteins to the list
    _proteins.addAll(pageProteins);
    _currentPage++;

    // Check if we've reached the end
    if (endIndex >= _allLigandIds.length) {
      _hasMoreData = false;
    }
  }

  // Search proteins
  Future<void> searchProteins(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      // If search is cleared, reload from beginning
      await loadProteins();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // For search, we'll search through already loaded proteins
      // and also search the mock data
      final searchResults = await _proteinService.searchProteins(query);
      _proteins = searchResults;
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
    loadProteins();
  }
}
