import 'package:app_instagram/screen/home.dart';
import 'package:app_instagram/widgets/navigation.dart';
import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const Navigations_Screen());
  }
}
