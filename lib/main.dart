import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_vision_application/core/routing/app_router.dart';
import 'package:smart_vision_application/data/repositories/local/cache_repository.dart';
import 'package:smart_vision_application/presentation/screens/camera_view.dart';
import 'package:smart_vision_application/presentation/screens/home/home_screen_navigator.dart';
import 'package:smart_vision_application/presentation/screens/home_screen.dart';
import 'package:smart_vision_application/presentation/screens/splash/splash_screen.dart';

Future<void> requestPermissions() async {
  if (await Permission.microphone.isDenied) {
    await Permission.microphone.request();
  }
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  if (await Permission.camera.isDenied) {
    await Permission.camera.request();
  }
}

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await CacheRepository.init();
  await requestPermissions();
  runApp(const SmartVisionApp());
}

class SmartVisionApp extends StatelessWidget {
  const SmartVisionApp({super.key});



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Vision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // onGenerateRoute: AppRouter.generateRoute,
      // initialRoute: SplashScreen.route
      home: const HomeScreenNavigator(),
    );
  }
}