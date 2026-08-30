import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/money/money_format.dart';
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
            InboxEmpty() => const Center(child: Text('No inbox items')),
            InboxFailure(:final failure) => Center(child: Text('$failure')),
            InboxSuccess(:final items) => ListView(
                children: [
                  for (final item in items)
                    ListTile(
                      title: Text(item.title),
                      subtitle: Text(item.dateLabel),
                      trailing: Text(formatMoney(item.amount)),
                    ),
                ],
              ),
          };
        },
      ),
    );
  }
}
