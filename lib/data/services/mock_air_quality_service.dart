import 'dart:async';
import 'dart:math';

import '../../domain/entities/air_quality.dart';
import '../models/air_quality_data.dart';

class MockAirQualityService {
  final Random _random = Random();
  bool _disposed = false;

  Stream<AirQualityData> get stream async* {
    while (!_disposed) {
      yield _generateData();
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  AirQualityData _generateData() {
    final co2 = _random.nextInt(500) + 500;
    final temperature = 23 + _random.nextDouble() * 5;
    final humidity = 45 + _random.nextDouble() * 25;
    final voc = _random.nextInt(150) + 50;

    final pm01 = _random.nextDouble() * 8;
    final pm25 = _random.nextDouble() * 15;
    final pm10 = _random.nextDouble() * 25;

    return AirQualityData(
      co2: co2.toDouble(),
      temperature: temperature,
      humidity: humidity,
      vocIndex: voc.toDouble(),
      pm01: pm01,
      pm25: pm25,
      pm10: pm10,

      humidityQuality: _randomQuality(),
      vocQuality: _randomQuality(),
      co2Quality: _randomQuality(),
      pm01Quality: _randomQuality(),
      pm25Quality: _randomQuality(),
      pm10Quality: _randomQuality(),

      receivedAt: DateTime.now(),
    );
  }

  AirQuality _randomQuality() {
    // Simula resultados mais frequentemente bons ou moderados.
    final value = _random.nextInt(100);

    if (value < 45) return AirQuality.boa;
    if (value < 80) return AirQuality.moderada;
    if (value < 92) return AirQuality.ruim;
    if (value < 98) return AirQuality.muitoRuim;

    return AirQuality.pessima;
  }

  void dispose() {
    _disposed = true;
  }
}