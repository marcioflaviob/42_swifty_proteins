import 'package:flutter/foundation.dart';
import '../models/protein.dart';
import '../services/protein_service.dart';

class ProteinProvider with ChangeNotifier {
  final ProteinService _proteinService = ProteinService();
  
  List<Protein> _proteins = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';

  // Getters
  List<Protein> get proteins => _proteins;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  // Load all proteins
  Future<void> loadProteins() async {
    _setLoading(true);
    _errorMessage = '';
    
    try {
      _proteins = await _proteinService.fetchProteins();
    } catch (error) {
      _errorMessage = 'Failed to load proteins: $error';
      _proteins = [];
    } finally {
      _setLoading(false);
    }
  }

  // Search proteins
  Future<void> searchProteins(String query) async {
    _searchQuery = query;
    _setLoading(true);
    _errorMessage = '';
    
    try {
      _proteins = await _proteinService.searchProteins(query);
    } catch (error) {
      _errorMessage = 'Failed to search proteins: $error';
      _proteins = [];
    } finally {
      _setLoading(false);
    }
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    loadProteins();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
