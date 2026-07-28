import 'package:flutter/material.dart';

import '../../data/models/session_state.dart';

class PowerCardTray extends StatelessWidget {
  const PowerCardTray({
    required this.participant,
    required this.onUse,
    super.key,
  });

  final Participant participant;
  final void Function(PowerCardAssignment assignment) onUse;

  @override
  Widget build(BuildContext context) {
    if (participant.powerCards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(participant.displayName, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: participant.powerCards.map((assignment) {
                return ActionChip(
                  label: Text(assignment.title),
                  avatar: Icon(
                    assignment.used ? Icons.check_circle_outline : Icons.bolt,
                    size: 16,
                  ),
                  onPressed: assignment.used ? null : () => onUse(assignment),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
