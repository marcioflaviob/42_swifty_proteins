import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/protein_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/protein_card.dart';
import 'login_screen.dart';
import 'protein_detail_screen.dart';

class ProteinListScreen extends StatefulWidget {
  const ProteinListScreen({super.key});

  @override
  State<ProteinListScreen> createState() => _ProteinListScreenState();
}

class _ProteinListScreenState extends State<ProteinListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProteinProvider>().loadProteins();
    });

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if user has scrolled to near the bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<ProteinProvider>();

      // Load more data if available and not currently loading
      if (provider.hasMoreData &&
          !provider.isLoadingMore &&
          provider.searchQuery.isEmpty) {
        provider.loadMoreProteins();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Logged in as ${context.watch<AuthProvider>().currentUser?.username ?? 'Guest'}',
          ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // Clear authentication state but keep biometric data for next login
              context.read<AuthProvider>().logout();
              // Navigate to login with proper animation
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(-1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.ease;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search proteins...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ProteinProvider>().clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {}); // Update UI to show/hide clear button
                // Debounce search to avoid too many API calls
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    context.read<ProteinProvider>().searchProteins(value);
                  }
                });
              },
            ),
          ),

          // Protein List
          Expanded(
            child: Consumer<ProteinProvider>(
              builder: (context, proteinProvider, child) {
                if (proteinProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (proteinProvider.errorMessage.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          proteinProvider.errorMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            proteinProvider.loadProteins();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (proteinProvider.proteins.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No proteins found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          proteinProvider.searchQuery.isNotEmpty
                              ? 'Try adjusting your search'
                              : 'Pull to refresh or check your connection',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: proteinProvider.loadProteins,
                  child: ListView.builder(
                    itemCount:
                        proteinProvider.proteins.length +
                        (proteinProvider.hasMoreData &&
                                proteinProvider.searchQuery.isEmpty
                            ? 1
                            : 0),
                    itemBuilder: (context, index) {
                      if (index == proteinProvider.proteins.length) {
                        return _buildLoadingIndicator(proteinProvider);
                      }
                      final protein = proteinProvider.proteins[index];
                      return ProteinCard(
                        protein: protein,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProteinDetailScreen(protein: protein),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(ProteinProvider provider) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (provider.hasMoreData && provider.searchQuery.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ElevatedButton(
            onPressed: () => provider.loadMoreProteins(),
            child: const Text('Load More'),
          ),
        ),
      );
    } else {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No more proteins to load',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
  }
}
