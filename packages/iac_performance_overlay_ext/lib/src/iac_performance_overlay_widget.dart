import 'package:flutter/material.dart';

import 'iac_performance_data.dart';
import 'iac_performance_service.dart';

/// A draggable always-on-top overlay that shows live FPS, CPU, and memory.
///
/// Pass [IacPerformanceOverlayExtension.overlayVisible] as [overlayVisible]
/// so the widget reacts to toggle changes and persisted preferences
/// automatically.
///
/// ```dart
/// builder: (context, child) => IacPerformanceOverlayWidget(
///   service: performanceExt.service,
///   overlayVisible: performanceExt.overlayVisible,
///   child: child!,
/// ),
/// ```
class IacPerformanceOverlayWidget extends StatefulWidget {
  const IacPerformanceOverlayWidget({
    super.key,
    required this.service,
    required this.overlayVisible,
    required this.child,
  });

  final IacPerformanceService service;

  /// Notifier owned by [IacPerformanceOverlayExtension]. The overlay renders
  /// only when the value is `true`.
  final ValueNotifier<bool> overlayVisible;

  final Widget child;

  @override
  State<IacPerformanceOverlayWidget> createState() =>
      _IacPerformanceOverlayWidgetState();
}

class _IacPerformanceOverlayWidgetState
    extends State<IacPerformanceOverlayWidget> {
  Offset _position = const Offset(8, 100);
  bool _positionInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_positionInitialized) {
      final padding = MediaQuery.of(context).padding;
      _position = Offset(8, padding.top + 8);
      _positionInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.overlayVisible,
        builder: (context, visible, child) {
          if (!visible) return child!;
          return Stack(
            children: [
              child!,
              Positioned(
                left: _position.dx,
                top: _position.dy,
                child: GestureDetector(
                  onPanUpdate: (d) => setState(() => _position += d.delta),
                  child: StreamBuilder<IacPerformanceData>(
                    stream: widget.service.stream,
                    initialData: widget.service.latest,
                    builder: (_, snapshot) => _OverlayPanel(
                      data: snapshot.data ?? IacPerformanceData.zero,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _OverlayPanel extends StatelessWidget {
  const _OverlayPanel({required this.data});

  final IacPerformanceData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatRow(
              label: 'FPS', value: data.fpsLabel, color: _fpsColor(data.fps)),
          const SizedBox(height: 2),
          _StatRow(
              label: 'CPU',
              value: data.cpuLabel,
              color: _cpuColor(data.cpuUsage)),
          const SizedBox(height: 2),
          _StatRow(
              label: 'MEM', value: data.memoryLabel, color: Colors.white70),
        ],
      ),
    );
  }

  Color _fpsColor(double fps) {
    if (fps >= 55) return Colors.greenAccent;
    if (fps >= 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _cpuColor(double cpu) {
    if (cpu < 40) return Colors.greenAccent;
    if (cpu < 70) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
