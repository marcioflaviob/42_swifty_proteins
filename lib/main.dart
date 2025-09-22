import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/protein_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/protein_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/auth_navigator_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ProteinProvider()),
      ],
      child: const SwiftyProteinsApp(),
    ),
  );
}

class SwiftyProteinsApp extends StatefulWidget {
  const SwiftyProteinsApp({super.key});

  @override
  State<SwiftyProteinsApp> createState() => _SwiftyProteinsAppState();
}

class _SwiftyProteinsAppState extends State<SwiftyProteinsApp> with WidgetsBindingObserver {
  final AuthNavigatorObserver _authNavigatorObserver = AuthNavigatorObserver();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authNavigatorObserver.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.logout();
      
      // Navigate to login screen
      if (_navigatorKey.currentState != null) {
        _navigatorKey.currentState!.pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swifty Proteins',
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/proteins': (context) => const ProteinListScreen(),
      },
    );
  }
}