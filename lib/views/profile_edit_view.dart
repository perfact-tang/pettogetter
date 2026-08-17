import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../store/care_store.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';

class ProfileEditView extends StatefulWidget {
  const ProfileEditView({super.key});

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  late final TextEditingController _caregiverName;
  late final TextEditingController _householdName;
  late final TextEditingController _petName;
  bool _copied = false;
  bool _didLoad = false;

  @override
  void initState() {
    super.initState();
    _caregiverName = TextEditingController();
    _householdName = TextEditingController();
    _petName = TextEditingController();
  }

  @override
  void dispose() {
    _caregiverName.dispose();
    _householdName.dispose();
    _petName.dispose();
    super.dispose();
  }

  void _loadIfNeeded(CareStore store) {
    if (_didLoad) return;
    _caregiverName.text = store.currentCaregiver?.displayName ?? '';
    _householdName.text = store.household?.name ?? '';
    _petName.text = store.household?.petName ?? '';
    _didLoad = true;
  }

  bool get _canSave {
    final caregiver = _caregiverName.text.trim();
    final household = _householdName.text.trim();
    final pet = _petName.text.trim();
    return caregiver.isNotEmpty &&
        caregiver.length <= 50 &&
        household.isNotEmpty &&
        household.length <= 60 &&
        pet.isNotEmpty &&
        pet.length <= 60;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CareStore>();
    _loadIfNeeded(store);

    final language = context.watch<AppLanguageStore>().language;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(L10n.text(language, 'Family profile', '家族プロフィール')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: store.isSavingProfile ? null : () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const PetScreenBackground(),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context),
                    const SizedBox(height: 18),
                    _profileCard(context),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: pawPrimaryButtonStyle(),
                      onPressed: (!_canSave || store.isSavingProfile)
                          ? null
                          : () => _save(store),
                      child: store.isSavingProfile
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(store.isSavingProfile
                                    ? L10n.text(language, 'Saving…', '保存中…')
                                    : L10n.text(
                                        language, 'Save changes', '変更を保存')),
                                if (!store.isSavingProfile) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check, size: 18),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      L10n.text(
                        language,
                        'Changes are shared with everyone in this household.',
                        '変更は家族全員と共有されます。',
                      ),
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 12, color: PawColors.muted),
                    ),
                    const SizedBox(height: 20),
                    _leaveCard(context, store, language),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final initial = _caregiverName.text.trim().isNotEmpty
        ? _caregiverName.text.trim()[0].toUpperCase()
        : '?';
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: PawColors.purple.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: PawColors.purple,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _t(context, 'Keep your family details current', '家族の情報を最新に保ちましょう'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: PawColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _t(context, 'Your name and pet details update across devices.',
              '名前とペット情報はすべての端末に反映されます。'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: PawColors.muted),
        ),
      ],
    );
  }

  Widget _profileCard(BuildContext context) {
    final language = context.watch<AppLanguageStore>().language;
    final store = context.watch<CareStore>();
    final inviteCode = store.household?.inviteCode ?? '';

    return PetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PetSectionTitle(
            title: L10n.text(language, 'About you', 'あなたについて'),
            detail: 'CAREGIVER',
          ),
          const SizedBox(height: 12),
          _fieldLabel(L10n.text(language, 'Your name', 'あなたの名前'), Icons.person),
          const SizedBox(height: 8),
          TextField(
            controller: _caregiverName,
            textCapitalization: TextCapitalization.words,
            decoration: petFieldDecoration(
              hintText: L10n.text(
                  language, 'How should your family see you?', '家族に表示する名前'),
            ),
          ),
          const SizedBox(height: 18),
          PetSectionTitle(
            title: L10n.text(language, 'Home & pet', '家とペット'),
            detail: 'SHARED',
          ),
          const SizedBox(height: 12),
          _fieldLabel(
              L10n.text(language, 'Household name', '家の名前'), Icons.home),
          const SizedBox(height: 8),
          TextField(
            controller: _householdName,
            textCapitalization: TextCapitalization.words,
            decoration: petFieldDecoration(
              hintText: L10n.text(language, 'Household name', '家の名前'),
            ),
          ),
          const SizedBox(height: 12),
          _fieldLabel(L10n.text(language, 'Pet name', 'ペットの名前'), Icons.pets),
          const SizedBox(height: 8),
          TextField(
            controller: _petName,
            textCapitalization: TextCapitalization.words,
            decoration: petFieldDecoration(
              hintText: L10n.text(language, 'Pet name', 'ペットの名前'),
            ),
          ),
          if (inviteCode.isNotEmpty) ...[
            const SizedBox(height: 20),
            PetSectionTitle(
              title: L10n.text(language, 'Invite a caregiver', '家族を招待'),
              detail: 'SHARE ACCESS',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const CareIcon(icon: Icons.group, color: PawColors.blue, size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        L10n.text(language, 'Invite code', '招待コード'),
                        style: const TextStyle(
                            fontSize: 12, color: PawColors.muted),
                      ),
                      Text(
                        inviteCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: PawColors.ink,
                          letterSpacing: 1.2,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _copy(inviteCode),
                  icon: Icon(_copied ? Icons.check : Icons.content_copy,
                      size: 16),
                  label: Text(_copied
                      ? L10n.text(language, 'Copied', 'コピー済み')
                      : L10n.text(language, 'Copy', 'コピー')),
                  style: TextButton.styleFrom(
                    foregroundColor: PawColors.purple,
                    backgroundColor: PawColors.lavender,
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              L10n.text(
                language,
                'Share this code with someone you trust so they can join this household.',
                '信頼できる人にこのコードを共有して、家族に招待しましょう。',
              ),
              style: const TextStyle(fontSize: 12, color: PawColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _leaveCard(
      BuildContext context, CareStore store, AppLanguage language) {
    return PetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            L10n.text(language, 'Household membership', '家族メンバーシップ'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: PawColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            L10n.text(
              language,
              'Return this device to the welcome screen without deleting shared household data.',
              '共有データを削除せずに、この端末をウェルカム画面に戻します。',
            ),
            style: const TextStyle(fontSize: 13, color: PawColors.muted),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: store.isSavingProfile
                ? null
                : () => _confirmLeave(context, store),
            icon: const Icon(Icons.logout, size: 18),
            label: Text(L10n.text(language, 'Leave household', '家から退出')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.withValues(alpha: 0.09),
              side: BorderSide.none,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, CareStore store) async {
    final language = context.read<AppLanguageStore>().language;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.text(language, 'Leave this household?', 'この家から退出しますか？')),
        content: Text(L10n.text(
          language,
          'This device will return to the welcome screen. The shared household stays available to other caregivers, and you can rejoin later with the invite code.',
          'この端末はウェルカム画面に戻ります。共有データは他の家族に残り、後で招待コードで再参加できます。',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(L10n.text(language, 'Cancel', 'キャンセル')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              L10n.text(language, 'Leave household', '家から退出'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      store.leaveHousehold();
      Navigator.of(context).pop();
    }
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _save(CareStore store) async {
    final saved = await store.updateProfile(
      caregiverName: _caregiverName.text,
      householdName: _householdName.text,
      petName: _petName.text,
    );
    if (saved && mounted) Navigator.of(context).pop();
  }

  Widget _fieldLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: PawColors.purpleDark),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: PawColors.purpleDark,
          ),
        ),
      ],
    );
  }

  String _t(BuildContext context, String en, String ja) =>
      L10n.text(context.watch<AppLanguageStore>().language, en, ja);
}
