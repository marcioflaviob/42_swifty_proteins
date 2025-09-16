import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/protein_provider.dart';
import '../screens/protein_detail_screen.dart';
import '../screens/login_screen.dart';
import '../models/protein.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  StreamSubscription? _linkSubscription;
  BuildContext? _context;
  String? _pendingProteinId;

  // Initialize deep link handling
  void initialize(BuildContext context) {
    _context = context;
    _handleInitialLink();
    _handleIncomingLinks();
  }

  // Handle the initial link when app is opened from a link
  Future<void> _handleInitialLink() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _processLink(initialLink);
      }
    } catch (e) {
      debugPrint('Failed to get initial link: $e');
    }
  }

  // Handle incoming links when app is already running
  void _handleIncomingLinks() {
    _linkSubscription = linkStream.listen(
      (String? link) {
        if (link != null) {
          _processLink(link);
        }
      },
      onError: (err) {
        debugPrint('Failed to handle incoming link: $err');
      },
    );
  }

  // Process the deep link
  void _processLink(String link) {
    final uri = Uri.parse(link);
    
    // Check if it's a protein link: swiftyproteins://protein/[protein_id]
    if (uri.scheme == 'swiftyproteins' && uri.host == 'protein' && uri.pathSegments.isNotEmpty) {
      final proteinId = uri.pathSegments.first;
      _handleProteinLink(proteinId);
    }
  }

  // Handle protein-specific links
  Future<void> _handleProteinLink(String proteinId) async {
    if (_context == null) return;

    final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
    
    // If user is not authenticated, store the protein ID and navigate to login
    if (!authProvider.isAuthenticated) {
      _pendingProteinId = proteinId;
      Navigator.of(_context!).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    // User is authenticated, navigate to protein detail
    await _navigateToProtein(proteinId);
  }

  // Navigate to protein detail screen
  Future<void> _navigateToProtein(String proteinId) async {
    if (_context == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: _context!,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final proteinProvider = Provider.of<ProteinProvider>(_context!, listen: false);
      
      // Try to find the protein in the already loaded proteins
      Protein? protein = proteinProvider.proteins
          .where((p) => p.name.toLowerCase() == proteinId.toLowerCase())
          .firstOrNull;

      // If not found, try to fetch it
      if (protein == null) {
        try {
          protein = await proteinProvider.searchForSpecificProtein(proteinId);
        } catch (e) {
          // If fetch fails, show error
          Navigator.of(_context!).pop(); // Close loading dialog
          ScaffoldMessenger.of(_context!).showSnackBar(
            SnackBar(
              content: Text('Protein "$proteinId" not found'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Close loading dialog
      Navigator.of(_context!).pop();

      if (protein != null) {
        // Navigate to protein detail screen
        Navigator.of(_context!).push(
          MaterialPageRoute(
            builder: (context) => ProteinDetailScreen(protein: protein!),
          ),
        );
      } else {
        // Show error if protein is still null
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text('Protein "$proteinId" not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(_context!).canPop()) {
        Navigator.of(_context!).pop();
      }
      
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text('Error loading protein: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Check if there's a pending protein to navigate to after login
  Future<void> checkPendingNavigation() async {
    if (_pendingProteinId != null) {
      final proteinId = _pendingProteinId!;
      _pendingProteinId = null;
      
      // Small delay to ensure the UI is ready
      await Future.delayed(const Duration(milliseconds: 500));
      await _navigateToProtein(proteinId);
    }
  }

  // Generate a shareable link for a protein
  String generateProteinLink(String proteinId) {
    return 'swiftyproteins://protein/$proteinId';
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
