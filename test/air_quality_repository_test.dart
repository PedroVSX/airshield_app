import 'dart:convert';

import 'package:airshield_app/data/models/air_quality_data.dart';
import 'package:airshield_app/data/repositories/air_quality_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/firmware_payload.dart';

class TestPreferences implements SharedPreferences {
  String? saved;
  bool failNextWrite = false;
  final writes = <String>[];
  @override
  String? getString(String key) => saved;
  @override
  Future<bool> setString(String key, String value) async {
    if (failNextWrite) {
      failNextWrite = false;
      return false;
    }
    writes.add(value);
    saved = value;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'keeps valid history rows, limits to 100 and tolerates corrupt storage',
    () {
      final prefs = TestPreferences();
      final data = AirQualityData.fromMqttPayload(firmwarePayload).toJson();
      prefs.saved = jsonEncode([
        null,
        {'broken': true},
        ...List.filled(110, data),
      ]);
      final repo = AirQualityRepository(prefs, 'test');
      expect(repo.load(), hasLength(100));
      prefs.saved = '{';
      expect(repo.load(), isEmpty);
    },
  );

  test('serializes writes and recovers after a storage failure', () async {
    final prefs = TestPreferences()..failNextWrite = true;
    final repo = AirQualityRepository(prefs, 'test');
    final reading = AirQualityData.fromMqttPayload(firmwarePayload);
    await expectLater(repo.save([reading]), throwsStateError);
    await Future.wait([
      repo.save([reading]),
      repo.save([reading, reading]),
    ]);
    expect(prefs.writes, hasLength(2));
    expect(repo.load(), hasLength(2));
  });
}
