import 'package:flutter/material.dart';

const _gameplaySteps = [
  'اقعدوا في بلاصة هادئة وحطّوا الهواتف على جنب.',
  'كل واحد يختار رمزًا يمثّله.',
  'أصغر لاعب يبدأ، وبعدها الدور يمشي مع عقارب الساعة.',
  'اللاعب يسحب كارطة ويقرى السؤال بصوت واضح.',
  'بعض الأسئلة يجاوب عليها لاعب واحد، وبعضها يجاوب عليها الثلاثة.',
  'ممنوع المقاطعة أثناء الإجابة.',
  'بعد كل إجابة، يمكن للاعب آخر أن يطلب توضيحًا واحدًا فقط.',
  'اللعبة تنتهي بعد 15 كارطة (قصيرة) أو 30 كارطة (طويلة)، أو عندما تتفقوا أنكم شبعتوا ضحكًا وحكايات.',
];

const _rules = [
  ('الصراحة من غير قسوة', 'جاوبوا بصدق، أما اختاروا كلامكم بحنان. الصراحة لا تعني التجريح.'),
  ('ممنوع الحكم', 'ما فماش إجابة صحيحة وإجابة غالطة. كل إجابة هي فرصة باش نفهموا الشخص أكثر.'),
  ('ممنوع استعمال الإجابات ضدّ صاحبها', 'أي سر أو موقف يتحكى أثناء اللعبة، ما يتعاودش بعد في خصام أو لوم.'),
  ('لا مقاطعة', 'حتى إذا كانت الحكاية معروفة أو الإجابة طويلة، خلّي صاحبها يكمل.'),
  ('الضحك مسموح، الاستهزاء ممنوع', 'نضحكوا مع بعضنا، موش على بعضنا.'),
  ('حقّ المرور', 'كل لاعب عنده الحق يتجاوز سؤالًا واحدًا فقط طوال الجلسة، من غير تفسير.'),
  ('الإجابة الأولى هي الأصدق', 'في كارطات التخمين، ما نبدّلوش الإجابة بعد ما نسمعوا إجابات الآخرين.'),
  ('الخلاف ما يفسدش اللعبة', 'إذا اختلفتم، كل واحد يفسّر وجهة نظره في دقيقة واحدة، من غير محاولة ربح النقاش.'),
  ('لا يوجد هاتف', 'الهواتف تُستعمل فقط إذا طلبت الكارطة صورة أو تسجيلًا.'),
  ('حضن المصالحة', 'إذا سؤال عمل توترًا، تتوقف اللعبة ويصير حضن أو كلمة طيبة قبل المواصلة.'),
];

const _powerCards = [
  ('الهمس', 'يجب على الطرف الآخر إجابة السؤال بـ "همس" في أذنك فقط.'),
  ('أفضّل ألا أجيب', 'تسمح لكل لاعب بتجاوز سؤال يشعر أنه غير مستعد للإجابة عنه.'),
  ('المرآة', 'يجب على الشخصين الآخرين أن يجيبا على السؤال أيضًا.'),
  ('الحكاية كاملة', 'تطلب من لاعب ألا يكتفي بإجابة قصيرة، بل يحكي الموقف بالتفصيل.'),
  ('بدّل السؤال', 'تضع الكارطة جانبًا وتسحب كارطة جديدة.'),
  ('الكل يجاوب', 'تحوّل أي سؤال فردي إلى سؤال يجاوب عليه الثلاثة.'),
  ('كلمة من القلب', 'تختار شخصًا، ويجب عليه أن يقول لك شيئًا جميلًا وصادقًا.'),
  ('ممنوع الدبلوماسية', 'يجب على صاحب السؤال أن يعطي الإجابة الحقيقية، لا الإجابة التي ترضي الآخرين.'),
];

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('قوانين اللعبة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('طريقة اللعب', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          ..._gameplaySteps.asMap().entries.map(
                (e) => ListTile(
                  dense: true,
                  leading: CircleAvatar(radius: 14, child: Text('${e.key + 1}')),
                  title: Text(e.value),
                ),
              ),
          const Divider(height: 32),
          Text('قوانين اللعبة', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          ..._rules.map(
            (rule) => ExpansionTile(
              title: Text(rule.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(alignment: Alignment.centerRight, child: Text(rule.$2)),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Text('بطاقات القوة', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          ..._powerCards.map(
            (card) => ExpansionTile(
              leading: const Icon(Icons.bolt),
              title: Text(card.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(alignment: Alignment.centerRight, child: Text(card.$2)),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('القاعدة الذهبية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'هذه اللعبة ليست لاختبار الحب، ولا لمعرفة شكون الأفضل أو شكون يعرف أكثر.\n'
                    'هي فرصة باش كل واحد يحسّ أنه مسموع، محبوب، ومكانه محفوظ داخل العائلة.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
