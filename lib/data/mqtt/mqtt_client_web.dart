import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

import 'mqtt_config.dart';

MqttClient createMqttClient(MqttConfig config, String clientId) =>
    MqttBrowserClient.withPort(
      '${config.transport.name}://${config.host}${config.webSocketPath}',
      clientId,
      config.port,
      maxConnectionAttempts: 1,
    )..connectTimeoutPeriod = 10000;
