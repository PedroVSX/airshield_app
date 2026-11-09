import 'dart:async';

import 'package:airshield_app/data/models/air_quality_data.dart';
import 'package:airshield_app/data/mqtt/mqtt_config.dart';
import 'package:airshield_app/providers/air_quality_provider.dart';
import 'package:airshield_app/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/firmware_payload.dart';

void main() {
  test(
    'collects 100 readings and isolates history when switching devices',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final input = StreamController<AirQualityData>.broadcast();
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          airQualityStreamProvider.overrideWith((ref) => input.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(input.close);
      container.listen(airQualityHistoryProvider, (_, _) {});
      await container.read(airQualityHistoryProvider.future);
      for (var index = 0; index < 105; index++) {
        input.add(AirQualityData.fromMqttPayload(firmwarePayload));
      }
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(airQualityHistoryProvider).requireValue,
        hasLength(100),
      );
      await container
          .read(settingsProvider.notifier)
          .save(
            const MqttConfig(
              macAddress: 'AA:BB:CC:DD:EE:FF',
              connectOnStart: false,
            ),
          );
      expect(await container.read(airQualityHistoryProvider.future), isEmpty);
      input.add(AirQualityData.fromMqttPayload(firmwarePayload));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(airQualityHistoryProvider).requireValue,
        hasLength(1),
      );
      await container
          .read(settingsProvider.notifier)
          .save(const MqttConfig(connectOnStart: false));
      expect(
        await container.read(airQualityHistoryProvider.future),
        hasLength(100),
      );
    },
  );
}
