import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mqtt/mqtt_config.dart';

final preferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw StateError('SharedPreferences must be initialized before runApp.'),
);

final settingsProvider = NotifierProvider<SettingsNotifier, MqttConfig>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<MqttConfig> {
  static const storageKey = 'airshield_connection_v1';

  @override
  MqttConfig build() {
    final saved = ref.watch(preferencesProvider).getString(storageKey);
    if (saved != null) {
      try {
        return MqttConfig.fromJson(jsonDecode(saved) as Map<String, dynamic>);
      } catch (_) {
        // A malformed preference must not prevent opening configuration.
      }
    }
    return const MqttConfig(connectOnStart: false);
  }

  Future<void> save(MqttConfig config) async {
    final success = await ref
        .read(preferencesProvider)
        .setString(storageKey, jsonEncode(config.toJson()));
    if (!success) throw StateError('Não foi possível salvar a configuração.');
    if (ref.mounted) state = config;
  }
}
