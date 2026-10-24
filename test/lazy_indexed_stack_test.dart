import 'package:alpha_plus/core/widgets/lazy_indexed_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Page extends StatefulWidget {
  const _Page(this.index, this.mountedPages, this.disposedPages);
  final int index;
  final List<int> mountedPages;
  final List<int> disposedPages;
  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  @override
  void initState() {
    super.initState();
    widget.mountedPages.add(widget.index);
  }

  @override
  void dispose() {
    widget.disposedPages.add(widget.index);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('Page ${widget.index}');
}

void main() {
  testWidgets(
    'tabs mount on demand and returning keeps the existing map alive',
    (tester) async {
      final mounted = <int>[];
      final disposed = <int>[];
      Widget app(int selected, String account) => MaterialApp(
        home: LazyIndexedStack(
          key: ValueKey<String>(account),
          index: selected,
          children: List<Widget>.generate(
            5,
            (i) => _Page(i, mounted, disposed),
          ),
        ),
      );
      await tester.pumpWidget(app(0, 'driver1'));
      expect(mounted, <int>[0]);
      await tester.pumpWidget(app(2, 'driver1'));
      expect(mounted, <int>[0, 2]);
      expect(disposed, isEmpty);
      await tester.pumpWidget(app(0, 'driver1'));
      expect(mounted, <int>[0, 2]);
      expect(find.text('Page 0'), findsOneWidget);
      expect(disposed, isEmpty);
      await tester.pumpWidget(app(0, 'driver2'));
      expect(mounted, <int>[0, 2, 0]);
      expect(disposed, containsAll(<int>[0, 2]));
    },
  );
}
