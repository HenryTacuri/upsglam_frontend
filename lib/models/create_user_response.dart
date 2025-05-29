class CreateUserResponse {

  final String message;
  final String idUser;
  final String username;
  final String email;

  CreateUserResponse({
    required this.message,
    required this.idUser,
    required this.username, 
    required this.email,
  });

  factory CreateUserResponse.fromJsonMap(Map<String, dynamic> json) => CreateUserResponse(
    message: json["message"],
    idUser: json["idUser"],
    username: json["username"],
    email: json["email"],
  );

}
