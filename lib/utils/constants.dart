import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'Swifty Proteins';
  static const String appVersion = '1.0.0';
  
  // Colors
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Colors.blueAccent;
  
  // Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Border Radius
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  
  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  
  // Text Styles
  static const TextStyle headlineStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  
  // API URLs (for future use)
  static const String baseUrl = 'https://api.example.com';
  static const String proteinsEndpoint = '/proteins';
}

class AppStrings {
  // Home Screen
  static const String welcomeTitle = 'Welcome to Swifty Proteins!';
  static const String welcomeSubtitle = 'Your app skeleton is ready.';
  static const String exploreProteins = 'Explore Proteins';
  
  // Protein List Screen
  static const String proteinDatabase = 'Protein Database';
  static const String searchProteins = 'Search proteins...';
  static const String noProteinsFound = 'No proteins found';
  static const String tryAdjustingSearch = 'Try adjusting your search';
  static const String pullToRefresh = 'Pull to refresh or check your connection';
  
  // Protein Detail Screen
  static const String description = 'Description';
  static const String properties = 'Properties';
  static const String actions = 'Actions';
  static const String atomCount = 'Atom Count';
  static const String molecularFormula = 'Molecular Formula';
  static const String view3D = 'View 3D';
  static const String download = 'Download';
  
  // Common
  static const String retry = 'Retry';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  
  // Coming Soon Messages
  static const String shareFunctionalityComingSoon = 'Share functionality coming soon!';
  static const String visualization3DComingSoon = '3D visualization coming soon!';
  static const String downloadFeatureComingSoon = 'Download feature coming soon!';
}
