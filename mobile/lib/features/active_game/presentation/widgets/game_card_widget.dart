import 'package:flutter/material.dart';

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

  // Sampled from card-background.png's watercolor palette so the text reads
  // naturally against the cream center instead of needing a dark overlay.
  static const _titleColor = Color(0xFF6B3F3A);
  static const _bodyColor = Color(0xFF5A4038);
  static const _labelColor = Color(0xFF8B6F5E);
  static const _badgeBackground = Color(0x1F6B3F3A);

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
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(56, 72, 56, 56),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _categoryLabels[card.categoryCode] ?? (isChallenge ? 'مفاجأة وتحدّي' : ''),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: _labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (card.title != null) ...[
                  Text(
                    card.title!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(color: _titleColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  card.text ?? '',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: _bodyColor,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (card.instructions != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    card.instructions!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: _labelColor),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (card.timerSeconds != null)
                      _Badge(icon: Icons.timer_outlined, label: '${card.timerSeconds} ث'),
                    if (card.supportsScoring) const _Badge(icon: Icons.emoji_events_outlined, label: 'فيها نقاط'),
                    if (card.skippable) const _Badge(icon: Icons.skip_next_outlined, label: 'يمكن تجاوزها'),
                  ],
                ),
              ],
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
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GameCardWidget._titleColor),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: GameCardWidget._titleColor, fontSize: 12)),
        ],
      ),
    );
  }
}
