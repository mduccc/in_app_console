import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'iac_device_info_model.dart';

class IacDeviceInfoWidget extends StatefulWidget {
  const IacDeviceInfoWidget({super.key, required this.deviceInfoFuture});

  final Future<IacDeviceInfoModel> deviceInfoFuture;

  @override
  State<IacDeviceInfoWidget> createState() => _IacDeviceInfoWidgetState();
}

class _IacDeviceInfoWidgetState extends State<IacDeviceInfoWidget> {
  bool _copied = false;

  Future<void> _copyToClipboard(IacDeviceInfoModel model) async {
    final size = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final physicalWidth = (size.width * ratio).toStringAsFixed(0);
    final physicalHeight = (size.height * ratio).toStringAsFixed(0);

    final text = model.toFormattedString(
      screenResolution: '$physicalWidth x $physicalHeight px (${size.width.toStringAsFixed(0)} x ${size.height.toStringAsFixed(0)} logical)',
      pixelRatio: ratio.toStringAsFixed(2),
    );
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IacDeviceInfoModel>(
      future: widget.deviceInfoFuture,
      builder: (context, snapshot) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const Divider(height: 24),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  _buildError(snapshot.error)
                else if (snapshot.hasData)
                  _buildInfo(snapshot.data!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.phone_android, color: Colors.indigo, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Hardware & system information',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError(Object? error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Failed to load device info: $error',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(IacDeviceInfoModel model) {
    final size = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final physicalWidth = (size.width * ratio).toStringAsFixed(0);
    final physicalHeight = (size.height * ratio).toStringAsFixed(0);

    final isAndroid = model.platform == 'Android';

    return Column(
      children: [
        _buildRow(
          icon: isAndroid ? Icons.android : Icons.apple,
          iconColor: isAndroid ? Colors.green : Colors.grey[800]!,
          label: 'Platform',
          value: model.platform,
        ),
        _buildRow(
          icon: Icons.system_update_alt,
          label: 'OS Version',
          value: model.osVersion,
        ),
        _buildRow(
          icon: Icons.devices,
          label: 'Model',
          value: model.model,
        ),
        if (model.manufacturer.isNotEmpty)
          _buildRow(
            icon: Icons.business,
            label: 'Manufacturer',
            value: model.manufacturer,
          ),
        _buildRow(
          icon: Icons.memory,
          label: 'Architecture',
          value: model.architecture,
        ),
        _buildRow(
          icon: Icons.storage,
          label: 'Total RAM',
          value: model.totalRam,
        ),
        _buildRow(
          icon: Icons.stay_current_portrait,
          label: 'Screen',
          value: '${physicalWidth}x$physicalHeight px',
        ),
        _buildRow(
          icon: Icons.grid_on,
          label: 'Logical Size',
          value: '${size.width.toStringAsFixed(0)}x${size.height.toStringAsFixed(0)} dp',
        ),
        _buildRow(
          icon: Icons.hd,
          label: 'Pixel Ratio',
          value: ratio.toStringAsFixed(2),
        ),
        if (model.additionalInfo != null)
          _buildRow(
            icon: Icons.info_outline,
            label: 'Additional',
            value: model.additionalInfo!,
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _copyToClipboard(model),
            icon: Icon(_copied ? Icons.check : Icons.copy, size: 18),
            label: Text(_copied ? 'Copied!' : 'Copy to Clipboard'),
          ),
        ),
      ],
    );
  }

  Widget _buildRow({
    required IconData icon,
    Color? iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor ?? Colors.grey[600]),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
