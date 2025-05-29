class LoginUserResponse {

  final String message;
  final String userToken;
  final String userUID;
  final String username;
  final String userEmail;
  final String photoUserProfile;

  LoginUserResponse({
    required this.message,
    required this.userToken,
    required this.userUID,
    required this.username,
    required this.userEmail,
    required this.photoUserProfile,
  });

  factory LoginUserResponse.fromJsonMap(Map<String, dynamic> json) => LoginUserResponse(
    message: json["message"],
    userToken: json["userToken"],
    userUID: json["userUID"],
    username: json["username"],
    userEmail: json["userEmail"],
    photoUserProfile: json["photoUserProfile"],
  );

}
