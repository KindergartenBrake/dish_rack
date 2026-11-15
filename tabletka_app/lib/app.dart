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

  final TextEditingController _pinController = TextEditingController();

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
      setState(() => _error = 'Неверный PIN-код');
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_locked) return const MainScreen();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: const BoxDecoration(
                          gradient: AppTheme.heroGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.glowShadow,
                        ),
                        child: const Icon(
                          Icons.medication_rounded,
                          size: 54,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.background,
                              width: 3,
                            ),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 20,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Таблеточница',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Введите PIN-код, чтобы продолжить',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _pinController,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => _unlock(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 10,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'PIN-код',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                      ),
                      counterText: '',
                      errorText: _error,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _checking ? null : _unlock,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _checking
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'Разблокировать',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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
