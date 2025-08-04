import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/protein_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/protein_list_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const SwiftyProteinsApp());
}

class SwiftyProteinsApp extends StatelessWidget {
  const SwiftyProteinsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ProteinProvider()),
      ],
      child: MaterialApp(
        title: 'Swifty Proteins',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return authProvider.isAuthenticated 
                  ? const ProteinListScreen() 
                  : const LoginScreen();
            },
          ),
          '/login': (context) => const LoginScreen(),
          '/proteins': (context) => const ProteinListScreen(),
        },
      ),
    );
  }
}