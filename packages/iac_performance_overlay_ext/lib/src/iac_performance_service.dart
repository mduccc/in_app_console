import 'dart:async';

import 'package:flutter/scheduler.dart';

import '../iac_performance_overlay_ext_platform_interface.dart';
import 'iac_performance_data.dart';

/// Tracks FPS, CPU, and memory in real time.
///
/// FPS is measured by driving a continuous post-frame callback loop so that
/// idle frames are still counted — identical to Flutter's own PerformanceOverlay
/// approach. Without this, Flutter stops rendering when the app is static and
/// the counter would incorrectly read 0–1 fps.
class IacPerformanceService {
  final _controller = StreamController<IacPerformanceData>.broadcast();

  Stream<IacPerformanceData> get stream => _controller.stream;

  IacPerformanceData _latest = IacPerformanceData.zero;
  IacPerformanceData get latest => _latest;

  Timer? _pollTimer;
  bool _running = false;
  int _frameCount = 0;

  void start() {
    if (_running) return;
    _running = true;
    _scheduleNextFrame();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void stop() {
    _running = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }

  // ---------------------------------------------------------------------------
  // FPS — continuous frame loop
  // ---------------------------------------------------------------------------

  void _scheduleNextFrame() {
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    SchedulerBinding.instance.scheduleFrame();
  }

  void _onFrame(Duration _) {
    if (!_running) return;
    _frameCount++;
    _scheduleNextFrame();
  }

  // ---------------------------------------------------------------------------
  // CPU + memory — polled once per second
  // ---------------------------------------------------------------------------

  Future<void> _onTick(Timer _) async {
    final fps = _frameCount.toDouble();
    _frameCount = 0;

    final platform = IacPerformanceOverlayExtPlatform.instance;
    final cpuUsage = await platform.getCpuUsage() ?? 0;
    final memInfo = await platform.getMemoryInfo();

    _latest = IacPerformanceData(
      fps: fps,
      cpuUsage: cpuUsage,
      usedMemory: memInfo?['usedMem'] ?? 0,
      totalMemory: memInfo?['totalMem'] ?? 0,
    );

    if (!_controller.isClosed) {
      _controller.add(_latest);
    }
  }
}
