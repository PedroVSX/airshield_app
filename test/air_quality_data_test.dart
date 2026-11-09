import 'dart:convert';

import 'package:airshield_app/data/models/air_quality_data.dart';
import 'package:airshield_app/domain/entities/air_quality.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/firmware_payload.dart';

void main() {
  test(
    'accepts the old flat payload without inventing PM10 or quality indices',
    () {
      final data = AirQualityData.fromMqttPayload(legacyFirmwarePayload);
      expect(data.pm1, 0);
      expect(data.pm10, isNull);
      expect(data.co2Quality, isNull);
      final restored = AirQualityData.fromJson(data.toJson());
      expect(restored.pm1, 0);
      expect(restored.pm10, isNull);
    },
  );
  test(
    'accepts the exact firmware JSON including cov, spaces and zero values',
    () {
      final data = AirQualityData.fromMqttPayload(firmwarePayload);
      expect([
        data.co2,
        data.temperature,
        data.humidity,
        data.vocIndex,
        data.pm01,
        data.pm25,
        data.pm10,
      ], everyElement(0));
      expect(data.humidityQuality, AirQuality.muitoRuim);
      expect(data.toJson()['medidas']['cov'], 0);
    },
  );

  test('preserves distinct floating point readings and stored timestamps', () {
    final json = jsonDecode(firmwarePayload) as Map<String, dynamic>;
    json['medidas'] = {
      'co2': 723,
      'temperatura': 24.3,
      'umidade': 55.7,
      'cov': 117,
      'pm 0.1': 1.2,
      'pm 2.5': 3.4,
      'pm 10': 5.6,
    };
    json['received_at'] = '2026-11-04T16:20:00';
    final data = AirQualityData.fromJson(json);
    final restored = AirQualityData.fromJson(data.toJson());
    expect(restored.vocIndex, 117);
    expect(restored.pm01, 1.2);
    expect(restored.pm25, 3.4);
    expect(restored.pm10, 5.6);
    expect(restored.receivedAt, DateTime(2026, 11, 4, 16, 20));
  });

  test(
    'reads legacy local history but uses cov when both keys are present',
    () {
      final json = jsonDecode(firmwarePayload) as Map<String, dynamic>;
      json['medidas'].remove('cov');
      json['medidas']['indice_cov'] = 13;
      expect(AirQualityData.fromJson(json).vocIndex, 13);
      json['medidas']['cov'] = 24;
      expect(AirQualityData.fromJson(json).vocIndex, 24);
    },
  );

  test(
    'rejects malformed JSON, missing fields and non-finite measurements',
    () {
      for (final payload in ['{', '[]', '{}']) {
        expect(
          () => AirQualityData.fromMqttPayload(payload),
          throwsFormatException,
        );
      }
      for (final value in [null, '22', double.nan, double.infinity]) {
        final json = jsonDecode(firmwarePayload) as Map<String, dynamic>;
        json['medidas']['co2'] = value;
        expect(() => AirQualityData.fromJson(json), throwsFormatException);
      }
      final json = jsonDecode(firmwarePayload) as Map<String, dynamic>;
      json['indices_qualidade']['qualidade_co2'] = 99;
      expect(() => AirQualityData.fromJson(json), throwsFormatException);
    },
  );

  test('records reception time and identifies retained messages', () {
    final json = jsonDecode(firmwarePayload) as Map<String, dynamic>;
    json['received_at'] = '2000-01-01T00:00:00';
    final before = DateTime.now();
    final data = AirQualityData.fromMqttPayload(
      jsonEncode(json),
      retained: true,
    );
    expect(data.receivedAt.isBefore(before), isFalse);
    expect(AirQualityData.fromJson(data.toJson()).retained, isTrue);
  });
}
