import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/protein_provider.dart';
import 'screens/protein_list_screen.dart';

void main() {
  runApp(const SwiftyProteinsApp());
}

class SwiftyProteinsApp extends StatelessWidget {
  const SwiftyProteinsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProteinProvider(),
      child: MaterialApp(
        title: 'Swifty Proteins',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swifty Proteins'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Swifty Proteins!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your app skeleton is ready.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProteinListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.science),
              label: const Text('Explore Proteins'),
            ),
          ],
        ),
      ),
    );
  }
}
