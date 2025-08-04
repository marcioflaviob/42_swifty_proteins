import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthNavigatorObserver extends NavigatorObserver with WidgetsBindingObserver {
  AuthNavigatorObserver() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (navigator == null) {
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(navigator!.context, listen: false);

    if (state == AppLifecycleState.paused) {
      authProvider.logout();
    } else if (state == AppLifecycleState.resumed) {
      if (!authProvider.isAuthenticated) {
        navigator!.pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
