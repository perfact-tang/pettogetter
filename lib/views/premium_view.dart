import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';

class PremiumView extends StatelessWidget {
  const PremiumView({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguageStore>().language;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('copaw Pro'),
      ),
      body: Stack(
        children: [
          const PetScreenBackground(),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _hero(context),
                    const SizedBox(height: 20),
                    PetCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PetSectionTitle(
                            title: L10n.text(language,
                                'Made for the whole family', '家族みんなのために'),
                            detail: 'PRO',
                          ),
                          const SizedBox(height: 14),
                          _feature(
                              L10n.text(language,
                                  'Unlimited pets and caregivers', 'ペットも家族も無制限'),
                              Icons.group,
                              PawColors.purple),
                          _feature(
                              L10n.text(language,
                                  'Recurring medication routines', 'お薬ルーティン'),
                              Icons.medication,
                              PawColors.rose),
                          _feature(
                              L10n.text(
                                  language, 'Complete care history', '完全なケア履歴'),
                              Icons.history,
                              PawColors.blue),
                          _feature(
                              L10n.text(
                                  language, 'Pet sitter handoff mode', 'ペットシッター引継ぎ'),
                              Icons.waving_hand,
                              PawColors.yellow),
                          _feature(
                              L10n.text(
                                  language, 'Smart care reminders', 'スマートリマインダー'),
                              Icons.auto_awesome,
                              PawColors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _priceCard(
                              L10n.text(language, 'Monthly', '月額'),
                              '¥300',
                              L10n.text(language, 'per month', '月あたり'),
                              false),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _priceCard(
                              L10n.text(language, 'Annual', '年額'),
                              '¥2,000',
                              L10n.text(language, 'per year', '年あたり'),
                              true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: pawPrimaryButtonStyle(),
                      onPressed: () => _showPrototypeMessage(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(L10n.text(
                              language, 'Start Free Trial', '無料トライアル')),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      L10n.text(
                        language,
                        'Prototype pricing. Payment is not enabled in this build.',
                        '試作価格です。このビルドでは支払いは有効ではありません。',
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

  Widget _hero(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: PawColors.purpleDark.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              const PetArtwork(height: 210),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium,
                          size: 14, color: PawColors.purpleDark),
                      SizedBox(width: 4),
                      Text(
                        'FAMILY PRO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: PawColors.purpleDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            child: Column(
              children: [
                Text(
                  _t(context, 'More love. Less mental load.', 'もっと愛を。負担は少なく。'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: PawColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _t(
                    context,
                    'Build a calmer care routine for every pet and every caregiver.',
                    'ペットにも家族にも、もっと穏やかなケアを。',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: PawColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feature(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CareIcon(icon: icon, color: color, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: PawColors.ink,
              ),
            ),
          ),
          const Icon(Icons.check_circle, size: 18, color: PawColors.green),
        ],
      ),
    );
  }

  Widget _priceCard(
      String title, String price, String detail, bool highlight) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: highlight
            ? PawColors.lavender
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: highlight ? PawColors.purple : Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: PawColors.purpleDark.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            highlight ? 'BEST VALUE' : 'FLEXIBLE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.white : PawColors.muted,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: PawColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PawColors.purpleDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(fontSize: 12, color: PawColors.muted),
          ),
        ],
      ),
    );
  }

  void _showPrototypeMessage(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prototype package'),
        content: const Text('Payments are not enabled in this prototype.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _t(BuildContext context, String en, String ja) =>
      L10n.text(context.watch<AppLanguageStore>().language, en, ja);
}
