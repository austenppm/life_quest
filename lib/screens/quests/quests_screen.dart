import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../providers/quest_provider.dart';
import '../../widgets/quest_card.dart';
import 'quest_form_dialog.dart';

class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeQuests = ref.watch(activeQuestsProvider);
    final completedQuests = ref.watch(completedQuestsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Quests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildQuestList(context, activeQuests, 'active'),
            _buildQuestList(context, completedQuests, 'completed'),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateQuestDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('New Quest'),
        ),
      ),
    );
  }

  Widget _buildQuestList(BuildContext context, List quests, String type) {
    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 64,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No $type quests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            if (type == 'active') ...[
              const SizedBox(height: 8),
              Text(
                'Create your first quest to begin your adventure!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: quests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final quest = quests[index];
        return QuestCard(
          quest: quest,
          onTap: () => context.push('/quests/${quest.id}'),
        );
      },
    );
  }

  void _showCreateQuestDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuestFormDialog(),
    );
  }
}
