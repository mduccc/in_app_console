import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:in_app_console/src/core/console/in_app_console_internal.dart';

/// Screen that displays a list of all registered extensions.
class InAppConsoleExtensionsScreen extends StatefulWidget {
  const InAppConsoleExtensionsScreen({super.key});

  @override
  State<InAppConsoleExtensionsScreen> createState() =>
      _InAppConsoleExtensionsScreenState();
}

class _InAppConsoleExtensionsScreenState
    extends State<InAppConsoleExtensionsScreen> {
  final InAppConsoleInternal _console =
      InAppConsole.instance as InAppConsoleInternal;

  @override
  Widget build(BuildContext context) {
    final extensions = _console.getExtensions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extensions'),
        titleSpacing: 0,
      ),
      body: extensions.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              itemCount: extensions.length,
              itemBuilder: (context, index) {
                final extension = extensions[index];
                return _ExtensionTile(
                  extension: extension,
                  index: index + 1,
                  onTap: () => _showExtensionDetails(context, extension),
                );
              },
            ),
    );
  }

  void _showExtensionDetails(
    BuildContext context,
    InAppConsoleExtension extension,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return _ExtensionDetails(
            extension: extension,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.extension_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Extensions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No extensions are currently registered',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtensionTile extends StatelessWidget {
  const _ExtensionTile({
    required this.extension,
    required this.index,
    required this.onTap,
  });

  final InAppConsoleExtension extension;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDescription = extension.description.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Extension icon
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Center(
                  child: SizedBox(width: 28, height: 28, child: extension.icon),
                ),
              ),
              const SizedBox(width: 16),

              // Extension info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      extension.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v${extension.version}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (hasDescription) ...[
                      const SizedBox(height: 8),
                      Text(
                        extension.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExtensionDetails extends StatelessWidget {
  const _ExtensionDetails({
    required this.extension,
    required this.scrollController,
  });

  final InAppConsoleExtension extension;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Extension icon and title
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.white,
                 shape: BoxShape.circle
                ),
                child: Center(
                  child: extension.icon,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      extension.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version ${extension.version}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Extension ID
          _DetailRow(
            label: 'ID',
            value: extension.id,
            icon: Icons.fingerprint,
          ),

          const SizedBox(height: 16),

          // Extension description
          if (extension.description.isNotEmpty) ...[
            _DetailRow(
              label: 'Description',
              value: extension.description,
              icon: Icons.description,
            ),
            const SizedBox(height: 16),
          ],

          // Extension widget preview
          const SizedBox(height: 8),
          Text(
            'Widget Preview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: extension.buildWidget(context),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
