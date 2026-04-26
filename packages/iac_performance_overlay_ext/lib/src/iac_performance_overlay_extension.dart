import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'iac_performance_data.dart';
import 'iac_performance_service.dart';

const _prefKey = 'iac_perf_overlay_enabled';

/// In-console extension panel for the performance overlay.
///
/// Register this with [InAppConsole] and pass [overlayVisible] + [service]
/// to [IacPerformanceOverlayWidget] in your app's widget tree:
///
/// ```dart
/// final performanceExt = IacPerformanceOverlayExtension();
/// InAppConsole.instance.registerExtension(performanceExt);
///
/// // In MaterialApp.builder:
/// builder: (context, child) => IacPerformanceOverlayWidget(
///   service: performanceExt.service,
///   overlayVisible: performanceExt.overlayVisible,
///   child: child!,
/// ),
/// ```
class IacPerformanceOverlayExtension extends InAppConsoleExtension {
  IacPerformanceOverlayExtension() : service = IacPerformanceService();

  final IacPerformanceService service;

  /// Whether the draggable overlay is currently shown.
  /// Default is `false` (disabled). Persisted via shared_preferences.
  final ValueNotifier<bool> overlayVisible = ValueNotifier(false);

  @override
  String get id => 'iac_performance_overlay_ext';

  @override
  String get name => 'Performance Overlay';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Real-time FPS, CPU, and memory overlay';

  @override
  Widget get icon =>
      const Icon(Icons.speed_outlined, color: Colors.black);

  @override
  void onInit(InAppConsoleExtensionContext extensionContext) {
    service.start();
    _loadPreference();
  }

  @override
  void onDispose() {
    service.dispose();
    overlayVisible.dispose();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    overlayVisible.value = prefs.getBool(_prefKey) ?? false;
  }

  Future<void> toggleOverlay() async {
    overlayVisible.value = !overlayVisible.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, overlayVisible.value);
  }

  @override
  Widget buildWidget(BuildContext context) {
    return _PerformancePanel(
      service: service,
      overlayVisible: overlayVisible,
      onToggle: toggleOverlay,
    );
  }
}

// ---------------------------------------------------------------------------
// In-console panel UI
// ---------------------------------------------------------------------------

class _PerformancePanel extends StatelessWidget {
  const _PerformancePanel({
    required this.service,
    required this.overlayVisible,
    required this.onToggle,
  });

  final IacPerformanceService service;
  final ValueNotifier<bool> overlayVisible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<IacPerformanceData>(
      stream: service.stream,
      initialData: service.latest,
      builder: (context, snapshot) {
        final data = snapshot.data ?? IacPerformanceData.zero;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(overlayVisible: overlayVisible, onToggle: onToggle),
                const Divider(height: 24),
                _MetricRow(
                  icon: Icons.animation,
                  label: 'FPS',
                  value: data.fpsLabel,
                  subtitle: _fpsDescription(data.fps),
                  color: _fpsColor(data.fps),
                  progress: (data.fps / 60).clamp(0, 1),
                ),
                const SizedBox(height: 12),
                _MetricRow(
                  icon: Icons.memory,
                  label: 'CPU',
                  value: data.cpuLabel,
                  subtitle: _cpuDescription(data.cpuUsage),
                  color: _cpuColor(data.cpuUsage),
                  progress: (data.cpuUsage / 100).clamp(0, 1),
                ),
                const SizedBox(height: 12),
                _MetricRow(
                  icon: Icons.storage,
                  label: 'Memory',
                  value: data.memoryLabel,
                  subtitle: 'App used / Device total',
                  color: Colors.blue,
                  progress: data.totalMemory > 0
                      ? (data.usedMemory / data.totalMemory).clamp(0.0, 1.0)
                      : 0,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fpsDescription(double fps) {
    if (fps >= 55) return 'Smooth';
    if (fps >= 30) return 'Degraded';
    return 'Janky';
  }

  String _cpuDescription(double cpu) {
    if (cpu < 40) return 'Low';
    if (cpu < 70) return 'Moderate';
    return 'High';
  }

  Color _fpsColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 30) return Colors.orange;
    return Colors.red;
  }

  Color _cpuColor(double cpu) {
    if (cpu < 40) return Colors.green;
    if (cpu < 70) return Colors.orange;
    return Colors.red;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.overlayVisible, required this.onToggle});

  final ValueNotifier<bool> overlayVisible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.speed, color: Colors.deepPurple, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Performance Overlay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Updates every second',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: overlayVisible,
          builder: (_, enabled, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                enabled ? 'ON' : 'OFF',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: enabled ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: enabled,
                onChanged: (_) => onToggle(),
                activeThumbColor: Colors.deepPurple,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}
