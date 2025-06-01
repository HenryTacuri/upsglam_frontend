import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upsglam/models/comment_service.dart';
import 'package:upsglam/models/like_service.dart';
import 'package:upsglam/models/photos_user_response.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {

  final String userUID; 
  final String username;
  final String photoUserProfile;      


  const HomeScreen({
    super.key, 
    required this.userUID,
    required this.username,
    required this.photoUserProfile
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


  class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        // Escuchamos *toda* la colección 'photos'
        stream: FirebaseFirestore.instance.collection('photos').snapshots(),
        builder: (context, snapCols) {
          if (snapCols.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapCols.hasData || snapCols.data!.docs.isEmpty) {
            return const Center(child: Text('No hay publicaciones.'));
          }

          // Armamos una lista "plana" de posts de todos los usuarios
          final posts = <Map<String, dynamic>>[];
          for (final doc in snapCols.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final ownerUID = doc.id;
            final ownerUsername = data['username'] as String? ?? 'Sin nombre';
            final ownerProfile = data['photoUserProfile'] as String? ?? '';

            final rawPhotos = (data['photos'] as List<dynamic>);
            for (var i = 0; i < rawPhotos.length; i++) {
              final photo = Photo.fromJsonMap(rawPhotos[i] as Map<String, dynamic>);
              posts.add({
                'photo': photo,
                'ownerUID': ownerUID,
                'ownerUsername': ownerUsername,
                'ownerProfile': ownerProfile,
                'photoIndex': i,
              });
            }
          }

            posts.sort((a, b) {
              final dateA = (a['photo'] as Photo).date;
              final dateB = (b['photo'] as Photo).date;
              return dateB.compareTo(dateA); // orden descendente
            });

          return CustomScrollView(
            slivers: [
              const SliverAppBar(
                title: Text('Galería de Fotos'),
                floating: true,
                snap: true,
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    final Photo photo = post['photo'];
                    final ownerUID = post['ownerUID'] as String;
                    final ownerUsername = post['ownerUsername'] as String;
                    final ownerProfile = post['ownerProfile'] as String;
                    final photoIndex = post['photoIndex'] as int;

                    return Column(
                      children: [
                        // Cabecera con datos del dueño de la foto
                        Container(
                          width: 375.w,
                          height: 54.w,
                          color: Colors.white,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(ownerProfile),
                              radius: 20.r,
                            ),
                            title: Text(
                              ownerUsername,
                              style: TextStyle(fontSize: 13.sp),
                            ),
                          ),
                        ),

                        // La propia foto
                        Container(
                          width: 375.w,
                          height: 300.h,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(photo.urlPhotoFilter == 'NaN' ? photo.urlPhoto : photo.urlPhotoFilter),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        Container(
                          color: const Color.fromARGB(255, 255, 255, 255), // <– el color de fondo que desees
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.h),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formatDate(photo.date),
                                style: TextStyle(fontSize: 12.sp),
                              ),
                            ),
                          ),
                        ),

                        // Likes & comentarios
                        Container(
                          width: 375.w,
                          color: Colors.white,
                          child: Column(
                            children: [
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  buttonLike(
                                    context,
                                    photo,
                                    ownerUID,
                                    photoIndex,
                                  ),
                                  SizedBox(width: 17.w),
                                  buttonComment(
                                    context,
                                    photo,
                                    ownerUID,
                                    photoIndex,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  childCount: posts.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget buttonLike(
    BuildContext context,
    Photo photo,
    String ownerUID,
    int photoIndex,
  ) {
    final likeService = LikeService();

    final hasLiked =
        photo.likes.any((like) => like.userUID == widget.userUID);

    return Row(
      children: [
        IconButton(
          icon: Icon(
            hasLiked ? Icons.favorite : Icons.favorite_outline,
            size: 25.w,
            color: hasLiked ? Colors.red : null,
          ),
          onPressed: () async {
            await likeService.toggleLike(
              documentId: ownerUID,
              photoIndex: photoIndex,
              userUID: widget.userUID,             // el usuario ACTUAL
              username: widget.username,
              photoUserProfile: widget.photoUserProfile,
            );
          },
        ),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: () {
            // BottomSheet de lista de likes
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SafeArea(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('photos')
                        .doc(ownerUID)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (snap.connectionState ==
                          ConnectionState.waiting) {
                        return SizedBox(
                          height: 200.w,
                          child: const Center(
                              child: CircularProgressIndicator()),
                        );
                      }
                      if (!snap.hasData || !snap.data!.exists) {
                        return SizedBox(
                          height: 200.w,
                          child: const Center(
                              child: Text('No hay datos')),
                        );
                      }

                      final data =
                          snap.data!.data() as Map<String, dynamic>;
                      final photosList = (data['photos'] as List)
                          .map((e) =>
                              Photo.fromJsonMap(e as Map<String, dynamic>))
                          .toList();
                      final updatedPhoto = photosList[photoIndex];

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Text(
                              'Likes (${updatedPhoto.likes.length - 1})',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Divider(),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: updatedPhoto.likes.length,
                              itemBuilder: (_, i) {
                                if(i == 0) {
                                  return Center(
                                    child: Text(
                                      'Se el primero en dar like',
                                      style: TextStyle(fontSize: 16.sp),
                                    ),
                                  );
                                } else {
                                  final like = updatedPhoto.likes[i];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          like.photoUserProfile),
                                    ),
                                    title: Text(like.username),
                                  );
                                }
                              },
                            ),
                          ),
                          SizedBox(height: 16.w),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
          child: Text(
            '${photo.likes.length - 1}',
            style: TextStyle(
              fontSize: 16.sp,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

Widget buttonComment(
  BuildContext context,
  Photo photo,
  String ownerUID,
  int photoIndex,
) {
  final commentController = TextEditingController();

  return Row(
    children: [
      // -------------------------------- ICONO DEL BOTÓN --------------------------------
      IconButton(
        icon: Icon(Icons.comment_outlined, size: 25.w),
        onPressed: () async {
          // 1) Pre-cargar el snapshot antes de mostrar el modal
          DocumentSnapshot<Map<String, dynamic>> initialSnap =
              await FirebaseFirestore.instance
                  .collection('photos')
                  .doc(ownerUID)
                  .get();

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              return DraggableScrollableSheet(
                initialChildSize: 0.75,
                minChildSize: 0.3,
                maxChildSize: 0.9,
                expand: false,
                builder: (BuildContext sheetContext, ScrollController scrollController) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                        ),
                        child: Column(
                          children: [
                            // ------------------------- DRAG HANDLE -------------------------
                            Container(
                              width: 40.w,
                              height: 4.w,
                              margin: EdgeInsets.symmetric(vertical: 8.w),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2.w),
                              ),
                            ),

                            // ------------ CONTENIDO DINÁMICO (ENCABEZADO + LISTA) ------------
                            Expanded(
                              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                initialData: initialSnap,
                                stream: FirebaseFirestore.instance
                                    .collection('photos')
                                    .doc(ownerUID)
                                    .snapshots(),
                                builder: (context, snap) {
                                  // Si no hay datos aún, mostramos loader
                                  if (snap.data == null) {
                                    return Center(child: CircularProgressIndicator());
                                  }

                                  // Extraer datos actualizados del snapshot
                                  final data = snap.data!.data()! as Map<String, dynamic>;
                                  final photosList = (data['photos'] as List<dynamic>)
                                      .map((e) => Photo.fromJsonMap(e as Map<String, dynamic>))
                                      .toList();
                                  final currentPhoto = photosList[photoIndex];

                                  return Column(
                                    children: [
                                      // ----------------------- ENCABEZADO DINÁMICO -----------------------
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
                                        child: Text(
                                          'Comentarios (${currentPhoto.comments.length - 1})',
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Divider(),

                                      // ----------------------- LISTA DE COMENTARIOS -----------------------
                                      Expanded(
                                        child: currentPhoto.comments.length <= 1
                                            ? Center(
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 24.w),
                                                  child: Text(
                                                    'Sé el primero en comentar',
                                                    style: TextStyle(fontSize: 16.sp),
                                                  ),
                                                ),
                                              )
                                            : ListView.builder(
                                                controller: scrollController,
                                                shrinkWrap: true,
                                                itemCount: currentPhoto.comments.length,
                                                itemBuilder: (_, i) {
                                                  if (i == 0) return SizedBox.shrink();
                                                  final cmt = currentPhoto.comments[i];
                                                  return ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundImage: NetworkImage(cmt.photoUserProfile),
                                                    ),
                                                    title: Text(cmt.username),
                                                    subtitle: Text(cmt.comment),
                                                  );
                                                },
                                              ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),

                            // ---------- CAMPO DE TEXTO + BOTÓN ENVIAR (siempre fijo abajo) ----------
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: commentController,
                                      textInputAction: TextInputAction.send,
                                      decoration: InputDecoration(
                                        hintText: 'Añadir un comentario…',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 8.w,
                                        ),
                                      ),
                                      onSubmitted: (_) async {
                                        final texto = commentController.text.trim();
                                        if (texto.isEmpty) return;
                                        await CommentService().postComment(
                                          documentId: ownerUID,
                                          photoIndex: photoIndex,
                                          commenterUID: widget.userUID,
                                          commentText: texto,
                                          username: widget.username,
                                          photoUserProfile: widget.photoUserProfile,
                                        );
                                        commentController.clear();
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.send),
                                    onPressed: () async {
                                      final texto = commentController.text.trim();
                                      if (texto.isEmpty) return;
                                      await CommentService().postComment(
                                        documentId: ownerUID,
                                        photoIndex: photoIndex,
                                        commenterUID: widget.userUID,
                                        commentText: texto,
                                        username: widget.username,
                                        photoUserProfile: widget.photoUserProfile,
                                      );
                                      commentController.clear();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      const SizedBox(width: 8),

      // ----------------- CONTADOR FUERA DEL MODAL (REACTIVO) -----------------
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('photos')
            .doc(ownerUID)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists) {
            return Text('0');
          }

          final data = snap.data!.data()! as Map<String, dynamic>;
          final photosList = (data['photos'] as List<dynamic>)
              .map((e) => Photo.fromJsonMap(e as Map<String, dynamic>))
              .toList();

          if (photoIndex < 0 || photoIndex >= photosList.length) {
            return Text('0');
          }

          final currentPhoto = photosList[photoIndex];
          final count = currentPhoto.comments.length - 1;

          return Text(
            '$count',
            style: TextStyle(fontSize: 16.sp),
          );
        },
      ),
    ],
  );
}

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final formatter = DateFormat('dd/MM/yyyy HH:mm', 'es');
    return formatter.format(date);
  }


}




