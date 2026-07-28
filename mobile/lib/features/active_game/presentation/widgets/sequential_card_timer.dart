import 'package:flutter/material.dart';

import 'card_timer.dart';

/// For challenge cards where every player answers in turn under the same
/// timer (e.g. دقيقة ضحك، المدح السريع — `answerMode ==
/// 'ALL_PLAYERS_SEQUENTIALLY'`): repeats the timer once per participant
/// instead of a single shared countdown, with a "التالي" button to move to
/// the next player's round. Keyed by `sessionCardId` from the caller so a
/// new card fully resets the round counter.
class SequentialCardTimer extends StatefulWidget {
  const SequentialCardTimer({
    required this.sessionCardId,
    required this.seconds,
    required this.participantCount,
    super.key,
  });

  final String sessionCardId;
  final int seconds;
  final int participantCount;

  @override
  State<SequentialCardTimer> createState() => _SequentialCardTimerState();
}

class _SequentialCardTimerState extends State<SequentialCardTimer> {
  int _round = 0;

  @override
  Widget build(BuildContext context) {
    final isLastRound = _round >= widget.participantCount - 1;

    return Column(
      children: [
        Text(
          'الدور ${_round + 1} من ${widget.participantCount}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        CardTimer(
          key: ValueKey('${widget.sessionCardId}-$_round'),
          sessionCardId: '${widget.sessionCardId}-$_round',
          seconds: widget.seconds,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isLastRound ? null : () => setState(() => _round++),
          icon: const Icon(Icons.skip_next_outlined),
          label: const Text('التالي'),
        ),
      ],
    );
  }
}
