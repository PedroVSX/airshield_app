import 'dart:convert';

import '../../domain/entities/air_quality.dart';

class AirQualityData {
  final double co2;
  final double temperature;
  final double humidity;
  final double vocIndex;
  final double pm01;
  final double pm25;
  final double? pm10;
  final double? pm1;

  final AirQuality? humidityQuality;
  final AirQuality? vocQuality;
  final AirQuality? co2Quality;
  final AirQuality? pm01Quality;
  final AirQuality? pm25Quality;
  final AirQuality? pm10Quality;

  final DateTime receivedAt;
  final bool retained;

  const AirQualityData({
    required this.co2,
    required this.temperature,
    required this.humidity,
    required this.vocIndex,
    required this.pm01,
    required this.pm25,
    required this.pm10,
    required this.humidityQuality,
    required this.vocQuality,
    required this.co2Quality,
    required this.pm01Quality,
    required this.pm25Quality,
    required this.pm10Quality,
    required this.receivedAt,
    this.retained = false,
    this.pm1,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    final medidas = json.containsKey('medidas') ? json['medidas'] : json;
    final indices = json['indices_qualidade'] ?? <String, dynamic>{};

    if (medidas is! Map || indices is! Map) {
      throw const FormatException(
        'JSON não contém os objetos medidas e indices_qualidade.',
      );
    }

    double readNumber(Map data, String key) {
      final value = data[key];

      if (value is num && value.isFinite) return value.toDouble();

      throw FormatException('Valor numérico inválido: $key');
    }

    AirQuality? readQuality(String key) =>
        indices[key] == null ? null : AirQuality.fromJson(indices[key]);

    return AirQualityData(
      co2: readNumber(medidas, 'co2'),
      temperature: readNumber(medidas, 'temperatura'),
      humidity: readNumber(medidas, 'umidade'),
      // `cov` is the firmware contract; keep old local history readable.
      vocIndex: readNumber(
        medidas,
        medidas.containsKey('cov') ? 'cov' : 'indice_cov',
      ),
      pm01: readNumber(medidas, 'pm 0.1'),
      pm25: readNumber(medidas, 'pm 2.5'),
      pm10: medidas.containsKey('pm 10') ? readNumber(medidas, 'pm 10') : null,
      pm1: medidas.containsKey('pm 1.0') ? readNumber(medidas, 'pm 1.0') : null,

      humidityQuality: readQuality('qualidade_umidade'),
      vocQuality: readQuality('qualidade_cov'),
      co2Quality: readQuality('qualidade_co2'),
      pm01Quality: readQuality('qualidade_pm01'),
      pm25Quality: readQuality('qualidade_pm25'),
      pm10Quality: readQuality('qualidade_pm10'),

      receivedAt: json['received_at'] is String
          ? DateTime.tryParse(json['received_at']) ?? DateTime.now()
          : DateTime.now(),
      retained: json['retained'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medidas': {
        'co2': co2,
        'temperatura': temperature,
        'umidade': humidity,
        'cov': vocIndex,
        'pm 0.1': pm01,
        'pm 2.5': pm25,
        if (pm10 != null) 'pm 10': pm10,
        if (pm1 != null) 'pm 1.0': pm1,
      },
      'indices_qualidade': {
        'qualidade_umidade': humidityQuality?.index,
        'qualidade_cov': vocQuality?.index,
        'qualidade_co2': co2Quality?.index,
        'qualidade_pm01': pm01Quality?.index,
        'qualidade_pm25': pm25Quality?.index,
        'qualidade_pm10': pm10Quality?.index,
      },
      'received_at': receivedAt.toIso8601String(),
      'retained': retained,
    };
  }

  factory AirQualityData.fromMqttPayload(
    String payload, {
    bool retained = false,
  }) {
    final decoded = jsonDecode(payload);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Formato de mensagem MQTT inválido.');
    }

    // The firmware has no measurement timestamp. Always stamp local reception.
    return AirQualityData.fromJson({
      ...decoded,
      'received_at': DateTime.now().toIso8601String(),
      'retained': retained,
    });
  }
}
