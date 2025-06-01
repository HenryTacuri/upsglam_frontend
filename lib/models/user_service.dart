import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:upsglam/models/create_user_response.dart';
import 'package:upsglam/models/datauser_response.dart';
import 'package:upsglam/models/login_user_response.dart';

class UserService {


  final Dio _dio = Dio(BaseOptions(
    //192.168.18.162
    //192.168.18.20
    baseUrl: "http://192.168.18.20:8080/",
    headers: {
      "Content-Type": "application/json",
    },
  ));

  Future<CreateUserResponse> createUser(
    String firstName,
    String lastName,
    String gender,
    String username,
    String email,
    String password,
    String passwordConfirmed,
    File photoUserProfile,
  ) async {
    // 1) Validación de campos vacíos
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        gender.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        passwordConfirmed.isEmpty) {
      throw Exception('Por favor completa todos los campos');
    }

    if(photoUserProfile.path.isEmpty) {
      throw Exception('Por favor selecciona una foto de perfil');
    }

    // 2) Validación de igualdad de contraseñas
    if (password != passwordConfirmed) {
      throw Exception('Las contraseñas no coinciden');
    }

    // 3) Preparar FormData
    final formData = FormData.fromMap({
      'user': MultipartFile.fromString(
        jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'gender': gender,
          'username': username,
          'email': email,
          'password': password,
        }),
        filename: 'user.json',
        contentType: DioMediaType('application', 'json'),
      ),
      'photoUserProfile': await MultipartFile.fromFile(
        photoUserProfile.path,
        filename: '${username}_photoProfile.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      ),
    });

    try {
      // 4) Llamada al endpoint
      final response = await _dio.post(
        'users/register',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return CreateUserResponse.fromJsonMap(response.data);
    } on DioException catch (e) {
      // 5) Si el servidor devolvió un cuerpo JSON con "message"
      if (e.response != null &&
          e.response?.data != null &&
          e.response!.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        final serverMsg = data['error'] as String? ??
            'Error al crear el usuario';
        throw Exception(serverMsg);
      }
      // 6) Caso de fallo de red u otros errores
      throw Exception('Error de conexión. Intenta de nuevo.');
    }
  }


  Future<LoginUserResponse> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Por favor completa todos los campos');
    }

    try {
      final response = await _dio.post(
        'auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return LoginUserResponse.fromJsonMap(response.data);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final serverMsg = e.response!.data['error'] as String? ?? 'Error al iniciar sesión';
        throw Exception(serverMsg);
      }
            throw Exception('Error de conexión. Intenta de nuevo.');
    }
  }


  Future<DatauserResponse> dataUser(String userUID) async {
    try {
      final response = await _dio.get(
        'users/datauser/$userUID', // ajusta la ruta según tu API
      );

      return DatauserResponse.fromJsonMap(response.data);
    } on DioException catch (e) {
      // 3) Si el servidor devuelve un error con body JSON
      if (e.response != null &&
          e.response?.data != null &&
          e.response!.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = e.response!.data as Map<String, dynamic>;
        final serverMsg = data['error'] as String? ?? 'Error inesperado al cargar las fotos';
        throw Exception(serverMsg);
      }
      // 4) Otro tipo de fallo (red, timeouts, etc.)
      throw Exception('Error de conexión. Intenta de nuevo.');
    }
  }


  Future<Map<String, dynamic>> logout(String userUID) async {

    try {
      final response = await _dio.post(
        'auth/logout',
        data: {
          'userUID': userUID,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final serverMsg = e.response!.data['error'] as String? ?? 'Error al cerrar sesión';
        throw Exception(serverMsg);
      }
      throw Exception('Error de conexión. Intenta de nuevo.');
    }
  }

}
