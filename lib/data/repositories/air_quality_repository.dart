import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/air_quality_data.dart';

class AirQualityRepository {
  AirQualityRepository(this.preferences, this.storageKey);
  static const maxMeasurements = 100;
  final SharedPreferences preferences;
  final String storageKey;
  Future<void> _writeQueue = Future.value();

  List<AirQualityData> load() {
    final entries = <AirQualityData>[];
    try {
      final saved = preferences.getString(storageKey);
      if (saved == null) return entries;
      final decoded = jsonDecode(saved);
      if (decoded is! List) return entries;
      for (final item in decoded) {
        try {
          final json = Map<String, dynamic>.from(item as Map);
          if (json['received_at'] is! String ||
              DateTime.tryParse(json['received_at']) == null) {
            continue;
          }
          entries.add(AirQualityData.fromJson(json));
        } catch (_) {
          // Keep valid rows if a single stored row is corrupt.
        }
      }
    } catch (_) {
      return entries;
    }
    return entries.length > maxMeasurements
        ? entries.sublist(entries.length - maxMeasurements)
        : entries;
  }

  Future<void> save(List<AirQualityData> history) {
    final encoded = jsonEncode(history.map((entry) => entry.toJson()).toList());
    final write = _writeQueue.then((_) async {
      if (!await preferences.setString(storageKey, encoded)) {
        throw StateError('Falha ao salvar histórico.');
      }
    });
    _writeQueue = write.catchError((Object _) {});
    return write;
  }
}
