import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../cubit/home_cubit.dart';
import '../../../card/presentation/pages/card_page.dart';
import '../../../explore/presentation/pages/explore_page.dart';
import '../../../futures/presentation/pages/futures_page.dart';
import '../../../swap/presentation/pages/swap_page.dart';
import 'dashboard_page.dart';

class HomeShellPage extends StatelessWidget {
  const HomeShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, session) {
        if (session is! SessionSuccess) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const _HomeTabs();
      },
    );
  }
}

class _HomeTabs extends StatefulWidget {
  const _HomeTabs();

  @override
  State<_HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<_HomeTabs> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardPage(),
      const ExplorePage(),
      const FuturesPage(),
      const CardPage(),
      const SwapPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
          if (i == 0) {
            context.read<HomeCubit>().load();
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Futures',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Card',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Exchange',
          ),
        ],
      ),
    );
  }
}
