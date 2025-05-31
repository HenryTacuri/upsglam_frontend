import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upsglam/models/comment_service.dart';
import 'package:upsglam/models/like_service.dart';
import 'package:upsglam/models/photos_user_response.dart';

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
            return const Center(child: Text('No hay datos.'));
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
                            trailing: const Icon(Icons.more_horiz),
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
                              'Likes (${updatedPhoto.likes.length})',
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
                                final like =
                                    updatedPhoto.likes[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                        like.photoUserProfile),
                                  ),
                                  title: Text(like.username),
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
    String ownerUID,
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
                        .doc(ownerUID)
                        .snapshots(),
                    builder: (c, snap) {
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
                          const Divider(),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount:
                                  currentPhoto.comments.length,
                              itemBuilder: (_, i) {
                                final cmt =
                                    currentPhoto.comments[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                        cmt.photoUserProfile),
                                  ),
                                  title: Text(cmt.username),
                                  subtitle: Text(cmt.comment),
                                );
                              },
                            ),
                          ),
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
                                        borderRadius:
                                            BorderRadius.circular(
                                                8.r),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: () async {
                                    final text =
                                        commentController.text;
                                    await CommentService()
                                        .postComment(
                                      documentId: ownerUID,
                                      photoIndex: photoIndex,
                                      commenterUID:
                                          widget.userUID,
                                      commentText: text,
                                      username:
                                          widget.username,
                                      photoUserProfile:
                                          widget.photoUserProfile,
                                    );
                                    commentController.clear();
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




