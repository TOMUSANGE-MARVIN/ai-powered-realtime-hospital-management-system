import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/doctor_providers.dart';
import 'category_card.dart';

/// Dedicated categories browser — just a searchable grid of every
/// specialty. Selecting one opens the search screen pre-filtered to that
/// category (the "doctors in this category" screen).
class AllCategoriesScreen extends ConsumerStatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  ConsumerState<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends ConsumerState<AllCategoriesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesWithCountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search a category',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                final filtered = _query.isEmpty
                    ? categories
                    : categories
                        .where((c) => c.category.name.toLowerCase().contains(_query))
                        .toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No categories match your search'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => CategoryCard(
                    category: filtered[index].category,
                    count: filtered[index].count,
                    width: double.infinity,
                    showCount: true,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ),
        ],
      ),
    );
  }
}
