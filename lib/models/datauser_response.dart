class DatauserResponse {

  final String firstName;
  final String lastName;
  final String gender;
  final String username;
  final String userEmail;
  final String photoUserProfile;

  DatauserResponse({
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.username,
    required this.userEmail,
    required this.photoUserProfile,
  });

  factory DatauserResponse.fromJsonMap(Map<String, dynamic> json) => DatauserResponse(
    firstName: json["firstname"],
    lastName: json["lastname"],
    gender: json["gender"],
    username: json["username"],
    userEmail: json["userEmail"],
    photoUserProfile: json["photoUserProfile"],
  );

}
