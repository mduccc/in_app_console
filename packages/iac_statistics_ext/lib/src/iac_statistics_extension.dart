import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';

/// Sample extension that displays log statistics and analytics.
///
/// This extension demonstrates:
/// - How to implement InAppConsoleExtension
/// - How to access console data via extensionContext
/// - Lifecycle management with onInit/onDispose
/// - Building interactive UI widgets
class LogStatisticsExtension extends InAppConsoleExtension {
  @override
  String get id => 'iac_statistics_ext';

  @override
  String get name => 'Log Statistics';

  @override
  String get version => '1.0.2';

  @override
  String get description => 'View log statistics and analytics';

  @override
  Widget get icon => const Icon(
        Icons.analytics_outlined,
        color: Colors.black,
      );

  late InAppConsoleExtensionContext _extensionContext;

  @override
  void onInit(InAppConsoleExtensionContext extensionContext) {
    _extensionContext = extensionContext;
    debugPrint('[$name] Extension initialized');
  }

  @override
  void onDispose() {
    debugPrint('[$name] Extension disposed');
  }

  @override
  Widget buildWidget(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            // Statistics
            _buildStatistics(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    final logs = _extensionContext.history;

    // Calculate statistics
    final totalLogs = logs.length;
    final infoCount =
        logs.where((log) => log.type == InAppLoggerType.info).length;
    final warningCount =
        logs.where((log) => log.type == InAppLoggerType.warning).length;
    final errorCount =
        logs.where((log) => log.type == InAppLoggerType.error).length;

    // Group by label
    final Map<String, int> labelCounts = {};
    for (var log in logs) {
      final label = log.label ?? 'Unknown';
      labelCounts[label] = (labelCounts[label] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall statistics
        Text(
          'Overall Statistics',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Logs',
                totalLogs.toString(),
                Colors.blue,
                Icons.list,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Info',
                infoCount.toString(),
                Colors.green,
                Icons.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Warnings',
                warningCount.toString(),
                Colors.orange,
                Icons.warning,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Errors',
                errorCount.toString(),
                Colors.red,
                Icons.error,
              ),
            ),
          ],
        ),

        if (labelCounts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Logs by Module',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...labelCounts.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
