import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/today/today_screen.dart';

class TabletkaApp extends StatelessWidget {
  const TabletkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Таблеточница',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const TodayScreen(),
    );
  }
}