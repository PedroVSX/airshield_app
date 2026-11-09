import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';

import '../models/air_quality_data.dart';
import '../services/mock_air_quality_service.dart';
import 'mqtt_client_factory.dart';
import 'mqtt_config.dart';

enum ConnectionPhase {
  idle,
  connecting,
  subscribing,
  waiting,
  live,
  retained,
  stale,
  reconnecting,
  invalidPayload,
  demo,
}

class ConnectionSnapshot {
  const ConnectionSnapshot(this.phase, this.message);
  final ConnectionPhase phase;
  final String message;
}

typedef MqttClientFactory = MqttClient Function(MqttConfig config, String id);

/// Owns exactly one client and retries with a new client after a hard disconnect.
/// Old callbacks are ignored, including callbacks completing after disposal.
class MqttService {
  MqttService(
    this.config, {
    MqttClientFactory? clientFactory,
    this.retryDelay = const Duration(seconds: 5),
    this.subscriptionTimeout = const Duration(seconds: 10),
  }) : _clientFactory = clientFactory ?? createMqttClient;

  final MqttConfig config;
  final MqttClientFactory _clientFactory;
  final Duration retryDelay;
  final Duration subscriptionTimeout;
  final _states = StreamController<ConnectionSnapshot>.broadcast();
  final _measurements = StreamController<AirQualityData>.broadcast();
  MqttClient? _client;
  StreamSubscription<dynamic>? _updates;
  StreamSubscription<AirQualityData>? _demo;
  Timer? _retryTimer;
  Timer? _deadline;
  Timer? _staleTimer;
  int _generation = 0;
  bool _disposed = false;
  bool _connecting = false;
  bool _stopped = true;

  ConnectionSnapshot current = const ConnectionSnapshot(
    ConnectionPhase.idle,
    'Configure a conexão com o seu AirShield.',
  );
  Stream<ConnectionSnapshot> get states => _states.stream;
  Stream<AirQualityData> get measurements => _measurements.stream;

  void _emit(ConnectionPhase phase, String message) {
    if (_disposed) return;
    current = ConnectionSnapshot(phase, message);
    _states.add(current);
  }

  Future<void> connect() async {
    if (_disposed || _connecting) return;
    _stopped = false;
    _retryTimer?.cancel();
    final issue = config.validate(isWeb: kIsWeb);
    if (issue != null) {
      _emit(ConnectionPhase.idle, issue);
      return;
    }
    if (config.demo) {
      if (_demo != null) return;
      _emit(ConnectionPhase.demo, 'Demonstração • dados simulados');
      _demo = MockAirQualityService().stream.listen(_measurements.add);
      return;
    }

    _closeClient();
    final generation = ++_generation;
    bool active() => !_disposed && !_stopped && generation == _generation;
    _connecting = true;
    _emit(ConnectionPhase.connecting, 'Conectando ao broker…');
    try {
      final id =
          'as${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}'
          '${Random.secure().nextInt(0xffffff).toRadixString(36)}';
      final client = _clientFactory(config, id);
      _client = client;
      client
        ..logging(on: false)
        ..setProtocolV311()
        ..keepAlivePeriod = 20
        ..disconnectOnNoResponsePeriod = 10
        ..autoReconnect = false
        ..connectionMessage = MqttConnectMessage()
            .withClientIdentifier(id)
            .startClean()
        ..onDisconnected = () {
          if (active()) {
            _failed('Conexão perdida. Verifique a rede e o broker.');
          }
        }
        ..onSubscribed = (topic) {
          if (!active() || topic != config.topic) return;
          _deadline?.cancel();
          _emit(
            ConnectionPhase.waiting,
            'Broker conectado • aguardando dados do ESP32',
          );
          _armStaleTimer();
        }
        ..onSubscribeFail = (_) {
          if (active()) _failed('O broker recusou a assinatura do tópico.');
        };
      final status = await client
          .connect(
            config.username.isEmpty ? null : config.username,
            config.password.isEmpty ? null : config.password,
          )
          .timeout(const Duration(seconds: 12));
      if (!active()) return;
      if (status?.state != MqttConnectionState.connected) {
        _failed(
          'Conexão recusada (${status?.returnCode?.name ?? 'sem resposta'}). '
          'Verifique endereço, porta e credenciais.',
        );
        return;
      }
      _connecting = false;
      _updates = client.updates!.listen(
        (messages) {
          if (!active()) return;
          for (final message in messages) {
            if (message.topic != config.topic ||
                message.payload is! MqttPublishMessage) {
              continue;
            }
            final publish = message.payload as MqttPublishMessage;
            try {
              final reading = AirQualityData.fromMqttPayload(
                utf8.decode(publish.payload.message),
                retained: publish.header?.retain ?? false,
              );
              _measurements.add(reading);
              _emit(
                reading.retained
                    ? ConnectionPhase.retained
                    : ConnectionPhase.live,
                reading.retained
                    ? 'Mensagem retida • horário da medição desconhecido'
                    : 'Recebendo dados do ESP32',
              );
              _armStaleTimer();
            } on FormatException {
              _emit(
                ConnectionPhase.invalidPayload,
                'Mensagem inválida no tópico. Confira o JSON do firmware. '
                'Aguardando uma leitura válida.',
              );
            }
          }
        },
        onError: (Object error) {
          if (active()) _failed('Falha ao receber mensagens do broker.');
        },
      );
      _emit(ConnectionPhase.subscribing, 'Conectado • assinando tópico…');
      _deadline = Timer(subscriptionTimeout, () {
        if (active()) _failed('O broker não confirmou a assinatura do tópico.');
      });
      if (client.subscribe(config.topic, MqttQos.atMostOnce) == null) {
        _failed('Não foi possível assinar o tópico do dispositivo.');
      }
    } catch (_) {
      if (active()) {
        _failed(
          'Não foi possível conectar. Verifique rede, host, porta, '
          'transporte e credenciais do broker.',
        );
      }
    }
  }

  void _armStaleTimer() {
    _staleTimer?.cancel();
    _staleTimer = Timer(Duration(seconds: config.staleSeconds), () {
      _emit(
        ConnectionPhase.stale,
        'Sem nova leitura há ${config.staleSeconds}s. '
        'Verifique o ESP32 e o tópico.',
      );
    });
  }

  void _failed(String reason) {
    ++_generation;
    _connecting = false;
    _closeClient();
    if (_disposed || _stopped) return;
    _emit(
      ConnectionPhase.reconnecting,
      '$reason Nova tentativa em '
      '${retryDelay.inSeconds}s.',
    );
    _retryTimer?.cancel();
    _retryTimer = Timer(retryDelay, connect);
  }

  void _closeClient() {
    _deadline?.cancel();
    _staleTimer?.cancel();
    unawaited(_updates?.cancel());
    _updates = null;
    final oldClient = _client;
    _client = null;
    if (oldClient != null) {
      oldClient.onDisconnected = null;
      oldClient.disconnect();
    }
  }

  void disconnect() {
    _stopped = true;
    ++_generation;
    _connecting = false;
    _retryTimer?.cancel();
    unawaited(_demo?.cancel());
    _demo = null;
    _closeClient();
    _emit(ConnectionPhase.idle, 'Desconectado. Conecte nas configurações.');
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    disconnect();
    unawaited(_states.close());
    unawaited(_measurements.close());
  }
}
