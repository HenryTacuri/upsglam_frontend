import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upsglam/models/upload_photo_response.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'photos';

  Future<void> postComment({
    required String documentId,
    required int photoIndex,
    required String commenterUID,
    required String username,
    required String photoUserProfile,
    required String commentText,
  }) {
    final docRef = _firestore.collection(collectionName).doc(documentId);

    // Crear comentario como objeto tipo Comment
    final newComment = Comment(
      userUID: commenterUID,
      username: username,
      comment: commentText,
      photoUserProfile: photoUserProfile,
    );

    // Convertir a Map<String, dynamic>
    final commentMap = {
      'userUID': newComment.userUID,
      'username': newComment.username,
      'comment': newComment.comment,
      'photoUserProfile': newComment.photoUserProfile,
    };

    return _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists) {
        throw Exception('El documento no existe');
      }

      final data = snapshot.data()!;
      final List<Map<String, dynamic>> photos = (data['photos'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (photoIndex < 0 || photoIndex >= photos.length) {
        throw Exception('Índice de foto fuera de rango');
      }

      final photo = photos[photoIndex];
      final List<dynamic> comments =
          List<dynamic>.from(photo['comments'] as List<dynamic>? ?? []);

      comments.add(commentMap);
      photo['comments'] = comments;
      photos[photoIndex] = photo;

      tx.update(docRef, {'photos': photos});
    });
  }
}



