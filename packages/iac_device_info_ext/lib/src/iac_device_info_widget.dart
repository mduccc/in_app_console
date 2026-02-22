import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'iac_device_info_model.dart';

class IacDeviceInfoWidget extends StatelessWidget {
  const IacDeviceInfoWidget({super.key, required this.deviceInfoFuture});

  final Future<IacDeviceInfoModel> deviceInfoFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IacDeviceInfoModel>(
      future: deviceInfoFuture,
      builder: (context, snapshot) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(),
                const Divider(height: 24),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  _ErrorView(error: snapshot.error)
                else if (snapshot.hasData)
                  _InfoView(model: snapshot.data!),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
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
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
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
}

class _InfoView extends StatefulWidget {
  const _InfoView({required this.model});

  final IacDeviceInfoModel model;

  @override
  State<_InfoView> createState() => _InfoViewState();
}

class _InfoViewState extends State<_InfoView> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    final size = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final physicalWidth = (size.width * ratio).toStringAsFixed(0);
    final physicalHeight = (size.height * ratio).toStringAsFixed(0);

    final text = widget.model.toFormattedString(
      screenResolution:
          '$physicalWidth x $physicalHeight px (${size.width.toStringAsFixed(0)} x ${size.height.toStringAsFixed(0)} logical)',
      pixelRatio: ratio.toStringAsFixed(2),
    );
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final physicalWidth = (size.width * ratio).toStringAsFixed(0);
    final physicalHeight = (size.height * ratio).toStringAsFixed(0);
    final isAndroid = widget.model.platform == 'Android';

    return Column(
      children: [
        _InfoRow(
          icon: isAndroid ? Icons.android : Icons.apple,
          iconColor: isAndroid ? Colors.green : Colors.grey[800]!,
          label: 'Platform',
          value: widget.model.platform,
        ),
        _InfoRow(
          icon: Icons.system_update_alt,
          label: 'OS Version',
          value: widget.model.osVersion,
        ),
        _InfoRow(
          icon: Icons.devices,
          label: 'Model',
          value: widget.model.model,
        ),
        if (widget.model.manufacturer.isNotEmpty)
          _InfoRow(
            icon: Icons.business,
            label: 'Manufacturer',
            value: widget.model.manufacturer,
          ),
        _InfoRow(
          icon: Icons.memory,
          label: 'Architecture',
          value: widget.model.architecture,
        ),
        _InfoRow(
          icon: Icons.storage,
          label: 'Total RAM',
          value: widget.model.totalRam,
        ),
        _InfoRow(
          icon: Icons.stay_current_portrait,
          label: 'Screen',
          value: '${physicalWidth}x$physicalHeight px',
        ),
        _InfoRow(
          icon: Icons.grid_on,
          label: 'Logical Size',
          value:
              '${size.width.toStringAsFixed(0)}x${size.height.toStringAsFixed(0)} dp',
        ),
        _InfoRow(
          icon: Icons.hd,
          label: 'Pixel Ratio',
          value: ratio.toStringAsFixed(2),
        ),
        if (widget.model.additionalInfo != null)
          _InfoRow(
            icon: Icons.info_outline,
            label: 'Additional',
            value: widget.model.additionalInfo!,
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _copyToClipboard,
            icon: Icon(_copied ? Icons.check : Icons.copy, size: 18),
            label: Text(_copied ? 'Copied!' : 'Copy to Clipboard'),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
