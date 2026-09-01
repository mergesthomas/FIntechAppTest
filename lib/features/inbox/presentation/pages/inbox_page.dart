import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/clock/chart_time_label.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_failure_view.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../domain/entities/inbox_item.dart';
import '../copy/inbox_copy.dart';
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
      appBar: AppBar(title: const Text(InboxCopy.title)),
      body: BlocBuilder<InboxCubit, InboxState>(
        builder: (context, state) {
          return switch (state) {
            InboxLoading() => const Center(child: CircularProgressIndicator()),
            InboxEmpty() => const AppEmptyState(message: InboxCopy.empty),
            InboxFailure(:final failure) => AppFailureView(
              failure: failure,
              onRetry: context.read<InboxCubit>().load,
            ),
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
              key: Key('inbox_item_${item.id}'),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: AppTextStyles.body),
                        const SizedBox(height: 2),
                        Text(
                          clockTimeLabel(item.occurredAt),
                          style: AppTextStyles.meta.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          formatQuantity(item.amount),
                          style: AppTextStyles.meta.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _priceText(item),
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

  String _priceText(InboxItem item) {
    final price = item.unitPrice;
    if (price == null) {
      return formatQuantity(item.amount);
    }
    return formatMoney(price);
  }
}
