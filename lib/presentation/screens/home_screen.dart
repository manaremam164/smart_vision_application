import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  static const route = "/home-screen";
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Screen"),
      ),

      body: Column(
        children: [
          Text("Hello There")
        ],
      ),
    );
  }
}