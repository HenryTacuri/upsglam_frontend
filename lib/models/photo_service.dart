import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

import 'package:dio/dio.dart';
import 'package:upsglam/models/photos_user_response.dart';
import 'package:upsglam/models/update_photo_response.dart';
import 'package:upsglam/models/upload_photo_response.dart';

class PhotoService {

    final Dio _dio = Dio(BaseOptions(
    //192.168.18.162
    //192.168.18.20
    baseUrl: "http://192.168.18.20:8080/",
    headers: {
      "Content-Type": "application/json",
    },
  ));

  Future<UploadPhotoResponse> uploadPhoto(
    String userUID,     
    File photoUser,
    File imageFiler,
  ) async {
  
    // 3) Preparar FormData
    final formData = FormData.fromMap({
      'userUID': userUID,
      'photoUser': await MultipartFile.fromFile(
        photoUser.path,
        filename: '${userUID}_photoUser.jpg',
        contentType: DioMediaType('image', 'jpg'),
      ),
      'imageFiler': await MultipartFile.fromFile(
        imageFiler.path,
        filename: '${userUID}_imageFiler.jpg',
        contentType: DioMediaType('image', 'jpg'),
      ),
    });

    try {
      final response = await _dio.post(
        'photos/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return UploadPhotoResponse.fromJsonMap(response.data);
    } on DioException catch (e) {

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

  Future<UploadPhotoResponse> getPhotosUser(String userUID) async {
    try {
      final response = await _dio.get(
        '/photos/getPhotosUser/$userUID', // ajusta la ruta según tu API
      );

      return UploadPhotoResponse.fromJsonMap(response.data);
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

  Future<List<PhotosUserResponse>> getPhotosUsers() async {
    try {
      final response = await _dio.get('photos/upload');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((e) => PhotosUserResponse.fromJsonMap(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Error ${response.statusCode}: '
            '${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null &&
          e.response!.data is Map<String, dynamic>) {
        final serverMsg =
            (e.response!.data as Map<String, dynamic>)['error']
                as String? ??
            'Error inesperado al cargar las fotos';
        throw Exception(serverMsg);
      }
      throw Exception('Error de conexión. Intenta de nuevo.');
    }
  }

  Future<Uint8List> procesarImagen({
    required String userUID,
    required File photoFile,
    required String tipoFiltro,
  }) async {
    // 1) Construye el MultipartFile a partir del File local
    final multipartImage = await MultipartFile.fromFile(
      photoFile.path,
      filename: '${userUID}_photo_$tipoFiltro.jpg',
    );

    // 2) Empaqueta en FormData
    final formData = FormData.fromMap({
      'imagen': multipartImage,
      'tipoFiltro': tipoFiltro,
    });

    // 3) Haz la petición, pidiendo bytes en la respuesta
    final response = await _dio.post<Uint8List>(
      'processphoto/pycuda',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        responseType: ResponseType.bytes,         // para recibir Uint8List
        validateStatus: (status) => status! < 500, // lanza excepciones solo si status ≥500
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data!;
    } else {
      throw Exception(
          'Error ${response.statusCode}: ${response.statusMessage}');
    }
  }
  
  Future<File> bytesToTempFile(Uint8List bytes, String filename) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<UpdatePhotoResponse> updatePhoto(
    String userUID,
    String oldUrlPhoto,     
    File photo,
  ) async {
  
    // 3) Preparar FormData
    final formData = FormData.fromMap({
      'userUID': userUID,
      'oldUrlPhoto': oldUrlPhoto,
      'photo': await MultipartFile.fromFile(
        photo.path,
        filename: '${userUID}_photoUser.jpg',
        contentType: DioMediaType('image', 'jpg'),
      ),
    });

    try {
      final response = await _dio.post(
        'photos/updatePhoto',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return UpdatePhotoResponse.fromJsonMap(response.data);
    } on DioException catch (e) {

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

  Future<Map<String, dynamic>> deletePhoto({
    required String userUID,
    required String urlPhoto,
  }) async {
    try {
      final response = await _dio.delete(
        'photos/deletePhoto',
        data: {
          'userUID': userUID,
          'urlPhoto': urlPhoto,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final serverMsg = e.response!.data['message'] as String? ?? 'Error al eliminar la foto';
        throw Exception(serverMsg);
      }
      throw Exception('Error de conexión. Intenta de nuevo.');
    }
  }

}

