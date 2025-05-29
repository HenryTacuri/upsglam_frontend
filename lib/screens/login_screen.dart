import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upsglam/models/login_user_response.dart';
import 'package:upsglam/models/user_service.dart';
import 'package:upsglam/util/dialog.dart';
import 'package:upsglam/widgets/button_navigation.dart';

class LoginScreen extends StatefulWidget {
  
  final VoidCallback show;

  const LoginScreen(this.show, {super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final email = TextEditingController();
  FocusNode emailF = FocusNode();

  final password = TextEditingController();
  FocusNode passwordF = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Column(
        children: [
          SizedBox(width: 96.w, height: 30.h),
          Center(
            child: Image.asset('images/logo_app.png', width: 80.w, height: 80.h),
          ),
          SizedBox(height: 65.h),
          textField(email, Icons.email, 'Email', emailF),
          SizedBox(height: 30.h,),
          textField(password, Icons.lock, 'Password', passwordF),
          SizedBox(height: 30.h,),
          login(),
          SizedBox(height: 20.h,),
          signup(),
        ],
      )),
    );
  }

  Widget signup() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "¿No tienes cuenta?",
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey,
            ),
          ),
          GestureDetector(
            onTap: widget.show,
            child: Text(
              " Regístrate",
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

  Widget login() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: InkWell(
        onTap: () async {
          try {
            //await Authentication().Login(email: email.text, password: password.text);
            LoginUserResponse loginUserResponse = await UserService().login(email.text, password.text);
            print(loginUserResponse.message);
            String userUID = loginUserResponse.userUID;
            String username = loginUserResponse.username;
            String photoUserProfile = loginUserResponse.photoUserProfile;

            // ignore: use_build_context_synchronously
            Navigator.of(context).pushReplacement(
              //MaterialPageRoute(builder: (_) => const HomeScreen()),
              MaterialPageRoute(builder: (_) => ButtonNavigation(userUID: userUID, username: username, photoUserProfile: photoUserProfile)),
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
            'Iniciar Sesión',
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
