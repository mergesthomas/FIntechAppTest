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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.md,
                  AppSpacing.pageHorizontal,
                  AppSpacing.lg,
                ),
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.headline, style: AppTextStyles.body),
                          const SizedBox(height: 4),
                          Text(
                            '${item.source} · ${item.age}',
                            style: AppTextStyles.meta.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
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
