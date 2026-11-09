import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mqtt/mqtt_service.dart';
import '../../providers/mqtt_provider.dart';

class ConnectionStatus extends ConsumerWidget {
  const ConnectionStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionProvider).asData?.value;
    final live = status?.phase == ConnectionPhase.live;
    final color = live ? const Color(0xFF55D6BE) : const Color(0xFFF2B84B);
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(
            live ? Icons.sensors : Icons.info_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status?.message ?? 'Preparando conexão…',
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
