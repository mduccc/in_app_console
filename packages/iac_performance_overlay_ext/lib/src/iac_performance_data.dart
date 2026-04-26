class IacPerformanceData {
  const IacPerformanceData({
    required this.fps,
    required this.cpuUsage,
    required this.usedMemory,
    required this.totalMemory,
  });

  /// Frames per second (0–60+).
  final double fps;

  /// CPU usage percentage (0–100).
  final double cpuUsage;

  /// App memory in use, in bytes.
  final int usedMemory;

  /// Total device memory, in bytes.
  final int totalMemory;

  static const zero = IacPerformanceData(
    fps: 0,
    cpuUsage: 0,
    usedMemory: 0,
    totalMemory: 0,
  );

  String get fpsLabel => fps.toStringAsFixed(0);

  String get cpuLabel => '${cpuUsage.toStringAsFixed(1)}%';

  String get memoryLabel {
    final used = _formatBytes(usedMemory);
    final total = _formatBytes(totalMemory);
    return '$used / $total';
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}
