import 'dart:io';

import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:upsglam/models/comment_service.dart';
import 'package:upsglam/models/like_service.dart';
import 'package:upsglam/models/photo_service.dart';
import 'package:upsglam/models/upload_photo_response.dart';
import 'package:upsglam/screens/edit_photo_screen.dart';

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
              return Center(child: Text('No hay publicaciones.'));
            }

            
            // 2. Reconstruye tu modelo Photo desde el snapshot
            final data = snapDoc.data!.data() as Map<String, dynamic>;
            final photos = (data['photos'] as List<dynamic>)
                .map((e) => Photo.fromJsonMap(e as Map<String, dynamic>))
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
              
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
                              trailing: PopupMenuButton<String>(
                                icon: Icon(Icons.more_horiz),
                                onSelected: (String value) async {
                                  switch (value) {
                                    case 'editar':
                                    final File? defaultImage = await _loadDefaultImage(photo.urlPhoto);
                                      if (defaultImage == null) {
                                        // defaultImage: muestra un snackbar o alerta de error
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('No se puede editar la fotografía.')),	
                                        );
                                        return;
                                      }

                                      // Navegar a la pantalla de edición
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditPhotoScreen(
                                            userUID: widget.userUID,
                                            defaultImage: defaultImage,
                                            urlPhoto: photo.urlPhoto,
                                            username: widget.username,
                                            photoUserProfile: widget.photoUserProfile,
                                          )
                                        ),
                                      );
                                      break;
                                    case 'eliminar':
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false, // para que no se cierre si tocan fuera
                                        builder: (_) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                      final result = await PhotoService().deletePhoto(
                                        userUID: widget.userUID,
                                        urlPhoto: photo.urlPhoto,
                                      );
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Fotografía eliminada con éxito'),
                                        )
                                      );
                                    break;
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  PopupMenuItem(
                                    value: 'editar',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'eliminar',
                                    child: Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                          ),
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
                              'Likes (${updatedPhoto.likes.length -1})',
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
                                if(i==0) {
                                  return Center(
                                    child: Text(
                                      'Se el primero en dar like',
                                      style: TextStyle(fontSize: 16.sp),
                                    ),
                                  );
                                } else {
                                  final photoUserProfile = updatedPhoto.likes[i].photoUserProfile;
                                  final username = updatedPhoto.likes[i].username;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Image.network(photoUserProfile)
                                    ),
                                    title: Text(username),
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
    int photoIndex,
  ) {
    final commentController = TextEditingController();

    return Row(
      children: [
        // --------------------- ICONO DEL BOTÓN ---------------------
        IconButton(
          icon: Icon(Icons.comment_outlined, size: 25.w),
          onPressed: () async {
            // 1) Pre-cargamos el snapshot antes de mostrar el modal
            DocumentSnapshot<Map<String, dynamic>> initialSnap =
                await FirebaseFirestore.instance
                    .collection('photos')
                    .doc(widget.userUID)
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
                              // ----------- DRAG HANDLE -----------
                              Container(
                                width: 40.w,
                                height: 4.w,
                                margin: EdgeInsets.symmetric(vertical: 8.w),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2.w),
                                ),
                              ),

                              // ----------- CONTENIDO DINÁMICO (ENCABEZADO + LISTA) -----------
                              Expanded(
                                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                  initialData: initialSnap,
                                  stream: FirebaseFirestore.instance
                                      .collection('photos')
                                      .doc(widget.userUID)
                                      .snapshots(),
                                  builder: (context, snap) {
                                    // Si aún no hay datos, mostramos loader
                                    if (snap.data == null) {
                                      return Center(child: CircularProgressIndicator());
                                    }

                                    // Recolectamos datos actualizados del snapshot
                                    final data = snap.data!.data()! as Map<String, dynamic>;
                                    final photosList = (data['photos'] as List<dynamic>)
                                        .map((e) => Photo.fromJsonMap(e as Map<String, dynamic>))
                                        .toList();
                                    final currentPhoto = photosList[photoIndex];

                                    return Column(
                                      children: [
                                        // ----- ENCABEZADO DINÁMICO -----
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
                                        Divider(),

                                        // ----- LISTA DE COMENTARIOS -----
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

                              // ----------- CAMPO DE TEXTO + BOTÓN ENVIAR -----------
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
                                            documentId: widget.userUID,
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
                                          documentId: widget.userUID,
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
              .doc(widget.userUID)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || !snap.data!.exists) {
              return Text('0');
            }

            final data = snap.data!.data()! as Map<String, dynamic>;
            final photosList = (data['photos'] as List<dynamic>)
                .map((e) => Photo.fromJsonMap(e as Map<String, dynamic>))
                .toList();

            // Asegurarnos de que photoIndex esté dentro de rango
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



  Future<File?> _loadDefaultImage(String defaultUrl) async {
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        defaultUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        final bytes = response.data!;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/default.jpg');
        await file.writeAsBytes(bytes);
        return file;
      } else {
        print('Error: estado ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioError cargando imagen por defecto: $e');
    } catch (e) {
      print('Error inesperado: $e');
    }
    return null;
  }
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final formatter = DateFormat('dd/MM/yyyy HH:mm', 'es');
    return formatter.format(date);
  }

}




