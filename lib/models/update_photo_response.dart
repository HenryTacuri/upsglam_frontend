class UpdatePhotoResponse {
  
  String userUID;
  String username;
  String photoUserProfile;

  List<Photo> photos;

  UpdatePhotoResponse({
    required this.userUID,
    required this.username,
    required this.photoUserProfile,
    required this.photos
  });

  factory UpdatePhotoResponse.fromJsonMap(Map<String, dynamic> json) => UpdatePhotoResponse(
    userUID: json["userUID"],//
    username: json["username"],
    photoUserProfile: json["photoUserProfile"],
    photos: List<Photo>.from(json["photos"].map((x) => Photo.fromJsonMap(x))),
  );

}


class Photo {

  String urlPhoto;
  String urlPhotoFilter;
  List<Comment> comments;
  List<Like> likes;

  Photo({
      required this.urlPhoto,
      required this.urlPhotoFilter,
      required this.comments,
      required this.likes,
  });

  factory Photo.fromJsonMap(Map<String, dynamic> json) => Photo(
      urlPhoto: json["urlPhoto"],
      urlPhotoFilter: json["urlPhotoFilter"],
      comments: List<Comment>.from(json["comments"].map((x) => Comment.fromJsonMap(x))),
      likes: List<Like>.from(json["likes"].map((x) => Like.fromJsonMap(x))),
  );

}

class Comment {
    String userUID;
    String username;
    String comment;
    String photoUserProfile;

  Comment({
      required this.userUID,
      required this.username,
      required this.comment,
      required this.photoUserProfile,
  });

  factory Comment.fromJsonMap(Map<String, dynamic> json) => Comment(
      userUID: json["userUID"],
      username: json["username"],
      comment: json["comment"],
      photoUserProfile: json["photoUserProfile"],
  );
  
}


class Like {
    String userUID;
    String username;
    String photoUserProfile;

  Like({
      required this.userUID,
      required this.username,
      required this.photoUserProfile,
  });

  factory Like.fromJsonMap(Map<String, dynamic> json) => Like(
      userUID: json["userUID"],
      username: json["username"],
      photoUserProfile: json["photoUserProfile"],
  );
  
}