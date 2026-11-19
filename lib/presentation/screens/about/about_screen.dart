
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const Color backgroundColor = Color(0xFF101418);
  static const Color surfaceColor = Color(0xFF1B2228);
  static const Color primaryColor = Color(0xFF55D6BE);
  static const Color textColor = Color(0xFFF1F5F4);
  static const Color secondaryTextColor = Color(0xFF9AA6AC);

  static const Color goodColor = Color(0xFF4EA62C);
  static const Color moderateColor = Color(0xFFf7d400);
  static const Color badColor = Color(0xFFec8924);
  static const Color veryBadColor = Color(0xFFcb0912);
  static const Color terribleColor = Color(0xFF950060);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        title: const Text('Sobre o AirShield'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.air,
              color: primaryColor,
              size: 45,
            ),

            const SizedBox(height: 16),

            const Text(
              'Entenda a qualidade do ar',
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'O AirShield monitora diferentes parâmetros '
              'ambientais para avaliar a qualidade do ar, '
              'a ventilação e o conforto do ambiente.',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 28),

            _buildSectionTitle(
              Icons.air,
              'Qualidade do ar',
            ),

            // COVs
            _buildInfoCard(
              icon: Icons.science_outlined,
              title: 'COVs',
              subtitle: 'Compostos Orgânicos Voláteis',
              description:
                  'O VOC Index indica a variação relativa dos '
                  'compostos orgânicos voláteis no ambiente. '
                  'Valores elevados indicam aumento em relação '
                  'à referência do sensor.',
              healthEffects:
                  'A exposição a determinados compostos orgânicos '
                  'voláteis pode causar irritação nos olhos, nariz '
                  'e garganta, dores de cabeça, tontura e desconforto '
                  'respiratório. Alguns compostos podem apresentar '
                  'riscos à saúde em exposições prolongadas.',
              healthSource:
                  'EPA – Volatile Organic Compounds (VOCs).',
              unit: 'VOC Index',
              ranges: [
                _range('Boa', '1 a 100', goodColor),
                _range('Moderada', '101 a 150', moderateColor),
                _range('Ruim', '151 a 250', badColor),
                _range('Muito ruim', '251 a 500', veryBadColor),
              ],
            ),

            // PM1.0
            _buildInfoCard(
              icon: Icons.grain,
              title: 'PM1.0',
              subtitle: 'Partículas ultrafinas',
              description:
                  'São partículas com diâmetro de até 1 micrômetro. '
                  'Por serem muito pequenas, podem penetrar '
                  'profundamente no sistema respiratório.',
              healthEffects:
                  'A exposição a partículas muito pequenas pode '
                  'contribuir para efeitos respiratórios e '
                  'cardiovasculares. Entretanto, os efeitos '
                  'específicos do PM1.0 ainda são menos estabelecidos '
                  'do que os do PM2.5 e PM10.',
              healthSource:
                  'OMS – Health consequences of air pollution.',
              unit: 'µg/m³',
              ranges: [
                _range('Boa', 'Até 5', goodColor),
                _range('Moderada', 'Acima de 5 até 15', moderateColor),
                _range('Ruim', 'Acima de 15 até 35', badColor),
                _range('Muito ruim', 'Acima de 35', veryBadColor),
              ],
            ),

            // PM2.5
            _buildInfoCard(
              icon: Icons.blur_on,
              title: 'PM2.5',
              subtitle: 'Partículas finas',
              description:
                  'São partículas com diâmetro de até 2,5 micrômetros. '
                  'Podem alcançar regiões profundas dos pulmões '
                  'e representar riscos à saúde.',
              healthEffects:
                  'A exposição pode provocar inflamação das vias '
                  'respiratórias, agravar a asma e aumentar os riscos '
                  'de doenças cardiovasculares e respiratórias. '
                  'A exposição prolongada também está associada '
                  'a um maior risco de câncer de pulmão.',
              healthSource:
                  'OMS – Global Air Quality Guidelines.',
              unit: 'µg/m³',
              ranges: [
                _range('Boa', 'Até 15', goodColor),
                _range('Moderada', 'Acima de 15 até 50', moderateColor),
                _range('Ruim', 'Acima de 50 até 75', badColor),
                _range('Muito ruim', 'Acima de 75 até 125', veryBadColor),
                _range('Péssima', 'Acima de 125', terribleColor),
              ],
            ),

            // PM10
            _buildInfoCard(
              icon: Icons.blur_circular,
              title: 'PM10',
              subtitle: 'Partículas inaláveis',
              description:
                  'São partículas com diâmetro de até 10 micrômetros. '
                  'Podem ser provenientes de poeira, poluição, '
                  'fumaça e outras fontes.',
              healthEffects:
                  'A exposição pode causar irritação no nariz, '
                  'garganta e vias respiratórias, além de agravar '
                  'alergias e doenças respiratórias preexistentes.',
              healthSource:
                  'OMS – Health consequences of air pollution.',
              unit: 'µg/m³',
              ranges: [
                _range('Boa', 'Até 45', goodColor),
                _range('Moderada', 'Acima de 45 até 100', moderateColor),
                _range('Ruim', 'Acima de 100 até 150', badColor),
                _range('Muito ruim', 'Acima de 150 até 250', veryBadColor),
                _range('Péssima', 'Acima de 250', terribleColor),
              ],
            ),

            const SizedBox(height: 12),

            _buildSectionTitle(
              Icons.refresh,
              'Ventilação',
            ),

            // CO2
            _buildInfoCard(
              icon: Icons.cloud_outlined,
              title: 'CO₂',
              subtitle: 'Dióxido de Carbono',
              description:
                  'O CO₂ é utilizado como indicador indireto da '
                  'ventilação. Concentrações elevadas podem indicar '
                  'pouca renovação do ar em ambientes fechados '
                  'e ocupados.',
              healthEffects:
                  'Concentrações elevadas podem provocar dor de '
                  'cabeça, sonolência, tontura e dificuldade de '
                  'concentração. O aumento do CO₂ também pode '
                  'indicar ventilação insuficiente no ambiente.',
              healthSource:
                  'Health Canada – Residential Indoor Air Quality Guidelines: CO₂.',
              unit: 'ppm',
              ranges: [
                _range('Boa', 'Até 1.000', goodColor),
                _range('Moderada', '1.001 a 2.000', moderateColor),
                _range('Ruim', '2.001 a 5.000', badColor),
                _range('Muito ruim', 'Acima de 5.000', veryBadColor),
              ],
            ),

            const SizedBox(height: 12),

            _buildSectionTitle(
              Icons.thermostat,
              'Conforto ambiental',
            ),

            // Umidade
            _buildInfoCard(
              icon: Icons.water_drop_outlined,
              title: 'Umidade',
              subtitle: 'Umidade relativa do ar',
              description:
                  'A umidade influencia o conforto respiratório '
                  'e ambiental. Valores muito baixos favorecem '
                  'o ressecamento das vias respiratórias, enquanto '
                  'valores elevados favorecem o desenvolvimento '
                  'de mofo e ácaros.',
              healthEffects:
                  'A baixa umidade pode provocar ressecamento dos '
                  'olhos, pele e vias respiratórias. Já a umidade '
                  'excessiva favorece o crescimento de mofo, que '
                  'pode desencadear alergias e agravar problemas '
                  'respiratórios.',
              healthSource:
                  'EPA – Indoor Air Quality: Biological Pollutants.',
              unit: '%',
              ranges: [
                _range('Muito ruim', 'Abaixo de 20%', veryBadColor),
                _range('Ruim', '20% a 29%', badColor),
                _range('Moderada', '30% a 39%', moderateColor),
                _range('Boa', '40% a 60%', goodColor),
                _range('Moderada', '61% a 70%', moderateColor),
                _range('Ruim', '71% a 80%', badColor),
                _range('Muito ruim', 'Acima de 80%', veryBadColor),
              ],
            ),

            // Temperatura
            _buildInfoCard(
              icon: Icons.thermostat_outlined,
              title: 'Temperatura',
              subtitle: 'Indicador de conforto térmico',
              description:
                  'A temperatura influencia diretamente a sensação '
                  'de conforto térmico das pessoas no ambiente. '
                  'Seu monitoramento permite acompanhar as '
                  'condições térmicas do espaço.',
              healthEffects:
                  'Temperaturas muito elevadas podem causar fadiga, '
                  'desidratação e estresse térmico. Temperaturas '
                  'muito baixas podem provocar desconforto térmico. '
                  'Os efeitos dependem da intensidade e do tempo '
                  'de exposição.',
              healthSource:
                  'CDC/NIOSH – Heat-related Illnesses.',
              unit: '°C',
              ranges: [],
            ),

            const SizedBox(height: 12),

            // Informações sobre as classificações
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: primaryColor,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Sobre as classificações',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  Text(
                    'As faixas apresentadas representam os '
                    'critérios de classificação utilizados pelo '
                    'AirShield. Elas ajudam a identificar alterações '
                    'nos parâmetros ambientais e orientam ações '
                    'para melhorar a qualidade do ar e o conforto '
                    'dos ambientes.',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    'As informações sobre saúde possuem caráter '
                    'educativo e não representam diagnóstico médico. '
                    'Os efeitos dependem da concentração, do tempo '
                    'de exposição e das características individuais.',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Center(
              child: Text(
                'AirShield • Respire melhor, viva melhor.',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildSectionTitle(
    IconData icon,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: primaryColor,
            size: 23,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: textColor,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Map<String, dynamic> _range(
    String label,
    String value,
    Color color,
  ) {
    return {
      'label': label,
      'value': value,
      'color': color,
    };
  }

  static Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required String healthEffects,
    required String healthSource,
    required String unit,
    required List<Map<String, dynamic>> ranges,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Descrição
          Text(
            description,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 16),

          // Possíveis efeitos à saúde + fonte
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF292126),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      color: Color(0xFFFF8585),
                      size: 19,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Possíveis efeitos à saúde',
                      style: TextStyle(
                        color: Color(0xFFFF8585),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                Text(
                  healthEffects,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Fonte: $healthSource',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Faixas de classificação
          if (ranges.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Faixas de classificação',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  unit,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ...ranges.map((range) {
              final Color color = range['color'] as Color;

              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        range['label'] as String,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    Text(
                      range['value'] as String,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            Row(
              children: [
                const Icon(
                  Icons.thermostat,
                  color: primaryColor,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Text(
                  'Indicador informativo: $unit',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
