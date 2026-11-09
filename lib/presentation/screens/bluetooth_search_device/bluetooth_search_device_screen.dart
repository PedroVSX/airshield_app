
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:airshield_app/domain/services/saved_devices_service.dart';
import 'package:airshield_app/providers/air_quality_provider.dart';

class BluetoothDevicesScreen extends ConsumerStatefulWidget {
  const BluetoothDevicesScreen({super.key});

  @override
  ConsumerState<BluetoothDevicesScreen> createState() =>
      _BluetoothDevicesScreenState();
}

class _BluetoothDevicesScreenState extends ConsumerState<BluetoothDevicesScreen> {

  static const Color _backgroundColor = Color(0xFF101418);
  static const Color _surfaceColor = Color(0xFF1B2228);
  static const Color _primaryColor = Color(0xFF55D6BE);
  static const Color _textColor = Color(0xFFF1F5F4);
  static const Color _secondaryTextColor = Color(0xFF9AA6AC);

  final Map<String, ScanResult> _devices = {};

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _scanningSubscription;

  bool _isScanning = false;
  String? _errorMessage;

  String? _connectingDevice;
  String? _connectedDevice;

  final SavedDevicesService _savedDevicesService = SavedDevicesService();
  List<Map<String, String>> _savedDevices = [];

  @override
  void initState() {
    super.initState();

    _scanningSubscription =
        FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) {
        setState(() {
          _isScanning = scanning;
        });
      }
    });

    _loadSavedDevices();
  }

  // Inicia o escaneamento BLE.
  Future<void> _startScan() async {
    setState(() {
      _devices.clear();
      _errorMessage = null;
    });

    try {
      final isSupported = await FlutterBluePlus.isSupported;

      if (!isSupported) {
        throw Exception('Este dispositivo não suporta Bluetooth BLE.');
      }

      final adapterState =
          await FlutterBluePlus.adapterState.first;

      if (adapterState != BluetoothAdapterState.on) {
        throw Exception(
          'Ative o Bluetooth do celular para continuar.',
        );
      }

      await _scanSubscription?.cancel();

      _scanSubscription =
          FlutterBluePlus.onScanResults.listen((results) {
        if (!mounted) return;

        setState(() {
          for (final result in results) {
            final name = result.device.platformName.isNotEmpty
                ? result.device.platformName
                : result.advertisementData.advName;

            // Mostra somente dispositivos AirShield.
            if (name.toLowerCase().startsWith('airshield-')) {
              final id = result.device.remoteId.str;

              _devices[id] = result;
            }
          }
        });
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 20),
      );

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  // Interrompe o escaneamento.
  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanningSubscription?.cancel();
    FlutterBluePlus.stopScan();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = _devices.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
  
    return Scaffold(
      backgroundColor: _backgroundColor,
  
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
  
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
  
              const SizedBox(height: 28),
  
              // Busca Bluetooth
              _buildSearchCard(),
  
              const SizedBox(height: 28),
  
              // Dispositivos encontrados
              _buildDevicesHeader(devices.length),
  
              const SizedBox(height: 16),
  
              if (_errorMessage != null)
                _buildError(),
  
              if (devices.isEmpty && _errorMessage == null)
                _buildEmptyState(),
  
              ...devices.map(
                (result) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDeviceCard(result),
                ),
              ),
  
              const SizedBox(height: 32),
  
              // Dispositivos salvos
              _buildSavedDevicesHeader(),
  
              const SizedBox(height: 16),
  
              if (_savedDevices.isEmpty)
                _buildSavedDevicesEmptyState(),
  
              ..._savedDevices.map(
                (device) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSavedDeviceCard(device),
                ),
              ),
  
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Cabeçalho.
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.bluetooth_rounded,
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
                'Dispositivos',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Conecte seu AirShield via Bluetooth',
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Cartão de busca.
  Widget _buildSearchCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isScanning
                    ? Icons.bluetooth_searching_rounded
                    : Icons.bluetooth_rounded,
                color: _primaryColor,
                size: 24,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  _isScanning
                      ? 'Procurando dispositivos...'
                      : 'Busca Bluetooth',
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (_isScanning)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primaryColor,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            'Procure dispositivos AirShield próximos '
            'para identificar seu sensor.',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanning
                  ? _stopScan
                  : _startScan,

              icon: Icon(
                _isScanning
                    ? Icons.stop_rounded
                    : Icons.search_rounded,
              ),

              label: Text(
                _isScanning
                    ? 'Interromper busca'
                    : 'Procurar dispositivos',
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: _backgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Título da lista.
  Widget _buildDevicesHeader(int count) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Dispositivos encontrados',
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count encontrados',
            style: const TextStyle(
              color: _primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Cartão de cada ESP32.
  Widget _buildDeviceCard(ScanResult result) {
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : result.advertisementData.advName;

    final macAddress = name.substring('airshield-'.length);

    final isConnecting = _connectingDevice == macAddress;
    final isConnected = _connectedDevice == macAddress;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isConnecting
          ? null
          : () => _connectToDevice(result),

      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isConnected
                ? _primaryColor
                : _primaryColor.withValues(alpha: 0.15),
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.developer_board_rounded,
                color: _primaryColor,
                size: 25,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AirShield ESP32',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    macAddress,
                    style: const TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [
                      const Icon(
                        Icons.wifi_rounded,
                        size: 14,
                        color: _primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${result.rssi} dBm',
                        style: const TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isConnecting)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primaryColor,
                ),
              )
            else if (isConnected)
              const Icon(
                Icons.check_circle_rounded,
                color: _primaryColor,
                size: 24,
              )
            else
              const Icon(
                Icons.bluetooth_rounded,
                color: _primaryColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  // Estado vazio.
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 38,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bluetooth_searching_rounded,
            size: 48,
            color: _secondaryTextColor.withValues(alpha: 0.6),
          ),

          const SizedBox(height: 16),

          Text(
            _isScanning
                ? 'Procurando AirShield...'
                : 'Nenhum dispositivo encontrado',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _isScanning
                ? 'Aguarde enquanto procuramos dispositivos próximos.'
                : 'Toque em procurar dispositivos para iniciar uma busca.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Erro de Bluetooth.
  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF30291D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFF2B84B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFF2B84B),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedDevicesHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Meus dispositivos',
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_savedDevices.length} salvos',
            style: const TextStyle(
              color: _primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedDeviceCard(Map<String, String> device) {
    final name = device['name'] ?? 'AirShield ESP32';
    final macAddress = device['mac'] ?? '';

    final isConnected = _connectedDevice == macAddress;
    final isConnecting = _connectingDevice == macAddress;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isConnecting
          ? null
          : () => _connectSavedDevice(macAddress),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isConnected
                ? _primaryColor
                : _primaryColor.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.developer_board_rounded,
                color: _primaryColor,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: _textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    macAddress,
                    style: const TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isConnected
                        ? 'Selecionado para monitoramento'
                        : 'Dispositivo salvo',
                    style: TextStyle(
                      color: isConnected
                          ? _primaryColor
                          : _secondaryTextColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _renameDevice(device),
              icon: const Icon(
                Icons.edit_rounded,
                color: _primaryColor,
                size: 20,
              ),
              tooltip: 'Renomear dispositivo',
            ),
            if (isConnecting)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primaryColor,
                ),
              )
            else
              Icon(
                isConnected
                    ? Icons.check_circle_rounded
                    : Icons.cloud_sync_rounded,
                color: _primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedDevicesEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.devices_other_rounded,
            size: 40,
            color: _secondaryTextColor,
          ),

          SizedBox(height: 12),

          Text(
            'Nenhum dispositivo salvo',
            style: TextStyle(
              color: _textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Procure seu AirShield e selecione um dispositivo para salvá-lo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _connectToDevice(ScanResult result) async {
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : result.advertisementData.advName;

    if (!name.toLowerCase().startsWith('airshield-')) return;

    final macAddress = name.substring('airshield-'.length);

    await _selectDevice(macAddress);

    if (!mounted) return;

    await _saveDevice(result);
  }

  Future<void> _connectSavedDevice(String macAddress) async {
    if (macAddress.isEmpty) {
      setState(() {
        _errorMessage = 'MAC do dispositivo não encontrado.';
      });
      return;
    }

    await _selectDevice(macAddress);
  }

  Future<void> _selectDevice(String macAddress) async {
    setState(() {
      _connectingDevice = macAddress;
      _errorMessage = null;
    });

    try {
      // Seleciona o dispositivo no Riverpod.
      // O airQualityStreamProvider inicia a conexão MQTT.
      ref
          .read(selectedAirShieldMacProvider.notifier)
          .selectDevice(macAddress);

      if (!mounted) return;

      setState(() {
        _connectedDevice = null;
        _connectingDevice = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AirShield $macAddress selecionado!'),
          backgroundColor: const Color(0xFF29453F),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _connectingDevice = null;
        _errorMessage = 'Erro ao selecionar dispositivo: $e';
      });
    }
  }


  Future<void> _saveDevice(ScanResult result) async {
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : result.advertisementData.advName;

    if (!name.toLowerCase().startsWith('airshield-')) return;

    final macAddress = name.substring('airshield-'.length).trim();

    print('Nome Bluetooth: $name');
    print('MAC extraído: $macAddress');

    await _savedDevicesService.saveDevice(name, macAddress);

    await _loadSavedDevices();
  }
  
  Future<void> _loadSavedDevices() async {
    final devices = await _savedDevicesService.getDevices();

    if (!mounted) return;

    setState(() {
      _savedDevices = devices;
    });
  }

  Future<void> _renameDevice(Map<String, String> device) async {
    final mac = device['mac'] ?? '';
  
    final controller = TextEditingController(
      text: device['name'] ?? '',
    );
  
    try {
      final newName = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: _surfaceColor,
            title: const Text(
              'Renomear dispositivo',
              style: TextStyle(color: _textColor),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: _textColor),
              decoration: InputDecoration(
                hintText: 'Nome do dispositivo',
                hintStyle: const TextStyle(
                  color: _secondaryTextColor,
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _primaryColor),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _primaryColor),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: _secondaryTextColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    controller.text.trim(),
                  );
                },
                child: const Text(
                  'Salvar',
                  style: TextStyle(color: _primaryColor),
                ),
              ),
            ],
          );
        },
      );
  
      if (!mounted || newName == null || newName.isEmpty || mac.isEmpty) {
        return;
      }
  
      await _savedDevicesService.renameDevice(mac, newName);
  
      if (!mounted) return;
  
      await _loadSavedDevices();
    } finally {
      controller.dispose();
    }
  }
}