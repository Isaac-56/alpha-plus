import 'package:flutter/material.dart';

class AlphaBackButton extends StatelessWidget {
  const AlphaBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      icon: const Icon(Icons.arrow_back_rounded),
      tooltip: 'Back',
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        side: BorderSide(color: Theme.of(context).dividerColor),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
