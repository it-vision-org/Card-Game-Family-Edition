import 'dart:async';

import 'package:flutter/material.dart';

/// Simple countdown for challenge cards that carry a `timerSeconds` value.
/// Restarts automatically whenever [sessionCardId] changes (a new card
/// was drawn), driven by the widget key rather than internal state diffing.
class CardTimer extends StatefulWidget {
  const CardTimer({required this.sessionCardId, required this.seconds, super.key});

  final String sessionCardId;
  final int seconds;

  @override
  State<CardTimer> createState() => _CardTimerState();
}

class _CardTimerState extends State<CardTimer> {
  late int _remaining = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant CardTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionCardId != widget.sessionCardId) {
      _remaining = widget.seconds;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _remaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLow = _remaining <= 5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer, color: isLow ? theme.colorScheme.error : null),
        const SizedBox(width: 6),
        Text(
          '$_remaining ثانية',
          style: theme.textTheme.titleMedium?.copyWith(
            color: isLow ? theme.colorScheme.error : null,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
