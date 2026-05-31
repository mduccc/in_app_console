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

class _IacNetworkInspectorScreenState extends State<IacNetworkInspectorScreen> {
  String _searchQuery = '';
  String? _selectedTag;
  String? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Network Inspector',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey[200]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => widget.extension.clearHistory()),
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
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_outlined,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'No requests captured yet',
                          style:
                              TextStyle(fontSize: 15, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: TextField(
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search URL...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final allTags =
        widget.extension.history.map((e) => e.dioTag).toSet().toList();
    final allMethods =
        widget.extension.history.map((e) => e.request.method).toSet().toList();

    if (allTags.isEmpty && allMethods.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      color: Colors.white,
      child: Row(
        children: [
          if (allTags.isNotEmpty) ...[
            Text('Tag: ',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            DropdownButton<String?>(
              value: _selectedTag,
              hint: Text('All',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              underline: const SizedBox.shrink(),
              isDense: true,
              dropdownColor: Colors.white,
              items: [
                DropdownMenuItem(
                    value: null,
                    child: Text('All',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600]))),
                ...allTags.map((tag) => DropdownMenuItem(
                      value: tag,
                      child: Text(tag, style: const TextStyle(fontSize: 13)),
                    )),
              ],
              onChanged: (value) => setState(() => _selectedTag = value),
            ),
            const SizedBox(width: 16),
          ],
          if (allMethods.isNotEmpty) ...[
            Text('Method: ',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            DropdownButton<String?>(
              value: _selectedMethod,
              hint: Text('All',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              underline: const SizedBox.shrink(),
              isDense: true,
              dropdownColor: Colors.white,
              items: [
                DropdownMenuItem(
                    value: null,
                    child: Text('All',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600]))),
                ...allMethods.map((method) => DropdownMenuItem(
                      value: method,
                      child: Text(method, style: const TextStyle(fontSize: 13)),
                    )),
              ],
              onChanged: (value) => setState(() => _selectedMethod = value),
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
      if (_selectedMethod != null && item.request.method != _selectedMethod) {
        return false;
      }

      return true;
    }).toList();
  }
}
