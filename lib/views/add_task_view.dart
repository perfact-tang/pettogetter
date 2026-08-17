import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/models.dart';
import '../store/care_store.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';

class AddTaskView extends StatefulWidget {
  const AddTaskView({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<AddTaskView> createState() => _AddTaskViewState();
}

class _AddTaskViewState extends State<AddTaskView> {
  late DateTime _dueDate;
  final _title = TextEditingController();
  CareCategory _category = CareCategory.feeding;
  CareTaskKind _kind = CareTaskKind.oneOff;
  CarePriority _priority = CarePriority.normal;
  final List<int> _weekdays = [1, 2, 3, 4, 5, 6, 7];

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate ?? DateTime.now();
    _dueDate = DateTime(base.year, base.month, base.day,
        DateTime.now().hour, DateTime.now().minute);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  CareRoutineFrequency get _routineFrequency =>
      _kind == CareTaskKind.routine && _weekdays.length < 7
          ? CareRoutineFrequency.selectedDays
          : CareRoutineFrequency.daily;

  bool get _canSave => _title.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CareStore>();
    final language = context.watch<AppLanguageStore>().language;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(L10n.text(language, 'Add Task', 'ケアを追加')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: (!_canSave || store.isSavingTask)
                ? null
                : () => _save(store),
            child: store.isSavingTask
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    L10n.text(language, 'Save', '保存'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const PetScreenBackground(),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        const CareIcon(
                            icon: Icons.add, color: PawColors.purple, size: 58),
                        const SizedBox(height: 8),
                        Text(
                          L10n.text(language, 'A new care moment', '新しいケア'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: PawColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          language == AppLanguage.japanese
                              ? '${store.household?.petName ?? 'ペット'}に必要なことを追加しましょう。'
                              : 'Add one clear task so everyone knows what ${store.household?.petName ?? 'your pet'} needs.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: PawColors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PetCard(
                      padding: 14,
                      child: Row(
                        children: [
                          const CareIcon(
                              icon: Icons.calendar_today,
                              color: PawColors.purple,
                              size: 46),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  L10n.text(
                                      language, 'Scheduled for', '予定日'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: PawColors.muted,
                                  ),
                                ),
                                Text(
                                  _scheduledDateText(language),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: PawColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PetCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel(
                            L10n.text(language, 'Frequency', '頻度'),
                            Icons.repeat,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _typeButton(
                                  CareTaskKind.oneOff,
                                  L10n.text(language, 'One-time', '一回のみ'),
                                  L10n.text(
                                      language, 'A dated need', '指定日のケア'),
                                  Icons.add_circle_outline,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _typeButton(
                                  CareTaskKind.routine,
                                  L10n.text(language, 'Routine', '繰り返し'),
                                  L10n.text(language, 'Choose days', '曜日を指定'),
                                  Icons.repeat,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _kind == CareTaskKind.routine
                                ? L10n.text(language,
                                    'Choose the days and time this repeats.',
                                    '繰り返す曜日と時間を選びます。')
                                : L10n.text(language,
                                    'This will appear only on the date you choose.',
                                    '選んだ日に一度だけ表示されます。'),
                            style: const TextStyle(
                                fontSize: 12, color: PawColors.muted),
                          ),
                          if (_kind == CareTaskKind.routine) ...[
                            const SizedBox(height: 12),
                            Text(
                              L10n.text(language, 'Repeats on', '繰り返す曜日'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: PawColors.purpleDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (final day in _weekdayOptions(language))
                                  _weekdayChip(day.$1, day.$2),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PetCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel(
                            L10n.text(language, 'Care category', 'カテゴリー'),
                            Icons.grid_view,
                          ),
                          const SizedBox(height: 13),
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.25,
                            children: [
                              for (final category in CareCategory.values)
                                _categoryButton(category, language),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PetCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel(
                            L10n.text(
                                language, 'What needs to be done?', '具体的な名前'),
                            Icons.checklist,
                          ),
                          const SizedBox(height: 9),
                          TextField(
                            controller: _title,
                            decoration: petFieldDecoration(
                              hintText: L10n.text(
                                  language, 'For example: Morning meal', '例：朝ごはん'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PetCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel(
                            _kind == CareTaskKind.routine
                                ? L10n.text(
                                    language, 'Start date and time', '開始日と時間')
                                : L10n.text(language, 'Date and time', '日時'),
                            Icons.schedule,
                          ),
                          const SizedBox(height: 12),
                          _pickerTile(
                            icon: Icons.calendar_today,
                            label: _kind == CareTaskKind.routine
                                ? L10n.text(language, 'Starts', '開始')
                                : L10n.text(language, 'Date', '日付'),
                            value: DateFormat.yMMMd(language.rawValue)
                                .format(_dueDate),
                            onTap: _pickDate,
                          ),
                          const SizedBox(height: 10),
                          _pickerTile(
                            icon: Icons.schedule,
                            label: L10n.text(language, 'Time', '時間'),
                            value: DateFormat.jm(language.rawValue)
                                .format(_dueDate),
                            onTap: _pickTime,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PetCard(
                      padding: 15,
                      child: Row(
                        children: [
                          const CareIcon(
                              icon: Icons.error,
                              color: PawColors.rose,
                              size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  L10n.text(language, 'Urgent care', '緊急ケア'),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: PawColors.ink,
                                  ),
                                ),
                                Text(
                                  L10n.text(
                                    language,
                                    'Make this stand out for both caregivers.',
                                    '家族全員に目立つようにします。',
                                  ),
                                  style: const TextStyle(
                                      fontSize: 12, color: PawColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _priority == CarePriority.urgent,
                            activeThumbColor: PawColors.rose,
                            onChanged: (value) => setState(() => _priority =
                                value ? CarePriority.urgent : CarePriority.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateTime(picked.year, picked.month, picked.day,
            _dueDate.hour, _dueDate.minute);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _dueDate.hour, minute: _dueDate.minute),
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateTime(_dueDate.year, _dueDate.month, _dueDate.day,
            picked.hour, picked.minute);
      });
    }
  }

  Future<void> _save(CareStore store) async {
    final saved = await store.addTask(
      title: _title.text.trim(),
      category: _category,
      kind: _kind,
      priority: _priority,
      date: _dueDate,
      frequency: _routineFrequency,
      weekdays: _weekdays,
    );
    if (saved && mounted) Navigator.of(context).pop();
  }

  Widget _typeButton(
      CareTaskKind kind, String title, String detail, IconData icon) {
    final selected = _kind == kind;
    return InkWell(
      onTap: () => setState(() => _kind = kind),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        height: 92,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? PawColors.lavender : PawColors.cream,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? PawColors.purple : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: selected ? PawColors.purple : PawColors.ink),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: selected ? PawColors.purple : PawColors.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: TextStyle(
                fontSize: 11,
                color: selected ? PawColors.purpleDark : PawColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekdayChip(int value, String label) {
    final selected = _weekdays.contains(value);
    return InkWell(
      onTap: () => setState(() {
        if (selected && _weekdays.length > 1) {
          _weekdays.remove(value);
        } else if (!selected) {
          _weekdays.add(value);
        }
      }),
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? PawColors.purple : PawColors.lavender,
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : PawColors.purple,
          ),
        ),
      ),
    );
  }

  Widget _categoryButton(CareCategory category, AppLanguage language) {
    final selected = _category == category;
    final color = categoryAccent(category);
    return InkWell(
      onTap: () => setState(() => _category = category),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.13) : PawColors.cream,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CareIcon(icon: categoryIcon(category), color: color, size: 42),
            const SizedBox(height: 6),
            Text(
              L10n.categoryTitle(language, category),
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

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: PawColors.lavender.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: PawColors.purple),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: PawColors.ink),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: PawColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: PawColors.purpleDark),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: PawColors.purpleDark,
          ),
        ),
      ],
    );
  }

  String _scheduledDateText(AppLanguage language) {
    return language == AppLanguage.japanese
        ? DateFormat('M月d日 (E)', 'ja').format(_dueDate)
        : DateFormat('EEEE, MMM d', 'en').format(_dueDate);
  }

  List<(int, String)> _weekdayOptions(AppLanguage language) {
    return language == AppLanguage.japanese
        ? const [(1, '日'), (2, '月'), (3, '火'), (4, '水'), (5, '木'), (6, '金'), (7, '土')]
        : const [(1, 'S'), (2, 'M'), (3, 'T'), (4, 'W'), (5, 'T'), (6, 'F'), (7, 'S')];
  }
}
