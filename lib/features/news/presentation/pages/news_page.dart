import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../cubit/news_cubit.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NewsCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News')),
      body: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          return switch (state) {
            NewsLoading() => const Center(child: CircularProgressIndicator()),
            NewsEmpty() => const AppEmptyState(message: 'No news'),
            NewsFailure(:final failure) => AppEmptyState(message: '$failure'),
            NewsSuccess(:final items) => ListView(
              key: const Key('news_feed_scroll'),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.md,
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
              ),
              children: [
                for (final item in items)
                  ListTile(
                    key: Key('news_item_${item.id}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.headline, style: AppTextStyles.body),
                    subtitle: Text(
                      '${item.source} · ${item.age}',
                      style: AppTextStyles.meta.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          };
        },
      ),
    );
  }
}
