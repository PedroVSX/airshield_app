import 'dart:async';
import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';

import 'package:airshield_app/data/models/air_quality_data.dart';
import 'package:airshield_app/data/mqtt/mqtt_client_native.dart';
import 'package:airshield_app/data/mqtt/mqtt_config.dart';

/// Read-only diagnostic: subscribes to the two exact topics supplied by the team.
/// Does not publish data, scan wildcard topics, or modify the ESP32.
Future<void> main(List<String> arguments) async {
  final transport = arguments.contains('--wss')
      ? MqttTransport.wss
      : arguments.contains('--tls')
      ? MqttTransport.tls
      : MqttTransport.tcp;
  final config = MqttConfig(
    transport: transport,
    port: transport == MqttTransport.wss
        ? 8084
        : transport == MqttTransport.tls
        ? 8883
        : 1883,
  );
  final client =
      createMqttClient(
          config,
          'ascheck${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
        )
        ..logging(on: false)
        ..setProtocolV311()
        ..keepAlivePeriod = 15;
  final topics = [
    config.topic,
    const MqttConfig(topicFormat: TopicFormat.legacyDeviceId).topic,
  ];
  final subscribed = <String>{};
  var validReadings = 0;
  StreamSubscription<dynamic>? updates;
  try {
    final status = await client.connect().timeout(const Duration(seconds: 12));
    if (status?.state != MqttConnectionState.connected) {
      throw StateError('Broker refused connection: ${status?.returnCode}');
    }
    stdout.writeln(
      'MQTT ${transport.name} connected: ${config.host}:${config.port}',
    );
    client.onSubscribed = (topic) {
      subscribed.add(topic);
      stdout.writeln('SUBACK: $topic');
    };
    updates = client.updates!.listen((messages) {
      for (final message in messages) {
        final publish = message.payload as MqttPublishMessage;
        try {
          AirQualityData.fromMqttPayload(
            MqttPublishPayload.bytesToStringAsString(publish.payload.message),
          );
          validReadings++;
        } on FormatException {
          stdout.writeln('Invalid telemetry payload on ${message.topic}');
        }
      }
    });
    for (final topic in topics) {
      client.subscribe(topic, MqttQos.atMostOnce);
    }
    await Future<void>.delayed(const Duration(seconds: 5));
    stdout.writeln(
      'Confirmed subscriptions: ${subscribed.length}/2; valid readings: $validReadings',
    );
    if (subscribed.length != 2) exitCode = 1;
  } catch (error) {
    stderr.writeln('Broker check failed: ${error.runtimeType}');
    exitCode = 1;
  } finally {
    await updates?.cancel();
    client.disconnect();
  }
}
