import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/air_quality_data.dart';
import '../domain/services/mqtt_service.dart';

// Serviço MQTT compartilhado pelo aplicativo.
final mqttServiceProvider = Provider<MqttService>((ref) {
  final service = MqttService();

  ref.onDispose(() {
    unawaited(service.dispose());
  });

  return service;
});

// MAC do dispositivo atualmente selecionado.
class SelectedAirShieldMacNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectDevice(String macAddress) {
    state = macAddress;
  }

  void clearDevice() {
    state = null;
  }
}

final selectedAirShieldMacProvider =
    NotifierProvider<SelectedAirShieldMacNotifier, String?>(
  SelectedAirShieldMacNotifier.new,
);

// Dados de qualidade do ar.
final airQualityStreamProvider = StreamProvider<AirQualityData>((ref) {
  final macAddress = ref.watch(selectedAirShieldMacProvider);

  // Sem dispositivo selecionado, utiliza dados simulados.
  if (macAddress == null) {
    return Stream.value(AirQualityData.empty());
  }

  final mqttService = ref.watch(mqttServiceProvider);

  ref.onDispose(() {
    unawaited(mqttService.disconnect());
  });

  return _mqttAirQualityStream(mqttService, macAddress);
});

// Converte mensagens MQTT em AirQualityData.
Stream<AirQualityData> _mqttAirQualityStream(
  MqttService service,
  String macAddress,
) async* {
  await service.connectToDevice(macAddress);

  yield* service.messages.map((payload) {
    try {
      return AirQualityData.fromMqttPayload(payload);
    } catch (e) {
      print('Erro ao converter JSON MQTT: $e');
      rethrow;
    }
  });
}

// Histórico de medições.
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
    // Escuta novas medições.
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
      } catch (e) {
        print('Erro ao carregar histórico: $e');
        _history = [];
      }
    }

    // Mantém somente as últimas 100 medições.
    if (_history.length > maxMeasurements) {
      _history = _history.sublist(
        _history.length - maxMeasurements,
      );
    }

    _initialized = true;

    // Incorpora medições recebidas durante o carregamento.
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

    // Salva as medições na ordem de recebimento.
    final snapshot = List<AirQualityData>.of(_history);

    _writeQueue = _writeQueue.then((_) async {
      final encoded = jsonEncode(
        snapshot.map((item) => item.toJson()).toList(),
      );

      await _preferences.setString(storageKey, encoded);
    });
  }
}
