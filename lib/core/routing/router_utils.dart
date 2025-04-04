import 'package:flutter/material.dart';

PageRouteBuilder buildCustomBuilder(Widget screen, RouteSettings? settings) {
  return PageRouteBuilder(
    pageBuilder: (_context, animation, ___) {
      return screen;
    },
    settings: settings,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}


navigateNamed(BuildContext context,String route, {RouteSettings? settings}) {
  Navigator.of(context).pushNamed(
    route
  );
}

void navigateReplacementNamed(BuildContext context,String route, {RouteSettings? settings}) {
  Navigator.of(context).pushReplacementNamed(
    route
  );
}

navigateBack(BuildContext context) {
  Navigator.of(context).pop();
}