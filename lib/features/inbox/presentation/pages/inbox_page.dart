import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/money/money_format.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../domain/entities/inbox_item.dart';
import '../cubit/inbox_cubit.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InboxCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: BlocBuilder<InboxCubit, InboxState>(
        builder: (context, state) {
          return switch (state) {
            InboxLoading() => const Center(child: CircularProgressIndicator()),
            InboxEmpty() => const AppEmptyState(message: 'No inbox items'),
            InboxFailure(:final failure) => AppEmptyState(message: '$failure'),
            InboxSuccess(:final items) => _InboxList(items: items),
          };
        },
      ),
    );
  }
}

class _InboxList extends StatelessWidget {
  const _InboxList({required this.items});

  final List<InboxItem> items;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<InboxItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.dateLabel, () => []).add(item);
    }
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xs,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        for (final entry in grouped.entries) ...[
          AppSectionHeader(entry.key),
          for (final item in entry.value)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item.title, style: AppTextStyles.body),
                  ),
                  Text(
                    formatMoney(item.amount),
                    style: AppTextStyles.numeric.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
