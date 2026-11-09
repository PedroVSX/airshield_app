import 'dart:convert';

import '../../domain/entities/air_quality.dart';

class AirQualityData {
  final double co2;
  final double temperature;
  final double humidity;
  final double vocIndex;
  final double pm01;
  final double pm25;
  final double pm10;

  final AirQuality humidityQuality;
  final AirQuality vocQuality;
  final AirQuality co2Quality;
  final AirQuality pm01Quality;
  final AirQuality pm25Quality;
  final AirQuality pm10Quality;

  final DateTime receivedAt;

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
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    final medidas = json['medidas'];
    final indices = json['indices_qualidade'];

    if (medidas is! Map || indices is! Map) {
      throw const FormatException(
        'JSON não contém os objetos medidas e indices_qualidade.',
      );
    }

    double readNumber(Map data, String key) {
      final value = data[key];

      if (value is num) return value.toDouble();

      throw FormatException('Valor numérico inválido: $key');
    }

    return AirQualityData(
      co2: readNumber(medidas, 'co2'),
      temperature: readNumber(medidas, 'temperatura'),
      humidity: readNumber(medidas, 'umidade'),
      vocIndex: readNumber(medidas, 'indice_cov'),
      pm01: readNumber(medidas, 'pm 0.1'),
      pm25: readNumber(medidas, 'pm 2.5'),
      pm10: readNumber(medidas, 'pm 10'),

      humidityQuality: AirQuality.fromJson(
        indices['qualidade_umidade'],
      ),
      vocQuality: AirQuality.fromJson(
        indices['qualidade_cov'],
      ),
      co2Quality: AirQuality.fromJson(
        indices['qualidade_co2'],
      ),
      pm01Quality: AirQuality.fromJson(
        indices['qualidade_pm01'],
      ),
      pm25Quality: AirQuality.fromJson(
        indices['qualidade_pm25'],
      ),
      pm10Quality: AirQuality.fromJson(
        indices['qualidade_pm10'],
      ),

      receivedAt: json['received_at'] is String
        ? DateTime.tryParse(json['received_at']) ?? DateTime.now()
        : DateTime.now(),
    );
  }

  factory AirQualityData.empty() {
    return AirQualityData(
      co2: 0,
      temperature: 0,
      humidity: 0,
      vocIndex: 0,
      pm01: 0,
      pm25: 0,
      pm10: 0,
  
      // humidityQuality: AirQuality.boa,
      // vocQuality: AirQuality.boa,
      // co2Quality: AirQuality.boa,
      // pm01Quality: AirQuality.boa,
      // pm25Quality: AirQuality.boa,
      // pm10Quality: AirQuality.boa,
  
      humidityQuality: AirQuality.boa,
      vocQuality: AirQuality.boa,
      co2Quality: AirQuality.boa,
      pm01Quality: AirQuality.boa,
      pm25Quality: AirQuality.boa,
      pm10Quality: AirQuality.boa,

      receivedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medidas': {
        'co2': co2,
        'temperatura': temperature,
        'umidade': humidity,
        'indice_cov': vocIndex,
        'pm 0.1': pm01,
        'pm 2.5': pm25,
        'pm 10': pm10,
      },
      'indices_qualidade': {
        'qualidade_umidade': humidityQuality.index,
        'qualidade_cov': vocQuality.index,
        'qualidade_co2': co2Quality.index,
        'qualidade_pm01': pm01Quality.index,
        'qualidade_pm25': pm25Quality.index,
        'qualidade_pm10': pm10Quality.index,
      },
      'received_at': receivedAt.toIso8601String(),
    };
  }

  factory AirQualityData.fromMqttPayload(String payload) {
    final decoded = jsonDecode(payload);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Formato de mensagem MQTT inválido.');
    }

    return AirQualityData.fromJson(decoded);
  }
}