
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Future<void> scanESP32() async {
    print('Procurando ESP32...');

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
    );

    _scanSubscription =
        FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        final deviceName = result.device.platformName;

        // Verifica se o dispositivo é um AirShield.
        if (deviceName.startsWith('airshield-')) {
          // Extrai o MAC do nome anunciado.
          final macAddress = deviceName.replaceFirst(
            'airshield-',
            '',
          );

          print('ESP32 encontrado!');
          print('Nome: $deviceName');
          print('MAC: $macAddress');

          print('RSSI: ${result.rssi} dBm');
        }
      }
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }
}
