import 'dart:async';
import 'dart:convert';

import 'package:universal_ble/universal_ble.dart';

/// Proposed AirShield GATT contract. The ESP32 firmware must implement it.
class BleIdentityService {
  static const serviceUuid = '9b1d0001-6c2e-4b5a-8f10-4a6972736864';
  static const identityUuid = '9b1d0002-6c2e-4b5a-8f10-4a6972736864';
  static const operationTimeout = Duration(seconds: 12);
  bool _disposed = false;
  String? _activeDevice;

  Stream<BleDevice> get devices => UniversalBle.scanStream;

  Future<void> startScan() async {
    if (_disposed) return;
    // startScan requests OS permissions; on Web this opens the browser picker.
    await UniversalBle.startScan(
      scanFilter: ScanFilter(withServices: [serviceUuid]),
      platformConfig: PlatformConfig(
        android: AndroidOptions(legacy: true, requestLocationPermission: false),
      ),
    );
    if (_disposed) await stopScan();
  }

  Future<void> stopScan() => UniversalBle.stopScan();

  Future<String> readIdentity(String deviceId) async {
    if (_disposed) throw StateError('Identificação cancelada.');
    if (_activeDevice != null) throw StateError('Identificação em andamento.');
    _activeDevice = deviceId;
    try {
      await stopScan();
      _checkActive();
      await UniversalBle.connect(deviceId, timeout: operationTimeout);
      _checkActive();
      await UniversalBle.discoverServices(deviceId, timeout: operationTimeout);
      _checkActive();
      final bytes = await UniversalBle.read(
        deviceId,
        serviceUuid,
        identityUuid,
        timeout: operationTimeout,
      );
      _checkActive();
      return parseIdentity(bytes);
    } finally {
      await _disconnectQuietly(deviceId);
      _activeDevice = null;
    }
  }

  void _checkActive() {
    if (_disposed) throw StateError('Identificação cancelada.');
  }

  static String parseIdentity(List<int> bytes) {
    // BLE's own address is NOT the Wi-Fi MAC and must never form the topic.
    if (bytes.length > 32) {
      throw const FormatException('Identificador BLE muito longo.');
    }
    final value = utf8.decode(bytes).trim();
    if (!RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$').hasMatch(value)) {
      throw const FormatException(
        'O ESP32 deve enviar o MAC Wi-Fi como texto AA:BB:CC:DD:EE:FF.',
      );
    }
    return value; // Preserve case: MQTT topics are case-sensitive.
  }

  Future<void> _disconnectQuietly(String id) async {
    try {
      await UniversalBle.disconnect(id, timeout: const Duration(seconds: 3));
    } catch (_) {
      // Device may already be out of range or disconnected.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    try {
      await stopScan();
    } catch (_) {
      /* Adapter may be unavailable. */
    }
    final id = _activeDevice;
    if (id != null) await _disconnectQuietly(id);
  }
}
