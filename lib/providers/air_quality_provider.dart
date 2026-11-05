import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/air_quality_data.dart';
import '../data/services/mock_air_quality_service.dart';

final airQualityStreamProvider = StreamProvider<AirQualityData>((ref) {
  final service = MockAirQualityService();

  ref.onDispose(service.dispose);

  return service.stream;
});

final airQualityHistoryProvider =
    AsyncNotifierProvider<AirQualityHistoryNotifier, List<AirQualityData>>(
  AirQualityHistoryNotifier.new,
);

class AirQualityHistoryNotifier
    extends AsyncNotifier<List<AirQualityData>> {
  static const int maxMeasurements = 100;
  static const String storageKey = 'air_quality_history';

  late SharedPreferences _preferences;

  List<AirQualityData> _history = [];
  final List<AirQualityData> _pendingMeasurements = [];

  bool _initialized = false;

  Future<void> _writeQueue = Future.value();

  @override
  Future<List<AirQualityData>> build() async {
    // Escuta as medições. Enquanto o armazenamento carrega,
    // mantém as novas medições temporariamente em uma fila.
    ref.listen<AsyncValue<AirQualityData>>(
      airQualityStreamProvider,
      (previous, next) {
        next.whenData(_receiveMeasurement);
      },
    );

    _preferences = await SharedPreferences.getInstance();

    final savedData = _preferences.getString(storageKey);

    if (savedData != null) {
      try {
        final decoded = jsonDecode(savedData);

        if (decoded is List) {
          _history = decoded.map((item) {
            return AirQualityData.fromJson(
              Map<String, dynamic>.from(item as Map),
            );
          }).toList();
        }
      } catch (_) {
        _history = [];
      }
    }

    if (_history.length > maxMeasurements) {
      _history = _history.sublist(
        _history.length - maxMeasurements,
      );
    }

    _initialized = true;

    // Incorpora as medições recebidas durante o carregamento.
    for (final measurement in _pendingMeasurements) {
      _appendMeasurement(measurement);
    }

    _pendingMeasurements.clear();

    return List.unmodifiable(_history);
  }

  void _receiveMeasurement(AirQualityData measurement) {
    if (!_initialized) {
      _pendingMeasurements.add(measurement);
      return;
    }

    _appendMeasurement(measurement);
  }

  void _appendMeasurement(AirQualityData measurement) {
    _history = [
      ..._history,
      measurement,
    ];

    if (_history.length > maxMeasurements) {
      _history.removeRange(
        0,
        _history.length - maxMeasurements,
      );
    }

    state = AsyncData(List.unmodifiable(_history));

    // Mantém as gravações na ordem em que foram solicitadas.
    final snapshot = List<AirQualityData>.of(_history);

    _writeQueue = _writeQueue.then((_) async {
      final encoded = jsonEncode(
        snapshot.map((item) => item.toJson()).toList(),
      );

      await _preferences.setString(storageKey, encoded);
    });
  }
}
