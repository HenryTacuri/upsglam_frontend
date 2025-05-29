import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upsglam/models/comment_service.dart';
import 'package:upsglam/models/like_service.dart';
import 'package:upsglam/models/upload_photo_response.dart';

class GalleryScreen extends StatefulWidget {

  final String userUID; 
  final String username;
  final String photoUserProfile;      


  const GalleryScreen({
    super.key, 
    required this.userUID,
    required this.username,
    required this.photoUserProfile
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('photos')          // o el nombre de tu colección
                .doc(widget.userUID)
                .snapshots(),                 // STREAM en lugar de Future
            builder: (context, snapDoc) {
          
            if (snapDoc.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapDoc.hasData || !snapDoc.data!.exists) {
              return Center(child: Text('No data found.'));
            }

            
            // 2. Reconstruye tu modelo Photo desde el snapshot
            final data = snapDoc.data!.data() as Map<String, dynamic>;
            final photos = (data['photos'] as List<dynamic>)
                .map((e) => Photo.fromJsonMap(e as Map<String, dynamic>))
                .toList();

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: Text('Galería de Fotos'),
                  floating: true,
                  snap: true,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final photo = photos[index];
                      return Column(
                        children: [
                          Container(
                            width: 375.w,
                            height: 54.w,
                            color: Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(widget.photoUserProfile),
                                radius: 20.r,
                              ),
                              title: Text(widget.username, style: TextStyle(fontSize: 13.sp),),
                              trailing: const Icon(Icons.more_horiz),
                            ),
                          ),
                          Container(
                            width: 375.w,
                            height: 300.h,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(photo.urlPhoto),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            width: 375.w,
                            color: Colors.white,
                            child: Column(
                              children: [
                                SizedBox(width: 20.h),
                                Row(
                                  children: [
                                    buttonLike(context, photo, index),
                                    SizedBox(width: 17.w),
                                    buttonComment(context, photo, index)
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      );
                    },
                    childCount: photos.length, // <-- aquí limitas la cantidad
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
    int photoIndex,
  ) {
  final likeService = LikeService();

    return Row(
      children: [
        // 1. El icono que hace toggle like
        IconButton(
          icon: Icon(
            photo.likes.any((like) => like.userUID == widget.userUID)
                ? Icons.favorite
                : Icons.favorite_outline,
            size: 25.w,
            color: photo.likes.any((like) => like.userUID == widget.userUID) ? Colors.red : null,
          ),
          onPressed: () async {
            await likeService.toggleLike(
              documentId: widget.userUID,
              photoIndex: photoIndex,
              userUID: widget.userUID,
              username: widget.username,
              photoUserProfile: widget.photoUserProfile,
            );
            // el StreamBuilder del sheet y del StreamBuilder principal
            // actualizarán la UI automáticamente
          },
        ),

        SizedBox(width: 8.w),

        // 2. El contador que abre el sheet
        GestureDetector(
          onTap: () {
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
                        .doc(widget.userUID)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: 200.w,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (!snap.hasData || !snap.data!.exists) {
                        return SizedBox(
                          height: 200.w,
                          child: Center(child: Text('No hay datos')),
                        );
                      }

                      // Reconstruye la lista de fotos y cogemos la actualizada
                      final data = snap.data!.data() as Map<String, dynamic>;
                      final photosList = (data['photos'] as List<dynamic>)
                          .map((e) => Photo.fromJsonMap(e as Map<String, dynamic>))
                          .toList();
                      final updatedPhoto = photosList[photoIndex];

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Text(
                              'Likes (${updatedPhoto.likes.length})',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Divider(),

                          // Listado vivo de todos los UID que han dado like
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: updatedPhoto.likes.length,
                              itemBuilder: (_, i) {
                                final photoUserProfile = updatedPhoto.likes[i].photoUserProfile;
                                final username = updatedPhoto.likes[i].username;
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Image.network(photoUserProfile)
                                  ),
                                  title: Text(username),
                                );
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
            '${photo.likes.length}',
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
    int photoIndex,
  ) {
    final commentController = TextEditingController();

    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.comment_outlined, size: 25.w),
          onPressed: () {
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
                        .doc(widget.userUID)
                        .snapshots(),
                    builder: (c, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: 200.w,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (!snap.hasData || !snap.data!.exists) {
                        return SizedBox(
                          height: 200.w,
                          child: Center(child: Text('No hay datos')),
                        );
                      }

                      // Reconstruir lista de fotos y comentarios en tiempo real
                      final data = snap.data!.data()! as Map<String, dynamic>;
                      final photosList = (data['photos'] as List<dynamic>)
                          .map((e) => Photo.fromJsonMap(e as Map<String, dynamic>))
                          .toList();
                      final currentPhoto = photosList[photoIndex];

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Text(
                              'Comentarios (${currentPhoto.comments.length})',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Divider(),

                          // Lista viva de comentarios
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: currentPhoto.comments.length,
                              itemBuilder: (_, i) {
                                final cmt = currentPhoto.comments[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Image.network(cmt.photoUserProfile)
                                  ),
                                  title: Text(cmt.username),
                                  subtitle: Text(cmt.comment),
                                );
                              },
                            ),
                          ),

                          // Campo de texto + botón enviar
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.w,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: commentController,
                                    decoration: InputDecoration(
                                      hintText: 'Añadir un comentario…',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.send),
                                  onPressed: () async {
                                    final nuevoComentario = commentController.text;
                                    await CommentService()
                                        .postComment(
                                          documentId: widget.userUID,
                                          photoIndex: photoIndex,
                                          commenterUID: widget.userUID,
                                          commentText: nuevoComentario,
                                          username: widget.username,
                                          photoUserProfile: widget.photoUserProfile,
                                        );
                                    commentController.clear();
                                    // ¡No cerramos el sheet! El StreamBuilder actualiza la lista.
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(width: 8.w),
        Text('${photo.comments.length}'),
      ],
    );
  }

}




