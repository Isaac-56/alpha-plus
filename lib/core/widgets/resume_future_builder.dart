import 'package:flutter/material.dart';

/// Keeps platform reads stable through rebuilds, refreshing on return from settings.
class ResumeFutureBuilder<T> extends StatefulWidget {
  const ResumeFutureBuilder({required this.load, required this.builder, super.key});
  final Future<T> Function() load;
  final AsyncWidgetBuilder<T> builder;

  @override
  State<ResumeFutureBuilder<T>> createState() => _ResumeFutureBuilderState<T>();
}

class _ResumeFutureBuilderState<T> extends State<ResumeFutureBuilder<T>>
    with WidgetsBindingObserver {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _future = Future<T>.sync(widget.load);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _future = Future<T>.sync(widget.load));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: widget.builder,
  );
}
