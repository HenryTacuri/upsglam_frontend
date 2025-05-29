import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:upsglam/auth/auth_screen.dart';
//import 'package:upsglam/screens/home.dart';

class MainPage extends StatelessWidget {

  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if(snapshot.hasData) {
            //return const HomeScreen();
            return const AuthScreen();
          } else {
            return const AuthScreen();
          }
        },
      ),
    );
  }

}