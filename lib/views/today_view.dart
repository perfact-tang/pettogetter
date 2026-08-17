import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/models.dart';
import '../store/care_store.dart';
import '../theme/app_theme.dart';
import 'add_task_view.dart';
import 'profile_edit_view.dart';
import 'widgets/common.dart';
import 'widgets/task_card.dart';

class TodayView extends StatelessWidget {
  const TodayView({super.key});

  Future<void> _pickPhoto(BuildContext context, CareStore store) async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      await store.savePetPhoto(bytes);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't use that photo")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CareStore>();
    final language = context.watch<AppLanguageStore>().language;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(L10n.text(language, 'Today', '今日')),
        actions: [
          PopupMenuButton<AppLanguage>(
            icon: const Icon(Icons.language, color: PawColors.purple),
            onSelected: (value) =>
                context.read<AppLanguageStore>().language = value,
            itemBuilder: (context) => [
              for (final item in AppLanguage.values)
                PopupMenuItem(
                  value: item,
                  child: Row(
                    children: [
                      if (language == item) ...[
                        const Icon(Icons.check, size: 18),
                        const SizedBox(width: 6),
                      ],
                      Text(item.label),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const AddTaskView(),
              ),
            ),
            icon: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: PawColors.purple,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 20, color: Colors.white),
            ),
          ),
        ],
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
                    _greetingHeader(context, store, language),
                    const SizedBox(height: 20),
                    _petHeroCard(context, store, language),
                    const SizedBox(height: 20),
                    _section(
                      title: L10n.text(language, 'Needs a person', '担当が必要'),
                      detail: store.unclaimedTasks.isEmpty
                          ? L10n.text(language, 'CLEAR', 'なし')
                          : '${store.unclaimedTasks.length} ${L10n.text(language, 'UNCLAIMED', '未担当')}',
                      child: store.unclaimedTasks.isEmpty
                          ? _emptyState(context, language)
                          : Column(
                              children: [
                                for (final task in store.unclaimedTasks)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: TaskCard(task: task),
                                  ),
                              ],
                            ),
                    ),
                    if (store.claimedTasks.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _section(
                        title: L10n.text(language, 'In progress', '進行中'),
                        detail:
                            '${store.claimedTasks.length} ${L10n.text(language, 'CLAIMED', '担当者あり')}',
                        child: Column(
                          children: [
                            for (final task in store.claimedTasks)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TaskCard(task: task),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (store.completedTasks.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _section(
                        title: L10n.text(language, 'Done today', '今日の完了'),
                        detail: L10n.text(language, 'SHARED CARE', 'みんなのケア'),
                        child: Column(
                          children: [
                            for (final task in store.completedTasks.take(3))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TaskCard(task: task),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _categories(context, language),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _greetingHeader(
      BuildContext context, CareStore store, AppLanguage language) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${store.currentCaregiver?.displayName ?? 'pet parent'}',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: PawColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                L10n.text(language, 'Let’s make today a happy one.', '今日もいい一日に。'),
                style: const TextStyle(fontSize: 14, color: PawColors.muted),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const ProfileEditView(),
            ),
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            fixedSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          icon: const Icon(Icons.person, color: PawColors.purple),
        ),
      ],
    );
  }

  Widget _petHeroCard(
      BuildContext context, CareStore store, AppLanguage language) {
    final remaining = store.unclaimedTasks.length + store.claimedTasks.length;
    final summary = remaining == 0
        ? L10n.text(language, 'Everything is handled. Time for cuddles.',
            '全部おわり。なでなでの時間。')
        : '$remaining ${L10n.text(language, 'care moments left for today.', '件のケアが残っています。')}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PawColors.lavender,
            PawColors.peach.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: PawColors.purpleDark.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                    const Icon(Icons.auto_awesome,
                        size: 14, color: PawColors.purple),
                    const SizedBox(width: 5),
                    Text(
                      L10n.text(language, 'CARE PULSE', 'ケアパルス'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: PawColors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  store.household?.petName ?? L10n.text(language, 'Your pet', 'あなたのペット'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: PawColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  summary,
                  style: const TextStyle(fontSize: 13, color: PawColors.muted),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.home, size: 15, color: PawColors.purpleDark),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        store.household?.name ??
                            L10n.text(language, 'Your household', 'あなたの家族'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PawColors.purpleDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _pickPhoto(context, store),
            borderRadius: BorderRadius.circular(21),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: SizedBox(
                    width: 138,
                    height: 156,
                    child: PetPhotoView(data: store.petPhotoData),
                  ),
                ),
                Positioned(
                  bottom: -5,
                  right: -5,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: PawColors.purple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.photo_camera,
                        size: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required String? detail,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PetSectionTitle(title: title, detail: detail),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _emptyState(BuildContext context, AppLanguage language) {
    return PetCard(
      child: Column(
        children: [
          const CareIcon(icon: Icons.check, color: PawColors.green, size: 56),
          const SizedBox(height: 10),
          Text(
            L10n.text(language, 'Everything is handled', '全部おわり'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: PawColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            L10n.text(language, 'Add another task when your pet needs care.',
                'ケアが必要になったらタスクを追加しましょう。'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: PawColors.muted),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const AddTaskView(),
              ),
            ),
            child: Text(L10n.text(language, 'Add a task', 'タスクを追加')),
          ),
        ],
      ),
    );
  }

  Widget _categories(BuildContext context, AppLanguage language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PetSectionTitle(
          title: L10n.text(language, 'Daily care', '毎日のケア'),
          detail: L10n.text(language, 'AT A GLANCE', 'ひと目で'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _categoryTile(CareCategory.feeding,
                L10n.text(language, 'Meals', 'ごはん')),
            const SizedBox(width: 10),
            _categoryTile(CareCategory.walking,
                L10n.text(language, 'Walks', '散歩')),
            const SizedBox(width: 10),
            _categoryTile(CareCategory.medication,
                L10n.text(language, 'Meds', 'お薬')),
            const SizedBox(width: 10),
            _categoryTile(CareCategory.grooming,
                L10n.text(language, 'Groom', 'お手入れ')),
          ],
        ),
      ],
    );
  }

  Widget _categoryTile(CareCategory category, String shortTitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: PawColors.purpleDark.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            CareIcon(
              icon: categoryIcon(category),
              color: categoryAccent(category),
              size: 42,
            ),
            const SizedBox(height: 8),
            Text(
              shortTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: PawColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
