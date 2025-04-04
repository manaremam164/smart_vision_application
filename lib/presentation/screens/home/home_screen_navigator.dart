import 'package:flutter/material.dart';
import 'package:smart_vision_application/presentation/screens/tabs-layout/chat_tab.dart';

import '../../../core/theme/app_colors.dart';
import '../tabs-layout/home_tab.dart';

const tabs = <Widget>[
  HomeTab(),
  ChatScreen(),
];

class HomeScreenNavigator extends StatefulWidget {
  static const route = '/';
  const HomeScreenNavigator({super.key});

  @override
  State<HomeScreenNavigator> createState() => _HomeScreenNavigatorState();
}

class _HomeScreenNavigatorState extends State<HomeScreenNavigator> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabs[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            label: 'Chat',
          )
        ],
      )
    );
  }
}
