
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/services/settings_service.dart';
import 'presentation/screens/main_screen.dart';

class TabletkaApp extends StatelessWidget {
  const TabletkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Таблеточница',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppLockGate(),
    );
  }
}

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  bool _loading = true;
  bool _locked = false;
  bool _checking = false;
  String? _error;

  final TextEditingController _pinController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _checkLock() async {
    final hasPin = await SettingsService.hasPin();

    if (!mounted) return;

    setState(() {
      _locked = hasPin;
      _loading = false;
    });
  }

  Future<void> _unlock() async {
    if (_checking) return;

    final pin = _pinController.text;

    if (pin.isEmpty) {
      setState(() => _error = 'Введите PIN-код');
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });

    final correct = await SettingsService.verifyPin(pin);

    if (!mounted) return;

    setState(() => _checking = false);

    if (correct) {
      setState(() {
        _locked = false;
        _error = null;
      });
    } else {
      _pinController.clear();
      setState(() {
        _error = 'Неверный PIN-код';
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_locked) {
      return const MainScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: AppTheme.accentBlue,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Приложение заблокировано',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Введите PIN-код для продолжения',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 28),

                  TextField(
                    controller: _pinController,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => _unlock(),
                    decoration: InputDecoration(
                      labelText: 'PIN-код',
                      counterText: '',
                      errorText: _error,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _checking ? null : _unlock,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      child: _checking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Разблокировать'),
                    ),
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
