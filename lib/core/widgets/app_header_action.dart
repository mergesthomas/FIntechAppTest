import 'package:flutter/material.dart';

/// Header control with the same 40×40 hit target on leading and trailing edges.
class AppHeaderAction extends StatelessWidget {
  const AppHeaderAction({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        visualDensity: VisualDensity.compact,
        icon: icon,
      ),
    );
  }
}
