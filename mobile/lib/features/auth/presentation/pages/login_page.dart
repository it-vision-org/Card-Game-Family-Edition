import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../controllers/auth_controller.dart';

class _Profile {
  const _Profile(this.publicId, this.displayName, this.emoji);

  final String publicId;
  final String displayName;
  final String emoji;
}

const _profiles = [
  _Profile('AHMED', 'أحمد', '🧑'),
  _Profile('RAHMA', 'رحمة', '👩'),
  _Profile('MAMTI', 'مامتي', '👵'),
];

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  String _selectedPublicId = _profiles.first.publicId;
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بيناتنا الثلاثة',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'اختار البروفايل باش تدخل',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  alignment: WrapAlignment.center,
                  children: _profiles.map((profile) {
                    final selected = profile.publicId == _selectedPublicId;
                    return ChoiceChip(
                      selected: selected,
                      label: Text('${profile.emoji}  ${profile.displayName}'),
                      onSelected: isLoading
                          ? null
                          : (_) => setState(() => _selectedPublicId = profile.publicId),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  enabled: !isLoading,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'الرمز السري',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 8),
                if (authState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _errorMessage(authState.error),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('دخول'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object? error) {
    if (error is ApiException) {
      return error.code == 'INVALID_CREDENTIALS' ? 'الرمز السري غالط، جرب مرة أخرى' : error.message;
    }
    return 'ما نجمناش نتصلو بالسيرفر';
  }

  void _submit() {
    if (_pinController.text.isEmpty) {
      return;
    }
    ref.read(authControllerProvider.notifier).login(
          publicId: _selectedPublicId,
          pin: _pinController.text,
        );
  }
}
