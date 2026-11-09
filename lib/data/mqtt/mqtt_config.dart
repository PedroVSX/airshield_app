import '../../core/constants/app_constants.dart';

enum MqttTransport { tcp, tls, ws, wss }

enum TopicFormat { mac, legacyDeviceId }

class MqttConfig {
  const MqttConfig({
    this.host = 'broker.emqx.io',
    this.port = 1883,
    this.macAddress = AppConstants.referenceMac,
    this.transport = MqttTransport.tcp,
    this.webSocketPath = '/mqtt',
    this.username = '',
    this.password = '',
    this.demo = false,
    this.staleSeconds = 60,
    this.connectOnStart = true,
    this.topicFormat = TopicFormat.mac,
  });

  final String host;
  final int port;
  final String macAddress;
  final MqttTransport transport;
  final String webSocketPath;
  final String username;
  // Session only: never serialized to preferences or logs.
  final String password;
  final bool demo;
  final int staleSeconds;
  final bool connectOnStart;
  final TopicFormat topicFormat;

  bool get usesWebSocket =>
      transport == MqttTransport.ws || transport == MqttTransport.wss;
  String get topic => AppConstants.deviceTopic(
    topicFormat == TopicFormat.mac
        ? macAddress
        : 'dispositivo-${macAddress.replaceAll(':', '')}',
  );
  String get historyKey => demo
      ? 'airshield_history_v2_demo'
      : 'airshield_history_v2_${Uri.encodeComponent('$host:$port/$username/$topic')}';

  String? validate({bool isWeb = false}) {
    if (demo) return null;
    if (host.trim().isEmpty ||
        host != host.trim() ||
        RegExp(r'[\s/?#@]').hasMatch(host) ||
        host.contains('://')) {
      return 'Informe o host/IP do broker, sem protocolo, porta ou caminho.';
    }
    if (host.contains(':') && !(host.startsWith('[') && host.endsWith(']'))) {
      return 'Informe a porta no campo Porta; use colchetes para IPv6.';
    }
    if (port < 1 || port > 65535) return 'A porta deve estar entre 1 e 65535.';
    if (!RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$').hasMatch(macAddress)) {
      return 'Informe o MAC no formato 48:E7:29:B4:5F:4C.';
    }
    if (isWeb && !usesWebSocket) {
      return 'No navegador, selecione WS ou WSS e a porta WebSocket do broker.';
    }
    if (usesWebSocket &&
        (!webSocketPath.startsWith('/') ||
            RegExp(r'[\s?#]').hasMatch(webSocketPath))) {
      return 'O caminho WebSocket deve começar com / e não conter espaços.';
    }
    if (staleSeconds < 10 || staleSeconds > 3600) {
      return 'O limite sem dados deve estar entre 10 e 3600 segundos.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'host': host,
    'port': port,
    'mac': macAddress,
    'transport': transport.name,
    'webSocketPath': webSocketPath,
    'username': username,
    'demo': demo,
    'staleSeconds': staleSeconds,
    'topicFormat': topicFormat.name,
  };

  factory MqttConfig.fromJson(Map<String, dynamic> json) => MqttConfig(
    host: json['host'] as String? ?? '',
    port: json['port'] as int? ?? 1883,
    macAddress: json['mac'] as String? ?? AppConstants.referenceMac,
    transport: MqttTransport.values.firstWhere(
      (value) => value.name == json['transport'],
      orElse: () => MqttTransport.tcp,
    ),
    webSocketPath: json['webSocketPath'] as String? ?? '/mqtt',
    username: json['username'] as String? ?? '',
    demo: json['demo'] == true,
    staleSeconds: json['staleSeconds'] as int? ?? 60,
    connectOnStart:
        json['demo'] == true || (json['username'] as String? ?? '').isEmpty,
    topicFormat: json['topicFormat'] == TopicFormat.legacyDeviceId.name
        ? TopicFormat.legacyDeviceId
        : TopicFormat.mac,
  );
}
