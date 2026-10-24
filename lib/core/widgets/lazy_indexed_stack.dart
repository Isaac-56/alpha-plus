import 'package:flutter/widgets.dart';

/// Mounts tabs on first use and keeps visited pages alive for instant returns.
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    required this.index,
    required this.children,
    super.key,
  }) : assert(index >= 0 && index < children.length);

  final int index;
  final List<Widget> children;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final Set<int> _visited = <int>{widget.index};

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited.removeWhere((int index) => index >= widget.children.length);
    _visited.add(widget.index);
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: widget.index,
    children: List<Widget>.generate(
      widget.children.length,
      (int index) => TickerMode(
        enabled: index == widget.index,
        child: RepaintBoundary(
          child: _visited.contains(index)
              ? widget.children[index]
              : const SizedBox.shrink(),
        ),
      ),
    ),
  );
}
