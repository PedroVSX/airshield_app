import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mqtt/mqtt_config.dart';
import '../../../providers/mqtt_provider.dart';
import '../../../providers/settings_provider.dart';
import 'ble_pairing_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _host,
      _port,
      _mac,
      _path,
      _username,
      _password,
      _stale;
  late MqttTransport _transport;
  late TopicFormat _topicFormat;
  late bool _demo;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final config = ref.read(settingsProvider);
    _host = TextEditingController(text: config.host);
    _port = TextEditingController(text: '${config.port}');
    _mac = TextEditingController(text: config.macAddress);
    _path = TextEditingController(text: config.webSocketPath);
    _username = TextEditingController(text: config.username);
    _password = TextEditingController(text: config.password);
    _stale = TextEditingController(text: '${config.staleSeconds}');
    _transport = config.transport;
    _topicFormat = config.topicFormat;
    _demo = config.demo;
    _mac.addListener(_refreshTopic);
  }

  void _refreshTopic() => setState(() {});

  Future<void> _identify() async {
    final mac = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const BlePairingScreen()));
    if (!mounted || mac == null) return;
    _mac.text = mac;
    await _save();
  }

  @override
  void dispose() {
    for (final controller in [
      _host,
      _port,
      _mac,
      _path,
      _username,
      _password,
      _stale,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final config = MqttConfig(
      host: _host.text.trim(),
      port: int.tryParse(_port.text) ?? 0,
      macAddress: _mac.text.trim(),
      transport: _transport,
      webSocketPath: _path.text.trim(),
      username: _username.text.trim(),
      password: _password.text,
      demo: _demo,
      staleSeconds: int.tryParse(_stale.text) ?? 0,
      topicFormat: _topicFormat,
    );
    final issue = config.validate(isWeb: kIsWeb);
    if (issue != null) {
      setState(() => _error = issue);
      return;
    }
    if (kIsWeb &&
        Uri.base.scheme == 'https' &&
        _transport == MqttTransport.ws &&
        !_demo) {
      setState(
        () => _error = 'Esta página usa HTTPS. Selecione WSS para conectar.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(settingsProvider.notifier).save(config);
      if (!mounted) return;
      // Reading creates the new service immediately; it connects in a microtask.
      ref.read(mqttServiceProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configuração salva. Acompanhe o estado da conexão acima.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível salvar. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    bool secret = false,
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      enabled: !_demo && !_saving,
      obscureText: secret,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        helperText: hint,
        helperMaxLines: 3,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Configure o Wi-Fi do ESP32',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const SelectableText(
              'Nas configurações de Wi-Fi do celular, conecte à rede '
              'airshield_48:E7:29:B4:5F:4C (ou à rede do seu dispositivo). '
              'Senha do ponto de acesso: 12345678.\n\n'
              'Abra http://192.168.4.1 no navegador. O firmware também anuncia '
              'http://airshield.com. Configure a rede do ESP32 pelo portal. '
              'Depois, volte à rede que alcança o broker MQTT.\n\n'
              'Esse portal configura o dispositivo. O endereço do broker precisa '
              'ser o mesmo usado no código do ESP32.',
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  const ClipboardData(text: 'http://192.168.4.1'),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Endereço do portal copiado.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar endereço do portal'),
            ),
            const SizedBox(height: 20),
            const Text(
              '2. Conecte aos dados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Modo demonstração'),
              subtitle: const Text(
                'Gera dados simulados em um histórico separado.',
              ),
              value: _demo,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _demo = value),
            ),
            const SizedBox(height: 12),
            _field(
              'Host/IP do broker MQTT',
              _host,
              hint: 'Informe o servidor do firmware. Sem http:// ou mqtt://.',
            ),
            DropdownButtonFormField<MqttTransport>(
              initialValue: _transport,
              decoration: const InputDecoration(
                labelText: 'Transporte',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: MqttTransport.tcp,
                  child: Text('MQTT / TCP'),
                ),
                DropdownMenuItem(
                  value: MqttTransport.tls,
                  child: Text('MQTT / TLS'),
                ),
                DropdownMenuItem(
                  value: MqttTransport.ws,
                  child: Text('WebSocket (WS)'),
                ),
                DropdownMenuItem(
                  value: MqttTransport.wss,
                  child: Text('WebSocket seguro (WSS)'),
                ),
              ],
              onChanged: _demo || _saving
                  ? null
                  : (value) => setState(() {
                      _transport = value!;
                      if (_host.text.trim() == 'broker.emqx.io') {
                        _port.text = switch (value) {
                          MqttTransport.tcp => '1883',
                          MqttTransport.tls => '8883',
                          MqttTransport.ws => '8083',
                          MqttTransport.wss => '8084',
                        };
                      }
                    }),
            ),
            const SizedBox(height: 16),
            _field(
              'Porta',
              _port,
              number: true,
              hint: 'Use a porta do transporte escolhido no broker.',
            ),
            if (_transport == MqttTransport.ws ||
                _transport == MqttTransport.wss)
              _field(
                'Caminho WebSocket',
                _path,
                hint: 'Confirme no broker; exemplo: /mqtt.',
              ),
            _field(
              'MAC do dispositivo',
              _mac,
              hint: 'Copie exatamente do tópico do firmware, inclusive maiúsculas/minúsculas.',
            ),
            DropdownButtonFormField<TopicFormat>(
              initialValue: _topicFormat,
              decoration: const InputDecoration(
                labelText: 'Formato do tópico',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: TopicFormat.mac,
                  child: Text('Atual: MAC com dois-pontos'),
                ),
                DropdownMenuItem(
                  value: TopicFormat.legacyDeviceId,
                  child: Text('Antigo: dispositivo-ID'),
                ),
              ],
              onChanged: _demo || _saving
                  ? null
                  : (value) => setState(() => _topicFormat = value!),
            ),
            const SizedBox(height: 12),
            SelectableText(
              MqttConfig(
                macAddress: _mac.text.trim(),
                topicFormat: _topicFormat,
              ).topic,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _demo || _saving ? null : _identify,
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Identificar e conectar via Bluetooth'),
            ),
            const SizedBox(height: 16),
            _field('Usuário MQTT (opcional)', _username),
            _field(
              'Senha MQTT (opcional)',
              _password,
              secret: true,
              hint: 'Mantida só nesta sessão. Não é a senha do Wi-Fi do ESP32.',
            ),
            _field(
              'Avisar após quantos segundos sem dados?',
              _stale,
              number: true,
            ),
            const Text(
              'Use o formato de tópico da versão do seu firmware. '
              'Os códigos de qualidade são exibidos como enviados; a escala e '
              'as unidades COV/PM precisam ser confirmadas com o firmware.',
            ),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'No navegador, o broker precisa oferecer WS/WSS. '
                  'Uma página HTTPS exige WSS.',
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.link),
                  label: Text(_saving ? 'Salvando…' : 'Salvar e conectar'),
                ),
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => ref.read(mqttServiceProvider).disconnect(),
                  child: const Text('Desconectar'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
