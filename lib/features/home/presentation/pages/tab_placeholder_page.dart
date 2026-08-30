import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class TabPlaceholderPage extends StatelessWidget {
  const TabPlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('$title is loading next.', style: AppTextStyles.secondary),
      ),
    );
  }
}
