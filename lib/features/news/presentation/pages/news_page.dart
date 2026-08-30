import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            NewsEmpty() => const Center(child: Text('No news')),
            NewsFailure(:final failure) => Center(child: Text('$failure')),
            NewsSuccess(:final items) => ListView(
                children: [
                  for (final item in items)
                    ListTile(
                      title: Text(item.headline),
                      subtitle: Text('${item.source} · ${item.age}'),
                    ),
                ],
              ),
          };
        },
      ),
    );
  }
}
