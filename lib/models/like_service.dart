import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upsglam/models/upload_photo_response.dart';

// Servicio para togglear like (añadir/quitar) con transacción
class LikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'photos';

  Future<void> toggleLike({
    required String documentId,
    required int photoIndex,
    required String userUID,
    required String username,
    required String photoUserProfile,
  }) {
    final docRef = _firestore.collection(collectionName).doc(documentId);

    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) throw Exception('Documento no existe');

      final data = snap.data()!;
      final photos = List<Map<String, dynamic>>.from(
        (data['photos'] as List).map((e) => Map<String, dynamic>.from(e)),
      );

      List<Like> likes = (photos[photoIndex]['likes'] as List)
          .map((e) => Like.fromJsonMap(Map<String, dynamic>.from(e)))
          .toList();

      final index = likes.indexWhere((like) => like.userUID == userUID);

      if (index >= 0) {
        // Si ya dio like, lo quitamos
        likes.removeAt(index);
      } else {
        // Si no ha dado like, lo agregamos
        likes.add(Like(
          userUID: userUID,
          username: username,
          photoUserProfile: photoUserProfile,
        ));
      }

      photos[photoIndex]['likes'] = likes.map((like) => {
            'userUID': like.userUID,
            'username': like.username,
            'photoUserProfile': like.photoUserProfile,
          }).toList();

      tx.update(docRef, {'photos': photos});
    });
  }
}

