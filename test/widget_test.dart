import 'package:airshield_app/app.dart';
import 'package:airshield_app/data/models/air_quality_data.dart';
import 'package:airshield_app/data/mqtt/mqtt_config.dart';
import 'package:airshield_app/providers/air_quality_provider.dart';
import 'package:airshield_app/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/firmware_payload.dart';

Future<ProviderContainer> mountApp(
  WidgetTester tester, {
  bool demo = false,
  AirQualityData? reading,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      preferencesProvider.overrideWithValue(prefs),
      if (reading != null)
        airQualityStreamProvider.overrideWith((ref) => Stream.value(reading)),
    ],
  );
  if (demo) {
    await container
        .read(settingsProvider.notifier)
        .save(const MqttConfig(demo: true));
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const AirShieldApp(),
    ),
  );
  await tester.pump();
  addTearDown(container.dispose);
  return container;
}

void main() {
  testWidgets('legacy zero readings do not fabricate quality or PM10', (
    tester,
  ) async {
    await mountApp(
      tester,
      reading: AirQualityData.fromMqttPayload(legacyFirmwarePayload),
    );
    await tester.pump();
    expect(
      find.textContaining('Todos os valores recebidos são zero'),
      findsOneWidget,
    );
    expect(find.text('Boa'), findsNothing);
    await tester.tap(find.text('Sensores'));
    await tester.pumpAndSettle();
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Material particulado PM1.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens settings and history before receiving any measurements', (
    tester,
  ) async {
    await mountApp(tester);
    expect(find.text('Aguardando medições'), findsOneWidget);
    await tester.tap(find.text('Configurar conexão'));
    await tester.pumpAndSettle();
    expect(find.text('1. Configure o Wi-Fi do ESP32'), findsOneWidget);
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();
    expect(find.text('Coletando medições'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo shows readings and real mode clears simulated data', (
    tester,
  ) async {
    final container = await mountApp(tester, demo: true);
    await tester.pump();
    expect(find.text('Demo'), findsOneWidget);
    await tester.runAsync(
      () => container
          .read(settingsProvider.notifier)
          .save(const MqttConfig(connectOnStart: false)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aguardando medições'), findsOneWidget);
    expect(find.text('Demo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard fits a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = await mountApp(tester, demo: true);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  });
}
