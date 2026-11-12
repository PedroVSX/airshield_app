enum AirQuality {
  boa,
  moderada,
  ruim,
  muitoRuim,
  pessima;

  static AirQuality fromJson(dynamic value) {
    if (value is int && value >= 0 && value < AirQuality.values.length) {
      return AirQuality.values[value];
    }

    if (value is String) {
      final normalized = value.toUpperCase();

      switch (normalized) {
        case 'BOA':
          return AirQuality.boa;
        case 'MODERADA':
          return AirQuality.moderada;
        case 'RUIM':
          return AirQuality.ruim;
        case 'MUITO_RUIM':
          return AirQuality.muitoRuim;
        case 'PESSIMA':
          return AirQuality.pessima;
      }
    }

    throw FormatException('Classificação de qualidade inválida: $value');
  }

  String get label {
    switch (this) {
      case AirQuality.boa:
        return 'Boa';
      case AirQuality.moderada:
        return 'Moderada';
      case AirQuality.ruim:
        return 'Ruim';
      case AirQuality.muitoRuim:
        return 'Muito ruim';
      case AirQuality.pessima:
        return 'Péssima';
    }
  }
}