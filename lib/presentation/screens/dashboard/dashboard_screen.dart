import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/air_quality_provider.dart';
import '../../../data/models/air_quality_data.dart';
import '../../../domain/entities/air_quality.dart';

import '../sensor_details/sensor_details_screen.dart';
import '../history/history_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  // Cores utilizadas na interface.
  static const Color _backgroundColor = Color(0xFF101418);
  static const Color _surfaceColor = Color(0xFF1B2228);
  static const Color _primaryColor = Color(0xFF55D6BE);
  static const Color _textColor = Color(0xFFF1F5F4);
  static const Color _secondaryTextColor = Color(0xFF9AA6AC);

  @override
  Widget build(BuildContext context) {
    final airQualityAsync = ref.watch(airQualityStreamProvider);
    ref.watch(airQualityHistoryProvider);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: airQualityAsync.when(
          data: (data) {
            switch (_selectedIndex) {
              case 0:
                return _buildDashboard(data);
              case 1:
                return SensorsScreen(data: data);
              case 2:
                return const HistoryScreen();
              default:
                return _buildPlaceholderPage();
            }
          },
          loading: _buildLoading,
          error: (error, stackTrace) => _buildError(error),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: 'Sensores',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            selectedIcon: Icon(Icons.insert_chart_rounded),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(AirQualityData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 700;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? 32 : 20,
            vertical: 20,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),

                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    'Visão geral',
                    'Acompanhe as condições do ambiente',
                  ),

                  const SizedBox(height: 16),

                  _buildAirQualityCard(data),

                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    'Monitoramento',
                    'Medições dos sensores',
                  ),

                  const SizedBox(height: 16),

                  _buildSensorGrid(isWideScreen, data),

                  const SizedBox(height: 24),

                  _buildUpdateInfo(data),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,

          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),

          child: const Icon(
            Icons.air_rounded,
            color: _primaryColor,
            size: 28,
          ),
        ),

        const SizedBox(width: 12),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AirShield',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: _textColor,
                ),
              ),

              SizedBox(height: 2),

              Text(
                'Qualidade do ar interior',
                style: TextStyle(
                  fontSize: 12,
                  color: _secondaryTextColor,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),

          decoration: BoxDecoration(
            color: const Color(0xFF30291D),
            borderRadius: BorderRadius.circular(20),
          ),

          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: Color(0xFFF2B84B),
              ),

              SizedBox(width: 6),

              Text(
                'Demo',
                style: TextStyle(
                  color: Color(0xFFF2B84B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          style: const TextStyle(
            color: _secondaryTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAirQualityCard(AirQualityData data) {
    final quality = _worstQuality(data);
    final statusColor = _qualityColor(quality);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF203B35),
            Color(0xFF1B2928),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withOpacity(0.25),
        ),
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
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.eco_outlined,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'QUALIDADE DO AR',
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_outward_rounded,
                color: _secondaryTextColor,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            quality.label,
            style: TextStyle(
              color: statusColor,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Classificação baseada nos índices dos sensores',
            style: TextStyle(
              color: _textColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (quality.index + 1) / 5,
              child: Container(
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Dados simulados para desenvolvimento.',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorGrid(bool isWideScreen, AirQualityData data) {
    final width = MediaQuery.sizeOf(context).width;

    final crossAxisCount = isWideScreen
        ? 3
        : width < 360
            ? 1
            : 2;

    final sensors = [
      _SensorData(
        name: 'CO₂',
        value: data.co2.toStringAsFixed(0),
        unit: 'ppm',
        icon: Icons.co2,
      ),
      _SensorData(
        name: 'VOC',
        value: data.vocIndex.toStringAsFixed(0),
        unit: 'índice',
        icon: Icons.air,
      ),
      _SensorData(
        name: 'Temperatura',
        value: data.temperature.toStringAsFixed(1).replaceAll('.', ','),
        unit: '°C',
        icon: Icons.thermostat,
      ),
      _SensorData(
        name: 'Umidade',
        value: data.humidity.toStringAsFixed(1).replaceAll('.', ','),
        unit: '%',
        icon: Icons.water_drop_outlined,
      ),
      _SensorData(
        name: 'PM1.0',
        value: data.pm01.toStringAsFixed(1).replaceAll('.', ','),
        unit: 'µg/m³',
        icon: Icons.grain,
      ),
      _SensorData(
        name: 'PM2.5',
        value: data.pm25.toStringAsFixed(1).replaceAll('.', ','),
        unit: 'µg/m³',
        icon: Icons.blur_on,
      ),
      _SensorData(
        name: 'PM10',
        value: data.pm10.toStringAsFixed(1).replaceAll('.', ','),
        unit: 'µg/m³',
        icon: Icons.scatter_plot_outlined,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sensors.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 154,
      ),
      itemBuilder: (context, index) {
        return _buildSensorCard(sensors[index]);
      },
    );
  }

  Widget _buildSensorCard(_SensorData sensor) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: Colors.white.withOpacity(0.04),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,

                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(
                  sensor.icon,
                  color: _primaryColor,
                  size: 20,
                ),
              ),

              const Spacer(),

              const Icon(
                Icons.more_horiz,
                color: _secondaryTextColor,
                size: 20,
              ),
            ],
          ),

          const Spacer(),

          Text(
            sensor.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: _textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,

            children: [
              Flexible(
                child: Text(
                  sensor.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.8,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              Flexible(
                child: Text(
                  sensor.unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateInfo(AirQualityData data) {
    final time = data.receivedAt;

    final formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';

    return Row(
      children: [
        const Icon(
          Icons.schedule_rounded,
          size: 16,
          color: _secondaryTextColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Última atualização: $formattedTime • Simulação',
            style: const TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderPage() {
    final titles = [
      'Início',
      'Sensores',
      'Histórico',
      'Configurações',
    ];

    final descriptions = [
      'Visão geral da qualidade do ar.',
      'Detalhes das medições dos sensores.',
      'Histórico e gráficos das medições.',
      'Preferências e conexão do dispositivo.',
    ];

    final icons = [
      Icons.home_rounded,
      Icons.sensors_rounded,
      Icons.show_chart_rounded,
      Icons.settings_rounded,
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icons[_selectedIndex],
              size: 56,
              color: _primaryColor,
            ),

            const SizedBox(height: 16),

            Text(
              titles[_selectedIndex],
              style: const TextStyle(
                color: _textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              descriptions[_selectedIndex],
              textAlign: TextAlign.center,

              style: const TextStyle(
                color: _secondaryTextColor,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Em desenvolvimento',
              style: TextStyle(
                color: _primaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AirQuality _worstQuality(AirQualityData data) {
    final qualities = [
      data.humidityQuality,
      data.vocQuality,
      data.co2Quality,
      data.pm01Quality,
      data.pm25Quality,
      data.pm10Quality,
    ];

    return qualities.reduce(
      (current, next) =>
          current.index > next.index ? current : next,
    );
  }

  Color _qualityColor(AirQuality quality) {
    switch (quality) {
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

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: _primaryColor,
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Não foi possível carregar as medições.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorData {
  final String name;
  final String value;
  final String unit;
  final IconData icon;

  const _SensorData({
    required this.name,
    required this.value,
    required this.unit,
    required this.icon,
  });
}