import 'package:airshield_app/data/mqtt/mqtt_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds the legacy topic from the Wi-Fi identifier', () {
    expect(
      const MqttConfig(topicFormat: TopicFormat.legacyDeviceId).topic,
      'airshield/dispositivo-48E729B45F4C/dados-ambiente',
    );
  });
  test(
    'requires a broker and constructs the exact case-sensitive device topic',
    () {
      expect(const MqttConfig(host: '').validate(), isNotNull);
      const config = MqttConfig(host: 'localhost');
      expect(config.validate(), isNull);
      expect(config.topic, 'airshield/48:E7:29:B4:5F:4C/dados-ambiente');
      expect(
        const MqttConfig(host: 'local', macAddress: '48:e7:29:b4:5f:4c').topic,
        'airshield/48:e7:29:b4:5f:4c/dados-ambiente',
      );
    },
  );

  test('validates address, port, MAC, WebSocket and stale interval', () {
    for (final config in [
      const MqttConfig(host: 'mqtt://local'),
      const MqttConfig(host: 'local:1883'),
      const MqttConfig(host: 'local', port: 0),
      const MqttConfig(host: 'local', port: 65536),
      const MqttConfig(host: 'local', macAddress: '#'),
      const MqttConfig(host: 'local', staleSeconds: 0),
      const MqttConfig(
        host: 'local',
        transport: MqttTransport.ws,
        webSocketPath: 'mqtt',
      ),
    ]) {
      expect(config.validate(), isNotNull);
    }
    expect(const MqttConfig(host: 'local').validate(isWeb: true), isNotNull);
    expect(
      const MqttConfig(
        host: 'local',
        transport: MqttTransport.wss,
      ).validate(isWeb: true),
      isNull,
    );
  });

  test('does not persist passwords and does not auto-connect an authenticated session', () {
    const config = MqttConfig(
      host: 'local',
      username: 'user',
      password: 'secret',
    );
    final restored = MqttConfig.fromJson(config.toJson());
    expect(config.toJson().toString(), isNot(contains('secret')));
    expect(restored.password, isEmpty);
    expect(restored.connectOnStart, isFalse);
  });

  test('separates histories by broker, device and demo source', () {
    final keys = [
      const MqttConfig(host: 'one'),
      const MqttConfig(host: 'two'),
      const MqttConfig(host: 'one', macAddress: 'AA:BB:CC:DD:EE:FF'),
      const MqttConfig(host: 'one', demo: true),
    ].map((config) => config.historyKey).toSet();
    expect(keys, hasLength(4));
  });
}
