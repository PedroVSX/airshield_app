import 'package:airshield_app/data/models/air_quality_data.dart';
import 'package:airshield_app/data/mqtt/mqtt_config.dart';
import 'package:airshield_app/data/mqtt/mqtt_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/firmware_payload.dart';
import 'support/mqtt_test_broker.dart';

Future<ConnectionSnapshot> waitFor(
  MqttService service,
  ConnectionPhase phase,
) => service.states
    .firstWhere((event) => event.phase == phase)
    .timeout(const Duration(seconds: 5));

void main() {
  for (final transport in [MqttTransport.tcp, MqttTransport.ws]) {
    test(
      'receives telemetry on a real ${transport.name} socket and recovers from bad JSON',
      () async {
        final broker = MqttTestBroker();
        await broker.start(webSocket: transport == MqttTransport.ws);
        addTearDown(broker.close);
        final service = MqttService(
          MqttConfig(
            host: '127.0.0.1',
            port: broker.port,
            transport: transport,
            username: 'tester',
            password: 'test-password',
          ),
        );
        addTearDown(service.dispose);
        final readings = <AirQualityData>[];
        final sub = service.measurements.listen(readings.add);
        addTearDown(sub.cancel);
        final waiting = waitFor(service, ConnectionPhase.waiting);
        await service.connect();
        await waiting;
        expect(broker.topics.single, service.config.topic);
        expect(broker.credentials.single, ['tester', 'test-password']);
        if (transport == MqttTransport.ws) {
          expect(broker.webSocketPath, '/mqtt');
        }

        final invalid = waitFor(service, ConnectionPhase.invalidPayload);
        broker.publish(service.config.topic, '{');
        await invalid;
        expect(readings, isEmpty);
        final retained = waitFor(service, ConnectionPhase.retained);
        broker.publish(service.config.topic, firmwarePayload, retained: true);
        await retained;
        expect(readings.single.retained, isTrue);
        final live = waitFor(service, ConnectionPhase.live);
        broker.publish(service.config.topic, firmwarePayload);
        await live;
        expect(readings, hasLength(2));
        expect(readings.last.retained, isFalse);
      },
    );
  }

  test(
    'reconnects, resubscribes and stops retrying after manual disconnect',
    () async {
      final broker = MqttTestBroker();
      await broker.start();
      addTearDown(broker.close);
      final service = MqttService(
        MqttConfig(host: '127.0.0.1', port: broker.port),
        retryDelay: const Duration(milliseconds: 30),
      );
      addTearDown(service.dispose);
      var ready = waitFor(service, ConnectionPhase.waiting);
      await service.connect();
      await ready;
      ready = waitFor(service, ConnectionPhase.waiting);
      broker.dropClients();
      await ready;
      expect(broker.topics, [service.config.topic, service.config.topic]);
      expect(broker.clientIds.toSet(), hasLength(2));
      service.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(broker.clientIds, hasLength(2));
      expect(service.current.phase, ConnectionPhase.idle);
    },
  );

  test('detects rejected subscriptions and missing SUBACK', () async {
    for (final reject in [true, false]) {
      final broker = MqttTestBroker()
        ..rejectSubscription = reject
        ..withholdSubscription = !reject;
      await broker.start();
      final service = MqttService(
        MqttConfig(host: '127.0.0.1', port: broker.port),
        subscriptionTimeout: const Duration(milliseconds: 50),
      );
      try {
        final failure = waitFor(service, ConnectionPhase.reconnecting);
        await service.connect();
        final result = await failure;
        expect(result.message, contains(reject ? 'recusou' : 'não confirmou'));
      } finally {
        service.dispose();
        await broker.close();
      }
    }
  });

  test(
    'marks a silent sensor stale even while the broker is connected',
    () async {
      final broker = MqttTestBroker();
      await broker.start();
      addTearDown(broker.close);
      final service = MqttService(
        MqttConfig(host: '127.0.0.1', port: broker.port, staleSeconds: 10),
      );
      addTearDown(service.dispose);
      final stale = service.states
          .firstWhere((s) => s.phase == ConnectionPhase.stale)
          .timeout(const Duration(seconds: 15));
      await service.connect();
      expect((await stale).message, contains('10s'));
    },
  );
}
