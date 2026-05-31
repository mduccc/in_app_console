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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Extensions',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey[200]),
        ),
      ),
      body: extensions.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.85,
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
          Icon(Icons.extension_off_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No extensions registered',
            style: TextStyle(fontSize: 15, color: Colors.grey[400]),
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

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[100]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Center(
                child: SizedBox(width: 22, height: 22, child: extension.icon),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    extension.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDescription ? extension.description : '--',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[300], size: 18),
          ],
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
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Center(child: extension.icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        extension.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'v${extension.version}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 20),
            _DetailRow(
                label: 'ID', value: extension.id, icon: Icons.fingerprint),
            if (extension.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DetailRow(
                  label: 'Description',
                  value: extension.description,
                  icon: Icons.description_outlined),
            ],
            const SizedBox(height: 20),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 16),
            extension.buildWidget(context),
          ],
        ),
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
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
