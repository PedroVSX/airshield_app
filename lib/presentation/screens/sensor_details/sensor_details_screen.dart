import 'package:flutter/material.dart';

import '../../../data/models/air_quality_data.dart';
import '../../../domain/entities/air_quality.dart';

class SensorsScreen extends StatelessWidget {
  final AirQualityData data;
  final bool demo;

  const SensorsScreen({super.key, required this.data, this.demo = false});

  @override
  Widget build(BuildContext context) {
    final sensors = [
      _SensorInfo(
        name: 'CO₂',
        description: 'Concentração de dióxido de carbono',
        value: data.co2.toStringAsFixed(0),
        unit: 'ppm',
        icon: Icons.co2_rounded,
        quality: data.co2Quality,
      ),
      _SensorInfo(
        name: 'Compostos orgânicos voláteis',
        description: 'Valor COV enviado pelo firmware',
        value: data.vocIndex.toStringAsFixed(0),
        unit: demo ? 'índice' : 'valor',
        icon: Icons.air_rounded,
        quality: data.vocQuality,
      ),
      _SensorInfo(
        name: 'Temperatura',
        description: 'Temperatura do ambiente',
        value: data.temperature.toStringAsFixed(1).replaceAll('.', ','),
        unit: '°C',
        icon: Icons.thermostat_rounded,
      ),
      _SensorInfo(
        name: 'Umidade',
        description: 'Umidade relativa do ar',
        value: data.humidity.toStringAsFixed(1).replaceAll('.', ','),
        unit: '%',
        icon: Icons.water_drop_outlined,
        quality: data.humidityQuality,
      ),
      _SensorInfo(
        name: 'Material particulado (campo PM 0.1)',
        description: 'Campo "pm 0.1" do firmware; faixa a confirmar',
        value: data.pm01.toStringAsFixed(1).replaceAll('.', ','),
        unit: 'µg/m³',
        icon: Icons.grain_rounded,
        quality: data.pm01Quality,
      ),
      _SensorInfo(
        name: 'Material particulado PM2.5',
        description: 'Partículas com diâmetro de até 2,5 µm',
        value: data.pm25.toStringAsFixed(1).replaceAll('.', ','),
        unit: 'µg/m³',
        icon: Icons.blur_on_rounded,
        quality: data.pm25Quality,
      ),
      _SensorInfo(
        name: 'Material particulado PM10',
        description: 'Partículas com diâmetro de até 10 µm',
        value: data.pm10?.toStringAsFixed(1).replaceAll('.', ',') ?? '—',
        unit: 'µg/m³',
        icon: Icons.bubble_chart_rounded,
        quality: data.pm10Quality,
      ),
      if (data.pm1 != null)
        _SensorInfo(
          name: 'Material particulado PM1.0',
          description: 'Campo "pm 1.0" do firmware antigo',
          value: data.pm1!.toStringAsFixed(1),
          unit: 'µg/m³',
          icon: Icons.grain,
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sensores',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acompanhe as medições e classificações individuais '
            'dos sensores do AirShield.',
            style: TextStyle(color: Color(0xFF9AA6AC), fontSize: 14),
          ),
          const SizedBox(height: 24),

          ...sensors.map(
            (sensor) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SensorCard(sensor: sensor, demo: demo),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'Recebido às '
            '${data.receivedAt.hour.toString().padLeft(2, '0')}:'
            '${data.receivedAt.minute.toString().padLeft(2, '0')}:'
            '${data.receivedAt.second.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Color(0xFF9AA6AC), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SensorInfo {
  final String name;
  final String description;
  final String value;
  final String unit;
  final IconData icon;
  final AirQuality? quality;

  const _SensorInfo({
    required this.name,
    required this.description,
    required this.value,
    required this.unit,
    required this.icon,
    this.quality,
  });
}

class _SensorCard extends StatelessWidget {
  final _SensorInfo sensor;
  final bool demo;

  const _SensorCard({required this.sensor, required this.demo});

  Color get statusColor {
    if (sensor.quality == null || !demo) {
      return const Color(0xFF9AA6AC);
    }

    switch (sensor.quality!) {
      case AirQuality.boa:
        return const Color(0xFF43B581);
      case AirQuality.moderada:
        return const Color(0xFFF2B84B);
      case AirQuality.ruim:
        return const Color(0xFFFF914D);
      case AirQuality.muitoRuim:
        return const Color(0xFFE85D75);
      case AirQuality.pessima:
        return const Color(0xFFB65DE8);
    }
  }

  String get statusLabel => sensor.quality == null
      ? 'Informativo'
      : demo
      ? sensor.quality!.label
      : 'Código ${sensor.quality!.index}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2228),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF272C38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF29453F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(sensor.icon, color: const Color(0xFF55D6BE)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensor.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sensor.description,
                      style: const TextStyle(
                        color: Color(0xFF9AA6AC),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                sensor.value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  sensor.unit,
                  style: const TextStyle(
                    color: Color(0xFF9AA6AC),
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
