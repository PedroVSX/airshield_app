import 'dart:async';
import 'dart:convert';

import 'package:airshield_app/data/ble/ble_identity_service.dart';
import 'package:airshield_app/presentation/screens/settings/ble_pairing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ble/universal_ble.dart';

class TestIdentityService extends BleIdentityService {
  final results = StreamController<BleDevice>.broadcast();
  bool stopped = false;
  bool disposed = false;
  String? readDevice;
  @override
  Stream<BleDevice> get devices => results.stream;
  @override
  Future<void> startScan() async {
    results.add(BleDevice(deviceId: 'bluetooth-opaque-id', name: 'AirShield'));
  }

  @override
  Future<void> stopScan() async {
    stopped = true;
  }

  @override
  Future<String> readIdentity(String deviceId) async {
    readDevice = deviceId;
    return '48:E7:29:B4:5F:4C';
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await results.close();
  }
}

void main() {
  test('validates the GATT value and preserves MQTT identifier case', () {
    expect(
      BleIdentityService.parseIdentity(utf8.encode('48:E7:29:B4:5F:4C')),
      '48:E7:29:B4:5F:4C',
    );
    expect(
      BleIdentityService.parseIdentity(utf8.encode('48:e7:29:b4:5f:4c')),
      '48:e7:29:b4:5f:4c',
    );
    for (final value in [
      '',
      '48E729B45F4C',
      'bluetooth-id',
      'airshield/#',
      '48:E7:29:B4:5F:4C\u0000',
    ]) {
      expect(
        () => BleIdentityService.parseIdentity(utf8.encode(value)),
        throwsFormatException,
      );
    }
    expect(
      () => BleIdentityService.parseIdentity([255, 254]),
      throwsFormatException,
    );
  });

  testWidgets(
    'selects a device but returns the Wi-Fi identity read from GATT',
    (tester) async {
      final service = TestIdentityService();
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlePairingScreen(service: service),
                    ),
                  );
                },
                child: const Text('Identificar'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Identificar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buscar dispositivos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AirShield'));
      await tester.pumpAndSettle();
      expect(service.readDevice, 'bluetooth-opaque-id');
      expect(result, '48:E7:29:B4:5F:4C');
      expect(service.disposed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
