import 'package:flutter/material.dart';

import 'iac_route_tracker_navigation_observer.dart';

class IacRouteTrackerWidget extends StatefulWidget {
  const IacRouteTrackerWidget({super.key, required this.observer});

  final IacRouteTrackerNavigationObserver observer;

  @override
  State<IacRouteTrackerWidget> createState() => _IacRouteTrackerWidgetState();
}

class _IacRouteTrackerWidgetState extends State<IacRouteTrackerWidget> {
  late String _currentDeepLink;
  late String _previousDeepLink;
  late List<String> _routeStack;

  @override
  void initState() {
    super.initState();
    _currentDeepLink = widget.observer.currentDeepLink;
    _previousDeepLink = widget.observer.previousDeepLink;
    _routeStack = widget.observer.routeStack;

    widget.observer.routeStackStream.listen((stack) {
      debugPrint('[RouteTrackerWidget] routeStackStream emitted new stack: $stack');
      if (!mounted) return;
      setState(() {
        _routeStack = stack;
        _currentDeepLink = widget.observer.currentDeepLink;
        _previousDeepLink = widget.observer.previousDeepLink;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 24),
            _buildDeepLinkRow(
              label: 'Current',
              value: _currentDeepLink,
              color: Colors.blue,
              icon: Icons.location_on,
            ),
            const SizedBox(height: 8),
            _buildDeepLinkRow(
              label: 'Previous',
              value: _previousDeepLink,
              color: Colors.grey,
              icon: Icons.history,
            ),
            if (_routeStack.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Route Stack (${_routeStack.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ..._routeStack.reversed.toList().asMap().entries.map(
                    (entry) => _buildStackEntry(
                      index: _routeStack.length - 1 - entry.key,
                      deepLink: entry.value,
                      isTop: entry.key == 0,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.route, color: Colors.deepPurple, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Tracker',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Navigation routes and deep links',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeepLinkRow({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final isEmpty = value.isEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
        Expanded(
          child: Text(
            isEmpty ? '—' : value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isEmpty ? FontWeight.normal : FontWeight.w500,
              color: isEmpty ? Colors.grey[400] : null,
              fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStackEntry({
    required int index,
    required String deepLink,
    required bool isTop,
  }) {
    final isEmpty = deepLink.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isTop ? Colors.deepPurple : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isTop ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEmpty ? '(no name)' : deepLink,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isTop ? FontWeight.w500 : FontWeight.normal,
                color: isEmpty ? Colors.grey[400] : null,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          if (isTop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'TOP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
