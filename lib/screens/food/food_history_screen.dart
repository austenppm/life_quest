import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../models/food_entry.dart';
import '../../providers/food_provider.dart';

class FoodHistoryScreen extends ConsumerStatefulWidget {
  final MealType targetMealType;
  final DateTime targetDate;

  const FoodHistoryScreen({
    super.key,
    required this.targetMealType,
    required this.targetDate,
  });

  @override
  ConsumerState<FoodHistoryScreen> createState() => _FoodHistoryScreenState();
}

class _FoodHistoryScreenState extends ConsumerState<FoodHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Add'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recent'),
            Tab(text: 'Frequent'),
            Tab(text: 'Favorites'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search foods...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RecentFoodsTab(
                  searchQuery: _searchQuery,
                  onSelect: _addFood,
                  onToggleFavorite: _toggleFavorite,
                ),
                _FrequentFoodsTab(
                  searchQuery: _searchQuery,
                  onSelect: _addFood,
                  onToggleFavorite: _toggleFavorite,
                ),
                _FavoriteFoodsTab(
                  searchQuery: _searchQuery,
                  onSelect: _addFood,
                  onToggleFavorite: _toggleFavorite,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addFood(FoodEntry food) {
    ref.read(foodNotifierProvider.notifier).copyFoodEntry(
      food,
      targetDate: widget.targetDate,
      targetMealType: widget.targetMealType,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${food.name} added to ${widget.targetMealType.displayName}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _toggleFavorite(String foodName) {
    ref.read(favoriteFoodsNotifierProvider.notifier).toggleFavorite(foodName);
  }
}

class _RecentFoodsTab extends ConsumerWidget {
  final String searchQuery;
  final Function(FoodEntry) onSelect;
  final Function(String) onToggleFavorite;

  const _RecentFoodsTab({
    required this.searchQuery,
    required this.onSelect,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentFoods = ref.watch(recentFoodsProvider);
    final favorites = ref.watch(favoriteFoodsNotifierProvider);

    final filteredFoods = searchQuery.isEmpty
        ? recentFoods
        : recentFoods.where((f) =>
            f.name.toLowerCase().contains(searchQuery.toLowerCase())
          ).toList();

    if (filteredFoods.isEmpty) {
      return _EmptyState(
        icon: Icons.history,
        message: searchQuery.isEmpty
            ? 'No recent foods yet'
            : 'No foods match your search',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredFoods.length,
      itemBuilder: (context, index) {
        final food = filteredFoods[index];
        final isFavorite = favorites.contains(food.name.toLowerCase().trim());
        return _FoodHistoryTile(
          food: food,
          isFavorite: isFavorite,
          onTap: () => onSelect(food),
          onFavorite: () => onToggleFavorite(food.name),
        );
      },
    );
  }
}

class _FrequentFoodsTab extends ConsumerWidget {
  final String searchQuery;
  final Function(FoodEntry) onSelect;
  final Function(String) onToggleFavorite;

  const _FrequentFoodsTab({
    required this.searchQuery,
    required this.onSelect,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frequentFoods = ref.watch(frequentFoodsProvider);
    final favorites = ref.watch(favoriteFoodsNotifierProvider);

    final filteredFoods = searchQuery.isEmpty
        ? frequentFoods
        : frequentFoods.where((f) =>
            f.key.contains(searchQuery.toLowerCase())
          ).toList();

    if (filteredFoods.isEmpty) {
      return _EmptyState(
        icon: Icons.repeat,
        message: searchQuery.isEmpty
            ? 'No frequent foods yet'
            : 'No foods match your search',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredFoods.length,
      itemBuilder: (context, index) {
        final entry = filteredFoods[index];
        final food = entry.value.first; // Most recent entry with this name
        final count = entry.value.length;
        final isFavorite = favorites.contains(food.name.toLowerCase().trim());

        return _FoodHistoryTile(
          food: food,
          isFavorite: isFavorite,
          subtitle: 'Logged $count time${count > 1 ? 's' : ''}',
          onTap: () => onSelect(food),
          onFavorite: () => onToggleFavorite(food.name),
        );
      },
    );
  }
}

class _FavoriteFoodsTab extends ConsumerWidget {
  final String searchQuery;
  final Function(FoodEntry) onSelect;
  final Function(String) onToggleFavorite;

  const _FavoriteFoodsTab({
    required this.searchQuery,
    required this.onSelect,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteFoods = ref.watch(favoriteFoodEntriesProvider);

    final filteredFoods = searchQuery.isEmpty
        ? favoriteFoods
        : favoriteFoods.where((f) =>
            f.name.toLowerCase().contains(searchQuery.toLowerCase())
          ).toList();

    if (filteredFoods.isEmpty) {
      return _EmptyState(
        icon: Icons.favorite_border,
        message: searchQuery.isEmpty
            ? 'No favorite foods yet\nTap the heart icon on any food to add it'
            : 'No favorites match your search',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredFoods.length,
      itemBuilder: (context, index) {
        final food = filteredFoods[index];
        return _FoodHistoryTile(
          food: food,
          isFavorite: true,
          onTap: () => onSelect(food),
          onFavorite: () => onToggleFavorite(food.name),
        );
      },
    );
  }
}

class _FoodHistoryTile extends StatelessWidget {
  final FoodEntry food;
  final bool isFavorite;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _FoodHistoryTile({
    required this.food,
    required this.isFavorite,
    this.subtitle,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Food icon based on meal type
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: food.mealType.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    food.mealType.icon,
                    color: food.mealType.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Food details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle ?? '${food.formattedServingSize} • ${food.calories} cal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Macros
                      Row(
                        children: [
                          _MacroBadge(
                            label: 'P',
                            value: food.protein.toStringAsFixed(0),
                            color: AppColors.protein,
                          ),
                          const SizedBox(width: 6),
                          _MacroBadge(
                            label: 'C',
                            value: food.carbs.toStringAsFixed(0),
                            color: AppColors.carbs,
                          ),
                          const SizedBox(width: 6),
                          _MacroBadge(
                            label: 'F',
                            value: food.fat.toStringAsFixed(0),
                            color: AppColors.fat,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Favorite button
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : AppColors.textMuted,
                  ),
                  onPressed: onFavorite,
                ),
                // Add button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: ${value}g',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
