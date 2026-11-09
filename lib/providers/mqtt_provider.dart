import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mqtt/mqtt_service.dart';
import 'settings_provider.dart';

final mqttServiceProvider = Provider<MqttService>((ref) {
  final config = ref.watch(settingsProvider);
  final service = MqttService(config);
  ref.onDispose(service.dispose);
  if (config.connectOnStart && (config.demo || config.host.isNotEmpty)) {
    unawaited(Future<void>.microtask(service.connect));
  }
  return service;
});

final connectionProvider = StreamProvider<ConnectionSnapshot>((ref) async* {
  final service = ref.watch(mqttServiceProvider);
  yield service.current;
  yield* service.states;
});
