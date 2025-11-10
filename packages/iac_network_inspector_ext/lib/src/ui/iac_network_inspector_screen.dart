import 'package:flutter/material.dart';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_rs.dart';
import 'package:iac_network_inspector_ext/src/external/iac_network_inspector_ext.dart';
import 'package:iac_network_inspector_ext/src/ui/iac_network_detail_screen.dart';
import 'package:iac_network_inspector_ext/src/ui/widgets/network_list_item.dart';

/// Screen to display list of network requests
class IacNetworkInspectorScreen extends StatefulWidget {
  const IacNetworkInspectorScreen({
    required this.extension,
    super.key,
  });

  final IacNetworkInspectorExt extension;

  @override
  State<IacNetworkInspectorScreen> createState() =>
      _IacNetworkInspectorScreenState();
}

class _IacNetworkInspectorScreenState
    extends State<IacNetworkInspectorScreen> {
  String _searchQuery = '';
  String? _selectedTag;
  String? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Inspector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                widget.extension.clearHistory();
              });
            },
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          Expanded(
            child: StreamBuilder<IacNetworkRS>(
              stream: widget.extension.stream,
              builder: (context, snapshot) {
                final history = widget.extension.history;
                final filteredHistory = _filterHistory(history);

                if (filteredHistory.isEmpty) {
                  return const Center(
                    child: Text('No network requests captured yet'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    final networkData =
                        filteredHistory[filteredHistory.length - 1 - index];
                    return NetworkListItem(
                      networkData: networkData,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => IacNetworkDetailScreen(
                              networkData: networkData,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search URL...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFilters() {
    final allTags = widget.extension.history
        .map((e) => e.dioTag)
        .toSet()
        .toList();
    final allMethods = widget.extension.history
        .map((e) => e.request.method)
        .toSet()
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          if (allTags.isNotEmpty) ...[
            const Text('Tag: '),
            DropdownButton<String?>(
              value: _selectedTag,
              hint: const Text('All'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...allTags.map((tag) => DropdownMenuItem(
                      value: tag,
                      child: Text(tag),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTag = value;
                });
              },
            ),
            const SizedBox(width: 16),
          ],
          if (allMethods.isNotEmpty) ...[
            const Text('Method: '),
            DropdownButton<String?>(
              value: _selectedMethod,
              hint: const Text('All'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...allMethods.map((method) => DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedMethod = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  List<IacNetworkRS> _filterHistory(List<IacNetworkRS> history) {
    return history.where((item) {
      // Filter by search query
      if (_searchQuery.isNotEmpty &&
          !item.url.toLowerCase().contains(_searchQuery)) {
        return false;
      }

      // Filter by tag
      if (_selectedTag != null && item.dioTag != _selectedTag) {
        return false;
      }

      // Filter by method
      if (_selectedMethod != null &&
          item.request.method != _selectedMethod) {
        return false;
      }

      return true;
    }).toList();
  }
}
