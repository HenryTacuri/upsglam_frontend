import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upsglam/auth/auth_screen.dart';
import 'package:upsglam/models/create_user_response.dart';
import 'package:upsglam/models/user_service.dart';
import 'package:upsglam/util/dialog.dart';
import 'package:upsglam/util/imagepicker.dart';

class SignupScreen extends StatefulWidget {
  
  final VoidCallback show;

  const SignupScreen(this.show, {super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  final username = TextEditingController();
  FocusNode usernameF = FocusNode();

  final email = TextEditingController();
  FocusNode emailF = FocusNode();

  final password = TextEditingController();
  FocusNode passwordF = FocusNode();

  final passwordConfirmed = TextEditingController();
  FocusNode passwordConfirmedF = FocusNode();
  File? _imageFile;

  @override
  void dispose() {
    super.dispose();
    username.dispose();
    email.dispose();
    password.dispose();
    passwordConfirmed.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Column(
        children: [
          SizedBox(width: 96.w, height: 5.h),
          Center(
            //child: Image.asset('images/logo_app.png', width: 125.w, height: 125.h),
            child: Text(
              'Regístrate',
              style: TextStyle(
                fontSize: 30.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black
              ),
            ),
          ),
          SizedBox(height: 30.h),
          InkWell(
            onTap: () async {
              File _imageFilee = await ImagePickerr().uploadImage('gallery');
              setState(() {
                _imageFile = _imageFilee;
              });

            },
            child: CircleAvatar(
              radius: 70.r,
              backgroundColor: Colors.grey,
              child: _imageFile==null ? CircleAvatar(
                  radius: 68.r,
                  backgroundImage: AssetImage('images/person.png'),
                  backgroundColor: Colors.grey.shade200,
              ):CircleAvatar(
                  radius: 68.r,
                  backgroundImage: Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                ).image,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ),
          SizedBox(height: 50.h),
          textField(username, Icons.person, 'Username', usernameF),
          SizedBox(height: 30.h,),
          textField(email, Icons.email, 'Email', emailF),
          SizedBox(height: 30.h,),
          textField(password, Icons.lock, 'Password', passwordF),
          SizedBox(height: 30.h,),
          textField(passwordConfirmed, Icons.lock, 'Password Confirmed', passwordConfirmedF),
          SizedBox(height: 30.h,),
          signup(),
          SizedBox(height: 20.h,),
          login(),
        ],
      )),
    );
  }

  Widget login() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "¿Ya tienes cuenta?",
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey,
            ),
          ),
          GestureDetector(
            onTap: widget.show,
            child: Text(
              " Iniciar Sesión",
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget signup() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: InkWell(
        onTap: () async {
          try {
            CreateUserResponse createUserResponse = await UserService().createUser(
              username.text,
              email.text,
              password.text,
              passwordConfirmed.text,
              _imageFile ?? File(''),
            );
            
            print(createUserResponse.email);
            
            // ignore: use_build_context_synchronously
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            );

          } catch (e) {
            final msg = e.toString().replaceFirst('Exception: ', '');
            // ignore: use_build_context_synchronously
            dialogBuilder(context, msg);
          }
        },
        child: Container(
          alignment: Alignment.center,
          width: double.infinity,
          height: 44.h,
          decoration: BoxDecoration(
            color: Colors.blue, 
            borderRadius: BorderRadius.circular(10.r)
          ),
          child: Text(
            'Regístrate',
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }

  Widget textField(TextEditingController controller, IconData icon, String type, FocusNode focusNode) {
    return  Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.r)
        ),   
        child: TextField(
          style: TextStyle(fontSize: 15.sp, color: Colors.black),
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: type,
            prefixIcon: Icon(
              icon, 
              color: focusNode.hasFocus ? Colors.black: Colors.grey
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(color: Colors.grey, width: 2.w)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(color: Colors.black, width: 2.w)
            ),
          ),
        ),
      ),
    );
  }

}
