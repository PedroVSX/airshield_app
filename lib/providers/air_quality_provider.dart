import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/air_quality_data.dart';
import '../data/repositories/air_quality_repository.dart';
import 'mqtt_provider.dart';
import 'settings_provider.dart';

final airQualityStreamProvider = StreamProvider<AirQualityData>((ref) {
  return ref.watch(mqttServiceProvider).measurements;
});

final airQualityHistoryProvider =
    AsyncNotifierProvider<AirQualityHistoryNotifier, List<AirQualityData>>(
      AirQualityHistoryNotifier.new,
    );

class HistorySaveStatus extends Notifier<String?> {
  @override
  String? build() => null;
  void report(String? message) => state = message;
}

final historySaveStatusProvider = NotifierProvider<HistorySaveStatus, String?>(
  HistorySaveStatus.new,
);

class AirQualityHistoryNotifier extends AsyncNotifier<List<AirQualityData>> {
  @override
  List<AirQualityData> build() {
    final key = ref.watch(
      settingsProvider.select((config) => config.historyKey),
    );
    final repository = AirQualityRepository(
      ref.watch(preferencesProvider),
      key,
    );
    var history = repository.load();
    var active = true;
    ref.onDispose(() => active = false);
    ref.listen<AsyncValue<AirQualityData>>(airQualityStreamProvider, (
      previous,
      next,
    ) {
      // AsyncLoading can carry the previous value when the source changes.
      if (next.isLoading || next.hasError) return;
      final measurement = next.asData?.value;
      if (measurement == null ||
          identical(previous?.asData?.value, measurement)) {
        return;
      }
      history = [...history, measurement];
      if (history.length > AirQualityRepository.maxMeasurements) {
        history = history.sublist(
          history.length - AirQualityRepository.maxMeasurements,
        );
      }
      state = AsyncData(List.unmodifiable(history));
      unawaited(
        repository
            .save(history)
            .then(
              (_) {
                if (active) {
                  ref.read(historySaveStatusProvider.notifier).report(null);
                }
              },
              onError: (Object _) {
                if (active) {
                  ref
                      .read(historySaveStatusProvider.notifier)
                      .report(
                        'As últimas medições estão na memória, mas não puderam ser salvas.',
                      );
                }
              },
            ),
      );
    });
    return List.unmodifiable(history);
  }
}
