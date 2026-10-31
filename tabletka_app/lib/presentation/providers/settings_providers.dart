import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/settings_service.dart';

final userNameProvider = FutureProvider<String>((ref) async {
  return SettingsService.getUserName();
});