import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/models.dart';
import '../store/care_store.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';

class ActivityView extends StatelessWidget {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CareStore>();
    final language = context.watch<AppLanguageStore>().language;

    final completed = store.tasks
        .where((t) => t.status == CareTaskStatus.completed)
        .toList()
      ..sort((a, b) =>
          (b.completedAt ?? b.dueTime).compareTo(a.completedAt ?? a.dueTime));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title:
            Text(L10n.text(language, 'Activity', 'アクティビティ', '活动', '활동')),
      ),
      body: Stack(
        children: [
          const PetScreenBackground(),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _summary(context, store, language),
                    const SizedBox(height: 18),
                    if (completed.isEmpty)
                      _emptyState(context, language)
                    else ...[
                      PetSectionTitle(
                        title: L10n.text(
                            language, 'Care history', 'ケア履歴', '护理记录', '케어 기록'),
                        detail:
                            '${completed.length} ${L10n.text(language, 'COMPLETED', '完了', '已完成', '완료')}',
                      ),
                      const SizedBox(height: 14),
                      for (final task in completed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _activityCard(context, task, language),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(
      BuildContext context, CareStore store, AppLanguage language) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PawColors.peach.withValues(alpha: 0.8),
            PawColors.lavender,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: PawColors.purpleDark.withValues(alpha: 0.11),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite,
                        size: 14, color: PawColors.purple),
                    const SizedBox(width: 5),
                    Text(
                      L10n.text(language, 'SHARED CARE', 'みんなのケア',
                          '共同照护', '함께하는 케어'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: PawColors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  L10n.text(language, 'Every handoff,\nin one place.',
                      'すべての引き継ぎを\nひとつに。', '每次交接，\n都在一处。',
                      '모든 인수인계를\n한곳에.'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: PawColors.ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  L10n.text(
                    language,
                    'See who cared for ${store.household?.petName ?? 'your pet'} and when.',
                    '${store.household?.petName ?? 'ペット'}のケアを誰がいつ行ったか確認できます。',
                    '查看谁在何时照顾了${store.household?.petName ?? '你的宠物'}。',
                    '${store.household?.petName ?? '반려동물'}의 케어를 누가 언제 했는지 확인할 수 있습니다.',
                  ),
                  style: const TextStyle(fontSize: 12, color: PawColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/copaw_pets.png',
              width: 124,
              height: 138,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityCard(
      BuildContext context, CareTask task, AppLanguage language) {
    return PetCard(
      padding: 15,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CareIcon(
            icon: categoryIcon(task.category),
            color: categoryAccent(task.category),
            size: 50,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: PawColors.ink,
                        ),
                      ),
                    ),
                    const Icon(Icons.check_circle,
                        size: 18, color: PawColors.green),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  L10n.categoryTitle(language, task.category).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: categoryAccent(task.category),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person,
                        size: 15, color: PawColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      L10n.text(
                        language,
                        'Completed by ${task.completedBy ?? 'A caregiver'}',
                        '${task.completedBy ?? '担当者'}さんが完了',
                        '${task.completedBy ?? '家人'}已完成',
                        '${task.completedBy ?? '가족'}님이 완료',
                      ),
                      style: const TextStyle(
                          fontSize: 13, color: PawColors.muted),
                    ),
                  ],
                ),
                if (task.completedAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 13, color: PawColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat.yMMMd(language.rawValue)
                            .add_jm()
                            .format(task.completedAt!),
                        style: const TextStyle(
                            fontSize: 12, color: PawColors.muted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, AppLanguage language) {
    return PetCard(
      padding: 28,
      child: Column(
        children: [
          const CareIcon(icon: Icons.history, color: PawColors.purple, size: 62),
          const SizedBox(height: 12),
          Text(
            L10n.text(language, 'No activity yet', 'まだアクティビティがありません',
                '暂无活动', '아직 활동이 없습니다'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: PawColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            L10n.text(
              language,
              'Completed care tasks will appear here for the whole household.',
              '完了したケアが家族全員にここで表示されます。',
              '已完成的护理任务会在这里对全家人显示。',
              '완료된 케어가 가족 모두에게 여기에 표시됩니다.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: PawColors.muted),
          ),
        ],
      ),
    );
  }
}
