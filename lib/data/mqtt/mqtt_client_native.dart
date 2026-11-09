import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'mqtt_config.dart';

MqttClient createMqttClient(MqttConfig config, String clientId) {
  final server = config.usesWebSocket
      ? '${config.transport.name}://${config.host}${config.webSocketPath}'
      : config.host.replaceAll(RegExp(r'[\[\]]'), '');
  final client =
      MqttServerClient.withPort(
          server,
          clientId,
          config.port,
          maxConnectionAttempts: 1,
        )
        ..useWebSocket = config.usesWebSocket
        ..secure = config.transport == MqttTransport.tls
        ..connectionTimeout = 10000
        ..connectTimeoutPeriod = 10000;
  return client;
}
