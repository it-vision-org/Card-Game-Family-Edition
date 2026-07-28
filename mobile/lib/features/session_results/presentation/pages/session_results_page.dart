import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../active_game/presentation/controllers/session_controller.dart';

const _rewards = [
  'الأكلة القادمة',
  'الفيلم القادم',
  'مكان الخرجة القادمة',
  'صورة المجموعة',
  'التحدّي العائلي القادم',
];

const _funnyPenalties = [
  'يحضّر القهوة للجميع',
  'يلتقط صورة مضحكة',
  'يقول ثلاث كلمات جميلة لكل لاعب',
  'يختار أغنية ويرقص عشر ثوانٍ',
  'يقلّد لاعبًا آخر',
  'يتكفّل بالحلو في اللمة القادمة',
  'يبعث رسالة جميلة في مجموعة العائلة في اليوم التالي',
];

const _goldenRule =
    'هذه اللعبة ليست لاختبار الحب، ولا لمعرفة شكون الأفضل أو شكون يعرف أكثر.\n'
    'هي فرصة باش كل واحد يحسّ أنه مسموع، محبوب، ومكانه محفوظ داخل العائلة.\n'
    'إذا ضحكتوا، حكيتوا من القلب، واكتشفتوا حاجة جديدة على بعضكم… فقد ربحتوا الثلاثة.';

class SessionResultsPage extends ConsumerWidget {
  const SessionResultsPage({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionControllerProvider(sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('نتيجة الجلسة'), automaticallyImplyLeading: false),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (session) {
          final sorted = [...session.participants]..sort((a, b) => b.score.compareTo(a.score));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.celebration, size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'ربحتوا الثلاثة 🎉',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                if (session.scoringEnabled) ...[
                  ...sorted.asMap().entries.map((entry) {
                    final rank = entry.key;
                    final participant = entry.value;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${rank + 1}')),
                        title: Text(participant.displayName),
                        trailing: Text('${participant.score} نقطة'),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  if (sorted.isNotEmpty)
                    _PickerCard(
                      title: '${sorted.first.displayName} يختار المكافأة 🏆',
                      options: _rewards,
                    ),
                  if (sorted.length > 1)
                    _PickerCard(
                      title: '${sorted.last.displayName} يختار عقوبته المرحة 😄',
                      options: _funnyPenalties,
                    ),
                  const SizedBox(height: 20),
                ],
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('القاعدة الذهبية', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(_goldenRule, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('رجوع للرئيسية'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PickerCard extends StatefulWidget {
  const _PickerCard({required this.title, required this.options});

  final String title;
  final List<String> options;

  @override
  State<_PickerCard> createState() => _PickerCardState();
}

class _PickerCardState extends State<_PickerCard> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_picked != null)
              Text(
                _picked!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              )
            else
              OutlinedButton(
                onPressed: () => setState(
                  () => _picked = widget.options[Random().nextInt(widget.options.length)],
                ),
                child: const Text('اسحب'),
              ),
          ],
        ),
      ),
    );
  }
}
