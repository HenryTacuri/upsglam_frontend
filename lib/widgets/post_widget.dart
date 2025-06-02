import 'package:app_instagram/widgets/comment.dart';
import 'package:app_instagram/widgets/like_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PostWidget extends StatefulWidget {
  const PostWidget({super.key});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool isAnimating = false;
  String user = 'mockUser123'; // Usuario simulado
  List<String> likes = []; // Lista simulada de usuarios que dieron like

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header del post
        Container(
          width: 375.w,
          height: 54.h,
          color: Colors.white,
          child: Center(
            child: ListTile(
              leading: ClipOval(
                child: SizedBox(
                  width: 35.w,
                  height: 35.h,
                  child: Image.asset('images/person.png'),
                ),
              ),
              title: Text('username', style: TextStyle(fontSize: 13.sp)),
            ),
          ),
        ),

        // Imagen del post con animación al hacer doble tap
        GestureDetector(
          onDoubleTap: () {
            setState(() {
              isAnimating = true;
              if (!likes.contains(user)) {
                likes.add(user); // Simula que se da like al hacer doble tap
              }
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 375.w,
                height: 375.h,
                child: Image.asset('images/post.jpg', fit: BoxFit.cover),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isAnimating ? 1 : 0,
                child: LikeAnimation(
                  isAnimating: isAnimating,
                  duration: const Duration(milliseconds: 400),
                  iconlike: false,
                  End: () {
                    setState(() {
                      isAnimating = false;
                    });
                  },
                  child: Icon(Icons.favorite, size: 100.w, color: Colors.red),
                ),
              ),
            ],
          ),
        ),

        // Iconos y acciones (like, comentario, enviar, guardar)
        Container(
          width: 375.w,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 14.h),

              Row(
                children: [
                  // Botón de Like
                  LikeAnimation(
                    isAnimating: likes.contains(user),
                    duration: Duration(milliseconds: 400),
                    iconlike: true,
                    End: () {},
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          if (likes.contains(user)) {
                            likes.remove(user); // Quitar like
                          } else {
                            likes.add(user); // Dar like
                          }
                        });
                      },
                      icon: Icon(
                        likes.contains(user)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: likes.contains(user) ? Colors.red : Colors.black,
                        size: 24.w,
                      ),
                    ),
                  ),

                  // Botón de comentarios
                  GestureDetector(
                    onTap: () {
                      showBottomSheet(
                        backgroundColor: Colors.transparent,
                        context: context,
                        builder: (context) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: DraggableScrollableSheet(
                              maxChildSize: 0.6,
                              initialChildSize: 0.6,
                              minChildSize: 0.2,
                              builder: (context, scrollController) {
                                return Comment(); // Comentarios
                              },
                            ),
                          );
                        },
                      );
                    },
                    child: Image.asset('images/comment.webp', height: 28.h),
                  ),
                ],
              ),

              Padding(
                padding: EdgeInsets.only(left: 15.w, top: 13.5.h, bottom: 5.h),
                child: Text(
                  '${likes.length} Me gusta',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
