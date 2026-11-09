import 'dart:async';

import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';

import '../../../data/ble/ble_identity_service.dart';

class BlePairingScreen extends StatefulWidget {
  const BlePairingScreen({super.key, this.service});
  final BleIdentityService? service;
  @override
  State<BlePairingScreen> createState() => _BlePairingScreenState();
}

class _BlePairingScreenState extends State<BlePairingScreen> {
  late final BleIdentityService _service =
      widget.service ?? BleIdentityService();
  final _devices = <String, BleDevice>{};
  StreamSubscription<BleDevice>? _subscription;
  Timer? _scanTimer;
  bool _scanning = false;
  bool _reading = false;
  String? _message;

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _devices.clear();
      _message = null;
    });
    await _subscription?.cancel();
    if (!mounted) return;
    _subscription = _service.devices.listen(
      (device) {
        if (mounted) setState(() => _devices[device.deviceId] = device);
      },
      onError: (Object _) {
        _showError();
      },
    );
    try {
      await _service.startScan();
      if (!mounted) return;
      _scanTimer?.cancel();
      _scanTimer = Timer(const Duration(seconds: 15), _stopScan);
    } catch (_) {
      _showError();
    }
  }

  Future<void> _stopScan() async {
    _scanTimer?.cancel();
    try {
      await _service.stopScan();
    } catch (_) {
      /* Already stopped. */
    }
    if (mounted) {
      setState(() {
        _scanning = false;
        if (_devices.isEmpty) {
          _message =
              'Nenhum AirShield encontrado. '
              'Aproxime o ESP32 e confirme se o firmware anuncia o serviço BLE AirShield.';
        }
      });
    }
  }

  void _showError() {
    _scanTimer?.cancel();
    unawaited(_service.stopScan().catchError((Object _) {}));
    if (mounted) {
      setState(() {
        _scanning = false;
        _message =
            'Não foi possível usar o Bluetooth. Ative-o e permita o acesso '
            'nas configurações do sistema. No navegador, use HTTPS/localhost e '
            'um navegador com Web Bluetooth.';
      });
    }
  }

  Future<void> _select(BleDevice device) async {
    _scanTimer?.cancel();
    setState(() {
      _reading = true;
      _message = 'Lendo identificador do ESP32…';
    });
    try {
      final mac = await _service.readIdentity(device.deviceId);
      if (mounted) Navigator.pop(context, mac);
    } catch (_) {
      if (mounted) {
        setState(() {
          _reading = false;
          _scanning = false;
          _message =
              'Não foi possível ler o identificador. Confirme a proximidade '
              'e a implementação do serviço/característica BLE no firmware.';
        });
      }
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(_service.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Identificar AirShield')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Selecione seu ESP32 para ler o identificador Wi-Fi e conectar '
          'ao tópico de telemetria. O firmware precisa implementar o contrato '
          'BLE AirShield; esse recurso ainda precisa ser integrado ao ESP32.',
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _reading
              ? null
              : _scanning
              ? _stopScan
              : _scan,
          icon: Icon(_scanning ? Icons.stop : Icons.bluetooth_searching),
          label: Text(_scanning ? 'Parar busca' : 'Buscar dispositivos'),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(_message!),
          ),
        for (final device in _devices.values)
          ListTile(
            leading: const Icon(Icons.bluetooth),
            title: Text(
              device.name?.isNotEmpty == true ? device.name! : 'AirShield',
            ),
            subtitle: const Text('Ler identificador e conectar'),
            onTap: _reading ? null : () => _select(device),
          ),
      ],
    ),
  );
}
