import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../store/care_store.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';

enum _Mode { create, join }

class CreateJoinView extends StatefulWidget {
  const CreateJoinView({super.key});

  @override
  State<CreateJoinView> createState() => _CreateJoinViewState();
}

class _CreateJoinViewState extends State<CreateJoinView> {
  _Mode _mode = _Mode.create;
  final _caregiverName = TextEditingController(text: '');
  final _householdName = TextEditingController(text: 'Mochi Family');
  final _petName = TextEditingController(text: 'Mochi');
  final _inviteCode = TextEditingController(text: '');

  @override
  void dispose() {
    _caregiverName.dispose();
    _householdName.dispose();
    _petName.dispose();
    _inviteCode.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_caregiverName.text.trim().isEmpty) return false;
    if (_mode == _Mode.create) {
      return _householdName.text.trim().isNotEmpty &&
          _petName.text.trim().isNotEmpty;
    }
    return _inviteCode.text.trim().isNotEmpty;
  }

  void _submit(CareStore store) {
    if (_mode == _Mode.create) {
      store.createHousehold(
        name: _householdName.text,
        petName: _petName.text,
        caregiverName: _caregiverName.text,
      );
    } else {
      store.joinHousehold(
        inviteCode: _inviteCode.text,
        caregiverName: _caregiverName.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguageStore>().language;
    final store = context.watch<CareStore>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<AppLanguage>(
            icon: const Icon(Icons.language, color: PawColors.purple),
            onSelected: (value) =>
                context.read<AppLanguageStore>().language = value,
            itemBuilder: (context) => [
              for (final item in AppLanguage.values)
                PopupMenuItem(value: item, child: Text(item.label)),
            ],
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _headerCard(),
                    const SizedBox(height: 22),
                    PetCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton<_Mode>(
                            segments: [
                              ButtonSegment(
                                value: _Mode.create,
                                label: Text(L10n.text(
                                    language, 'Create a home', '家を作る')),
                              ),
                              ButtonSegment(
                                value: _Mode.join,
                                label: Text(L10n.text(
                                    language, 'Join a home', '家に参加')),
                              ),
                            ],
                            selected: {_mode},
                            onSelectionChanged: (selection) =>
                                setState(() => _mode = selection.first),
                          ),
                          const SizedBox(height: 18),
                          _fieldLabel(
                              L10n.text(language, 'Your name', 'あなたの名前'),
                              Icons.person),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _caregiverName,
                            decoration: petFieldDecoration(
                              hintText: L10n.text(language,
                                  'How should your family see you?', '家族に表示する名前'),
                            ),
                          ),
                          if (_mode == _Mode.create) ...[
                            const SizedBox(height: 16),
                            _fieldLabel(
                                L10n.text(language, 'Household', '家の名前'),
                                Icons.home),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _householdName,
                              decoration: petFieldDecoration(
                                hintText: L10n.text(
                                    language, 'Household name', '家族の名前'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _fieldLabel(
                                L10n.text(language, 'Your pet', 'ペット'),
                                Icons.pets),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _petName,
                              decoration: petFieldDecoration(
                                hintText: L10n.text(
                                    language, 'Pet name', 'ペットの名前'),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            _fieldLabel(
                                L10n.text(language, 'Invite code', '招待コード'),
                                Icons.group),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _inviteCode,
                              textCapitalization:
                                  TextCapitalization.characters,
                              autocorrect: false,
                              decoration: petFieldDecoration(
                                hintText: L10n.text(language,
                                    'Enter the six-character code', '6文字のコードを入力'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              L10n.text(
                                language,
                                'Ask a caregiver in your household for their six-character code.',
                                '家族から6文字の招待コードをもらってください。',
                              ),
                              style: const TextStyle(
                                  fontSize: 12, color: PawColors.muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: pawPrimaryButtonStyle(),
                      onPressed:
                          (!_canSubmit || store.isLoading) ? null : () => _submit(store),
                      child: store.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_mode == _Mode.create
                                    ? L10n.text(
                                        language, 'Create household', '家を作成')
                                    : L10n.text(
                                        language, 'Join household', '家に参加')),
                                const SizedBox(width: 9),
                                const Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      L10n.text(
                        language,
                        'One shared place for meals, walks, medicine, and handoffs.',
                        '食事、散歩、薬、引き継ぎをひとつに。',
                      ),
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 12, color: PawColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: PawColors.purpleDark.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const PetArtwork(height: 230),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: PawColors.lavender,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.pets,
                          size: 18, color: PawColors.purple),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'copaw',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: PawColors.ink,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  _t(context, 'Shared care, without the guesswork.',
                      '迷わない、みんなのケア。'),
                  style: const TextStyle(color: PawColors.muted),
                ),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 15, color: PawColors.purple),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        _t(context, 'A happier routine for every pet parent',
                            'すべての飼い主に、もっと楽しい毎日を'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PawColors.purple,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

  String _t(BuildContext context, String en, String ja) {
    return L10n.text(context.watch<AppLanguageStore>().language, en, ja);
  }
}
