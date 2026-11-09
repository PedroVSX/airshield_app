class AppConstants {
  static const String referenceMac = '48:E7:29:B4:5F:4C';

  static const String mqttTopicPrefix = 'airshield';
  static const String mqttTopicSuffix = 'dados-ambiente';

  static String deviceTopic(String macAddress) {
    return '$mqttTopicPrefix/$macAddress/$mqttTopicSuffix';
  }
}
