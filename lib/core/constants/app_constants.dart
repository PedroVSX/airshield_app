class AppConstants {
  static const String mqttHost = 'broker.hivemq.com';
  static const int mqttPort = 1883;

  static const String mqttTopicPrefix = 'airshield';
  static const String mqttTopicSuffix = 'dados-ambiente';

  static String deviceTopic(String macAddress) {
    return '$mqttTopicPrefix/$macAddress/$mqttTopicSuffix';
  }
}