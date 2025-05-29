import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upsglam/models/photo_service.dart';
import 'package:upsglam/models/upload_photo_response.dart';
import 'package:upsglam/util/dialog.dart';
import 'package:upsglam/util/imagepicker.dart';

class UploadPhotoScreen extends StatefulWidget {

  final String userUID; 

  const UploadPhotoScreen({super.key, required this.userUID});

  @override
  State<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {

  final List<String> _filters = ['Filtro A', 'Filtro B', 'Filtro C', 'Filtro D', 'Filtro E', 'Filtro F'];
  String? _selectedFilter;

  File? _imageFile;

  Uint8List? _processedImage;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(
        children: [
          SizedBox(width: 96.w, height: 5.h),
          Center(
            child: Text(
              'Sube una foto',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black
              ),
            ),
          ),
          SizedBox(height: 30.h),
          InkWell(
            onTap: () async {
              File _imageFilee = await ImagePickerr().uploadImage('gallery');
              setState(() {
                _imageFile = _imageFilee;
              });
            },
            child: Container(
              width: 300.r,
              height: 180.r,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 231, 229, 229),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: _imageFile == null ? Center(
                child: SizedBox(
                  width: 100.r,   // ancho personalizado para upload.png
                  height: 100.r,  // alto personalizado para upload.png
                  child: Image.asset(
                    'images/upload.png',
                    fit: BoxFit.contain, // o BoxFit.cover si prefieres recorte
                  ),
                ),
              )
              : ClipRRect( //Se muestra la imagen seleccionada
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox.expand(
                  child: Image.file(
                    _imageFile!,
                    fit: BoxFit.cover, // cubre todo el Container
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 30.h),
          
          seleccionarFiltro(),

          SizedBox(height: 30.h),

          Container(
            width: 300.r,
            height: 180.r,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 231, 229, 229),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: _processedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.r), // recorta bordes
                  child: Image.memory(
                    _processedImage!,
                    width: 300.r,
                    height: 180.r,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text(
                    'Resultado',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
            ),

          SizedBox(height: 30.h),
          processPhoto(),
          SizedBox(height: 10.h),
          uploadPhoto(),
        ],
      ))
    );
  }

  Widget processPhoto() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: InkWell(
        onTap: () async {
          try {
            /*UploadPhotoResponse uploadPhotoResponse = await PhotoService().uploadPhoto(
              widget.userUID,
              _imageFile!
            );*/
            final bytes = await PhotoService().procesarImagen(
              userUID: widget.userUID,
              photoFile: _imageFile!,
              tipoFiltro: 'filtroCartoon', // o el que elijas
            );
            setState(() => _processedImage = bytes);
            //print(uploadPhotoResponse.userUID);
          } catch (e) {
            final msg = e.toString().replaceFirst('Exception: ', '');
            // ignore: use_build_context_synchronously
            dialogBuilder(context, msg);
          }
          
        },
        child: Container(
          alignment: Alignment.center,
          width: double.infinity,
          height: 44.h,
          decoration: BoxDecoration(
            color: Colors.blue, 
            borderRadius: BorderRadius.circular(10.r)
          ),
          child: Text(
            'Aplicar Filtro',
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }

  Widget uploadPhoto() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: InkWell(
        onTap: () async {
          //'${userUID}_photo_$tipoFiltro.jpg'
          final tempFile = await PhotoService().bytesToTempFile(
            _processedImage!,
            '${widget.userUID}_photo_filtroSketch.jpg',
          );

          UploadPhotoResponse uploadPhotoResponse = await PhotoService().uploadPhoto(
              widget.userUID,
              tempFile
          );

          print('userUID: ' + uploadPhotoResponse.userUID);
        },
        child: Container(
          alignment: Alignment.center,
          width: double.infinity,
          height: 44.h,
          decoration: BoxDecoration(
            color: Colors.blue, 
            borderRadius: BorderRadius.circular(10.r)
          ),
          child: Text(
            'Publicar Foto',
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }

  Widget seleccionarFiltro() {
    return Container(
      width: 245.w,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text('Elige un filtro'),
          value: _selectedFilter,
          items: _filters.map((f) => DropdownMenuItem(
            value: f,
            child: Text(f),
          )).toList(),
          onChanged: (val) {
            setState(() => _selectedFilter = val);
          },
        ),
      ),
    );
  }

}


