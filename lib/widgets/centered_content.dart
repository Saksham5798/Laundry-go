// Centres content on wide screens and enforces max-width 640.
// Wrap any full-page Column with this to avoid stretched content.

import 'package:flutter/material.dart';
import '../core/constants.dart';

class CenteredContent extends StatelessWidget {
  final Widget child;
  const CenteredContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
        child: child,
      ),
    );
  }
}
