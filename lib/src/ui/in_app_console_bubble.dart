import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:in_app_console/src/core/console/in_app_console_internal.dart';

/// A draggable floating bubble that opens the in-app console on tap.
///
/// Place inside [MaterialApp.builder] and pass the same [navigatorKey] to both
/// [MaterialApp] and this widget so the bubble can push routes correctly:
///
/// ```dart
/// final _navigatorKey = GlobalKey<NavigatorState>();
///
/// MaterialApp(
///   navigatorKey: _navigatorKey,
///   builder: (context, child) => InAppConsoleBubble(
///     navigatorKey: _navigatorKey,
///     child: child!,
///   ),
///   ...
/// )
/// ```
///
/// The bubble auto-snaps to the nearest horizontal edge on release.
/// It is hidden when [InAppConsole.kEnableConsole] is false.
class InAppConsoleBubble extends StatefulWidget {
  const InAppConsoleBubble({
    super.key,
    required this.navigatorKey,
    required this.child,
    this.bubbleSize = 56.0,
    this.edgeMargin = 8.0,
  });

  /// The same [GlobalKey] passed to [MaterialApp.navigatorKey].
  /// Used to obtain a Navigator-aware context when opening the console.
  final GlobalKey<NavigatorState> navigatorKey;

  final Widget child;

  /// Diameter of the bubble in logical pixels.
  final double bubbleSize;

  /// Minimum distance from screen edges.
  final double edgeMargin;

  @override
  State<InAppConsoleBubble> createState() => _InAppConsoleBubbleState();
}

class _InAppConsoleBubbleState extends State<InAppConsoleBubble>
    with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  bool _positionInitialized = false;

  late AnimationController _snapController;
  late Animation<Offset> _snapAnimation;

  final InAppConsoleInternal _console =
      InAppConsole.instance as InAppConsoleInternal;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _snapAnimation =
        Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.elasticOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_positionInitialized) {
      final size = MediaQuery.of(context).size;
      final padding = MediaQuery.of(context).padding;
      _position = Offset(
        size.width - widget.bubbleSize - widget.edgeMargin,
        padding.top + size.height * 0.6,
      );
      _positionInitialized = true;
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_snapController.isAnimating) _snapController.stop();
    setState(() {
      _position += details.delta;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    final snapToRight = _position.dx + widget.bubbleSize / 2 > size.width / 2;
    final targetX = snapToRight
        ? size.width - widget.bubbleSize - widget.edgeMargin
        : widget.edgeMargin;

    final minY = padding.top + widget.edgeMargin;
    final maxY =
        size.height - padding.bottom - widget.bubbleSize - widget.edgeMargin;
    final targetY = _position.dy.clamp(minY, maxY);

    final endOffset = Offset(targetX, targetY);

    _snapAnimation = Tween<Offset>(
      begin: _position,
      end: endOffset,
    ).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.elasticOut),
    );

    _snapController.forward(from: 0).then((_) {
      if (mounted) setState(() => _position = endOffset);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!InAppConsole.kEnableConsole) return widget.child;

    return StreamBuilder<bool>(
      stream: _console.isConsoleVisibleStream,
      initialData: false,
      builder: (context, snapshot) {
        final isConsoleVisible = snapshot.data ?? false;
        if (isConsoleVisible) return widget.child;

        return Stack(
          children: [
            widget.child,
            AnimatedBuilder(
              animation: _snapController,
              builder: (context, _) {
                final pos = _snapController.isAnimating
                    ? _snapAnimation.value
                    : _position;
                return Positioned(
                  left: pos.dx,
                  top: pos.dy,
                  child: _BubbleButton(
                    size: widget.bubbleSize,
                    onTap: () {
                      final navContext = widget.navigatorKey.currentContext;
                      if (navContext != null) {
                        InAppConsole.instance.openConsole(navContext);
                      }
                    },
                    onDragUpdate: _onDragUpdate,
                    onDragEnd: _onDragEnd,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _BubbleButton extends StatelessWidget {
  const _BubbleButton({
    required this.size,
    required this.onTap,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final double size;
  final VoidCallback onTap;
  final void Function(DragUpdateDetails) onDragUpdate;
  final void Function(DragEndDetails) onDragEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onPanUpdate: onDragUpdate,
      onPanEnd: onDragEnd,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black87,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.bug_report,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
