import 'package:flutter/material.dart';

import '../error/failure.dart';
import '../notice/failure_message.dart';
import '../notice/notice_copy.dart';
import 'app_empty_state.dart';

class AppFailureView extends StatelessWidget {
  const AppFailureView({
    super.key,
    required this.failure,
    this.onRetry,
  });

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      message: FailureMessage.map(failure),
      actionLabel: onRetry == null ? null : NoticeCopy.retry,
      onAction: onRetry,
    );
  }
}
