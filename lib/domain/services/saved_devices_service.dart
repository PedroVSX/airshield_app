import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedDevicesService {
  static const String _storageKey = 'airshield_saved_devices';

  Future<List<Map<String, String>>> getDevices() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getStringList(_storageKey) ?? [];

    return saved.map((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;

      return {
        'name': decoded['name'] as String,
        'mac': decoded['mac'] as String,
      };
    }).toList();
  }

  Future<void> saveDevice(String name, String mac) async {
    final prefs = await SharedPreferences.getInstance();

    final devices = await getDevices();

    // Evita salvar o mesmo ESP32 duas vezes.
    final alreadyExists = devices.any(
      (device) => device['mac'] == mac,
    );

    if (alreadyExists) return;

    devices.add({
      'name': name,
      'mac': mac,
    });

    final encoded = devices.map((device) {
      return jsonEncode(device);
    }).toList();

    await prefs.setStringList(_storageKey, encoded);
  }

  Future<void> removeDevice(String mac) async {
    final prefs = await SharedPreferences.getInstance();

    final devices = await getDevices();

    devices.removeWhere(
      (device) => device['mac'] == mac,
    );

    final encoded = devices.map((device) {
      return jsonEncode(device);
    }).toList();

    await prefs.setStringList(_storageKey, encoded);
  }

  Future<void> renameDevice(String mac, String newName) async {
    final prefs = await SharedPreferences.getInstance();
  
    final devices = await getDevices();
  
    final index = devices.indexWhere(
      (device) => device['mac'] == mac,
    );
  
    if (index == -1) return;
  
    devices[index]['name'] = newName;
  
    final encoded = devices.map((device) {
      return jsonEncode(device);
    }).toList();
  
    await prefs.setStringList(_storageKey, encoded);
  }
}
