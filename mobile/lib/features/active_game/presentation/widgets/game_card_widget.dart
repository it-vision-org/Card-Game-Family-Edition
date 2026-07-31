import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/session_state.dart';

/// The card face: the illustrated watercolor frame in
/// `assets/images/card-background.png` is always the same — only the
/// category label, main text and instructions change per card.
class GameCardWidget extends StatelessWidget {
  const GameCardWidget({required this.card, super.key});

  final CurrentCard card;

  static const _categoryLabels = {
    'HOW_WELL_DO_WE_KNOW_EACH_OTHER': 'نعرفوا بعضنا قدّاش؟',
    'MEMORIES_AND_STORIES': 'ذكريات وحكايات',
    'FUN_AND_GUESSING': 'ضحك وتخمين',
    'FROM_THE_HEART': 'من القلب',
    'FUTURE_AND_FAMILY': 'المستقبل والعائلة',
    'CHALLENGES_AND_SURPRISES': 'مفاجأة وتحدّي',
  };

  static const _titleColor = AppColors.textPrimary;
  static const _bodyColor = AppColors.textPrimary;
  static const _labelColor = AppColors.textSecondary;
  static const _badgeBackground = AppColors.primaryLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChallenge = card.type == 'CHALLENGE';

    return AspectRatio(
      aspectRatio: 1821 / 1145,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: AssetImage('assets/images/card-background.png'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(56, 64, 56, 56),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _categoryLabels[card.categoryCode] ??
                        (isChallenge ? 'مفاجأة وتحدّي' : ''),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _labelColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (card.title != null) ...[
                    Text(
                      card.title!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: _titleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  Text(
                    card.text ?? '',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: _bodyColor,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (card.instructions != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      card.instructions!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: _labelColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (card.timerSeconds != null)
                        _Badge(
                          icon: Icons.timer_outlined,
                          label: '${card.timerSeconds} ث',
                        ),
                      if (card.supportsScoring)
                        const _Badge(
                          icon: Icons.emoji_events_outlined,
                          label: 'فيها نقاط',
                        ),
                      if (card.skippable)
                        const _Badge(
                          icon: Icons.skip_next_outlined,
                          label: 'يمكن تجاوزها',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: GameCardWidget._badgeBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GameCardWidget._titleColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: GameCardWidget._titleColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
