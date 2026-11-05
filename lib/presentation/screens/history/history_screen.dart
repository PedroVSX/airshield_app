
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/air_quality_data.dart';
import '../../../providers/air_quality_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _selectedMetric = 0;

  final List<String> _metrics = [
    'CO₂',
    'Temperatura',
    'Umidade',
    'COV',
    'PM1.0',
    'PM2.5',
    'PM10',
  ];

  double _getValue(AirQualityData data) {
    switch (_selectedMetric) {
      case 0:
        return data.co2;
      case 1:
        return data.temperature;
      case 2:
        return data.humidity;
      case 3:
        return data.vocIndex;
      case 4:
        return data.pm01;
      case 5:
        return data.pm25;
      case 6:
        return data.pm10;
      default:
        return data.co2;
    }
  }

  String get _unit {
    switch (_selectedMetric) {
      case 0:
        return 'ppm';
      case 1:
        return '°C';
      case 2:
        return '%';
      case 3:
        return 'índice';
      default:
        return 'µg/m³';
    }
  }

  String _formatValue(double value) {
    if (_selectedMetric == 0 || _selectedMetric == 3) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1).replaceAll('.', ',');
  }
  
  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(airQualityHistoryProvider);

    return historyAsync.when(
      data: (history) => _buildContent(history),

      loading: () => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF55D6BE),
        ),
      ),

      error: (error, stackTrace) => const Center(
        child: Text(
          'Não foi possível carregar o histórico.',
          style: TextStyle(color: Color(0xFF9AA6AC)),
        ),
      ),
    );
  }

  Widget _buildContent(List<AirQualityData> history) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Histórico',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acompanhe a evolução das medições ao longo do tempo.',
            style: TextStyle(
              color: Color(0xFF9AA6AC),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          _buildMetricSelector(),

          const SizedBox(height: 20),

          if (history.isEmpty)
            _buildEmptyState()
          else
            _buildHistoryChart(history),

          const SizedBox(height: 20),

          _buildHistoryInfo(history),
        ],
      ),
    );
  }

  Widget _buildMetricSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2228),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF272C38)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedMetric,
          isExpanded: true,
          dropdownColor: const Color(0xFF1B2228),
          items: List.generate(
            _metrics.length,
            (index) => DropdownMenuItem(
              value: index,
              child: Text(_metrics[index]),
            ),
          ),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMetric = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildHistoryChart(List<AirQualityData> history) {
    final values = history.map(_getValue).toList();

    final spots = List.generate(
      values.length,
      (index) => FlSpot(index.toDouble(), values[index]),
    );

    final minimum = values.reduce(math.min);
    final maximum = values.reduce(math.max);

    final difference = maximum - minimum;
    final padding = difference == 0 ? 1.0 : difference * 0.15;

    final minY = minimum - padding;
    final maxY = maximum + padding;

    final latestValue = values.last;

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
          Text(
            _metrics[_selectedMetric],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatValue(latestValue),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  _unit,
                  style: const TextStyle(
                    color: Color(0xFF9AA6AC),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 220,
            child: history.length < 2
                ? const Center(
                    child: Text(
                      'Aguardando mais medições para gerar o gráfico...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9AA6AC)),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (spots.length - 1).toDouble(),
                      minY: minY,
                      maxY: maxY,
                      titlesData: const FlTitlesData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (maxY - minY) / 4,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Color(0xFF303943),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(
                        enabled: true,
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: const Color(0xFF55D6BE),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF55D6BE)
                                .withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${history.length} medições armazenadas',
                style: const TextStyle(
                  color: Color(0xFF9AA6AC),
                  fontSize: 12,
                ),
              ),
              const Text(
                'Últimas 100',
                style: TextStyle(
                  color: Color(0xFF9AA6AC),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2228),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF272C38)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 48,
            color: Color(0xFF55D6BE),
          ),
          SizedBox(height: 16),
          Text(
            'Coletando medições',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Assim que novas medições forem recebidas, '
            'seu histórico aparecerá aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9AA6AC),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryInfo(List<AirQualityData> history) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2228),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF55D6BE),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              history.isEmpty
                  ? 'O histórico será preenchido automaticamente.'
                  : 'As medições são armazenadas localmente no dispositivo '
                    'e permanecem disponíveis após fechar o aplicativo.',
              style: const TextStyle(
                color: Color(0xFF9AA6AC),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
