import 'package:flutter/material.dart';

import '../../data/models/session_state.dart';

class TurnIndicator extends StatelessWidget {
  const TurnIndicator({required this.participants, required this.scoringEnabled, super.key});

  final List<Participant> participants;
  final bool scoringEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: participants.map((p) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: p.currentTurn
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.person,
                    color: p.currentTurn ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.displayName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: p.currentTurn ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (scoringEnabled) Text('${p.score} نقطة', style: theme.textTheme.labelSmall),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
