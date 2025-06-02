import 'package:app_instagram/screen/home.dart';
import 'package:app_instagram/screen/profile_screen.dart';
import 'package:flutter/material.dart';

class Navigations_Screen extends StatefulWidget {
  const Navigations_Screen({super.key});

  @override
  State<Navigations_Screen> createState() => _MyWidgetState();
}

int _currentIndex = 0;

class _MyWidgetState extends State<Navigations_Screen> {
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  onPageChanged(int page) {
    setState(() {
      _currentIndex = page;
    });
  }

  navigationTapped(int page) {
    pageController.jumpToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          currentIndex: _currentIndex,
          onTap: navigationTapped,

          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
          ],
        ),
      ),

      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        children: const [HomeScreen(), ProfileScreen()],
      ),
    );
  }
}
