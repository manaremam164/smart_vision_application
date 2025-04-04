import 'package:flutter/material.dart';
import 'package:smart_vision_application/presentation/screens/home/home_screen_navigator.dart';
import 'package:smart_vision_application/presentation/screens/home_screen.dart';
import 'package:smart_vision_application/presentation/screens/splash/splash_screen.dart';

import '../../presentation/screens/tabs-layout/chat_tab.dart';
import 'router_utils.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch(settings.name){
      case SplashScreen.route:
        return buildCustomBuilder(SplashScreen(), settings);

      case HomeScreen.route:
        return buildCustomBuilder(HomeScreen(), settings);

      case ChatScreen.route:
        return buildCustomBuilder(ChatScreen(), settings);

      default:
        return buildCustomBuilder(Container(), settings);
    }
  }
}