import 'package:flutter/material.dart';
import 'package:upsglam/screens/gallery_screen.dart';
import 'package:upsglam/screens/home.dart';
import 'package:upsglam/screens/profile_screen.dart';
import 'package:upsglam/screens/upload_photo_screen.dart';


class ButtonNavigation extends StatefulWidget {

  final String userUID;   
  final String username;
  final String photoUserProfile;      

  const ButtonNavigation({
    super.key, 
    required this.userUID, 
    required this.username, 
    required this.photoUserProfile
  });

  @override
  State<ButtonNavigation> createState() => _ButtonNavigationState();
}

int _currentIndex = 0;

class _ButtonNavigationState extends State<ButtonNavigation> {
  
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
      _currentIndex=page;
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: ''
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera),
              label: ''
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_album),
              label: ''
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: ''
            )
          ],
        ),
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        children: [
          HomeScreen(userUID: widget.userUID, username: widget.username, photoUserProfile: widget.photoUserProfile),
          UploadPhotoScreen(userUID: widget.userUID), // 2) Pasar userUID
          GalleryScreen(userUID: widget.userUID, username: widget.username, photoUserProfile: widget.photoUserProfile), // 3) Pasar username y photoUserProfile
          ProfileScreen(userUID: widget.userUID)
        ],
      ),
    );
  }

}

