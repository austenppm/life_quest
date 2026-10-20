import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:life_quest/theme/app_theme.dart';
import 'package:life_quest/providers/user_provider.dart';
import 'package:life_quest/widgets/xp_bar.dart';
import 'package:life_quest/screens/dashboard/dashboard_content.dart';

export 'package:life_quest/screens/dashboard/dashboard_content.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  double _dragStartX = 0;

  final _navItems = const [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', path: '/home'),
    _NavItem(icon: Icons.task_outlined, activeIcon: Icons.task, label: 'Tasks', path: '/tasks'),
    _NavItem(icon: Icons.restaurant_outlined, activeIcon: Icons.restaurant, label: 'Food', path: '/food'),
    _NavItem(icon: Icons.fitness_center_outlined, activeIcon: Icons.fitness_center, label: 'Exercise', path: '/exercise'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Money', path: '/money'),
  ];

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
  }

  void _handleHorizontalDragEnd(DragEndDetails details, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final edgeThreshold = screenWidth * 0.15; // 15% from edges
    final velocity = details.primaryVelocity ?? 0;

    // Only handle edge swipes here (center swipes handled by individual screens)
    final isFromLeftEdge = _dragStartX < edgeThreshold;
    final isFromRightEdge = _dragStartX > screenWidth - edgeThreshold;

    if (!isFromLeftEdge && !isFromRightEdge) return;

    if (velocity.abs() > 300) {
      if (velocity > 0 && _selectedIndex > 0) {
        // Swipe right from edge -> previous tab
        context.go(_navItems[_selectedIndex - 1].path);
      } else if (velocity < 0 && _selectedIndex < _navItems.length - 1) {
        // Swipe left from edge -> next tab
        context.go(_navItems[_selectedIndex + 1].path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;

    // Update selected index based on current route
    final location = GoRouterState.of(context).matchedLocation;
    _selectedIndex = _navItems.indexWhere((item) => location.startsWith(item.path));
    if (_selectedIndex < 0) _selectedIndex = 0;

    return GestureDetector(
      onHorizontalDragStart: _handleHorizontalDragStart,
      onHorizontalDragEnd: (details) => _handleHorizontalDragEnd(details, context),
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: profile != null
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: AppColors.accent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Lv.${profile.level}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: XPBar(
                      currentXP: profile.totalXP,
                      maxXP: profile.xpToNextLevel,
                      height: 8,
                    ),
                  ),
                ],
              )
            : const Text('Life Quest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'AI Assistant',
            onPressed: () => context.push('/assistant'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 48,
                              color: AppColors.textMuted.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No new notifications',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = _selectedIndex == index;

                return _NavBarItem(
                  icon: isSelected ? item.activeIcon : item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () {
                    context.go(item.path);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
