import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/home/views/home_screen.dart';
import 'package:offline_pos/features/products/views/product_screen.dart';
import 'package:offline_pos/features/profile/views/profile_screen.dart';
import 'package:offline_pos/features/users/views/user_screen.dart';
import 'package:offline_pos/navigation_bloc.dart';
import 'package:offline_pos/features/transactions/transaction_screen.dart';

class MainWrapper extends StatelessWidget {
  final User user;
  const MainWrapper({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final List<NavigationItem> availableTabs = [
      NavigationItem(
        screen: const Center(child: HomeScreen()),
        label: 'Home',
        icon: Icons.home,
      ),
      if (user.role == 'ADMIN')
        NavigationItem(
          screen:  Center(child: ProductScreen()),
          label: 'Items',
          icon: Icons.inventory,
        ),
      if (user.role == 'ADMIN') // 🛡️ ADMIN ဖြစ်မှသာ Users Tab ကို ထည့်ပေးမယ်
        NavigationItem(
          screen:  Center(child: UserScreen()),
          label: 'Users',
          icon: Icons.people,
        ),
      NavigationItem(
        screen: const Center(child: TransactionsScreen()),
        label: 'Sales',
        icon: Icons.receipt_long,
      ),
      NavigationItem(
        screen: const Center(child: ProfileScreen()),
        label: 'Profile',
        icon: Icons.person,
      ),
    ];

    return BlocProvider(
      create: (context) => NavigationBloc(),
      child: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, navState) {
          int currentIndex = navState.selectedIndex;
          if (currentIndex >= availableTabs.length) {
            currentIndex = 0;
          }

          return Scaffold(
            body: IndexedStack(
              index: currentIndex,
              children: availableTabs.map((item) => item.screen).toList(),
            ),
            bottomNavigationBar: NavigationBarTheme(
              data: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    );
                  }
                  return const TextStyle(fontSize: 11);
                }),
              ),
              child: NavigationBar(
                selectedIndex: currentIndex,
                onDestinationSelected: (index) {
                  context.read<NavigationBloc>().add(TabChanged(index));
                },
                destinations: availableTabs.map((item) {
                  return NavigationDestination(
                    icon: Icon(item.icon),
                    label: item.label,
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class NavigationItem {
  final Widget screen;
  final String label;
  final IconData icon;
  NavigationItem({
    required this.screen,
    required this.label,
    required this.icon,
  });
}
