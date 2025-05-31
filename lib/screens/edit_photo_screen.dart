import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upsglam/models/photo_service.dart';
import 'package:upsglam/models/update_photo_response.dart';
import 'package:upsglam/util/dialog.dart';
import 'package:upsglam/util/imagepicker.dart';

class EditPhotoScreen extends StatefulWidget {

  final String userUID; 
  final File defaultImage;
  final String urlPhoto;
  final String username;
  final String photoUserProfile;      


  const EditPhotoScreen({super.key, required this.userUID, required this.defaultImage, required this.urlPhoto, required this.username, required this.photoUserProfile});

  @override
  State<EditPhotoScreen> createState() => _EditPhotoScreenState();
}

class _EditPhotoScreenState extends State<EditPhotoScreen> {

  final List<String> _filters = ['filtroLog', 'filtroMedia', 'filtroGaussiano', 'filtroCartoon', 'filtroSketch', 'filtroTermico', 'filtroAsciiUps'];

  String? _selectedFilter;

  File? _imageFile;

  Uint8List? _processedImage;

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, size: 24.sp),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(width: 10.w),
              Text(
                'Editar Foto',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          //SizedBox(width: 96.w, height: 5.h),

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
              child: _imageFile != null
                // imagen elegida por el usuario
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.file(
                    _imageFile!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              // imagen por defecto en full container
              : ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.file(
                  widget.defaultImage,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
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
            _imageFile ??= widget.defaultImage;

            showDialog(
              context: context,
              barrierDismissible: false, // para que no se cierre si tocan fuera
              builder: (_) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            final bytes = await PhotoService().procesarImagen(
              userUID: widget.userUID,
              photoFile: _imageFile!,
              tipoFiltro: _selectedFilter!, // o el que elijas
            );
            setState(() => _processedImage = bytes);
            //print(uploadPhotoResponse.userUID);
            Navigator.of(context).pop();
          } catch (e) {
            final msg = e.toString().replaceFirst('Exception: ', '');
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop();
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
          try{
            final tempFile = await PhotoService().bytesToTempFile(
              _processedImage!,
              '${widget.userUID}_$_selectedFilter.jpg',
            );

            showDialog(
              context: context,
              barrierDismissible: false, // para que no se cierre si tocan fuera
              builder: (_) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            UpdatePhotoResponse updatePhotoResponse = await PhotoService().updatePhoto(
                widget.userUID,
                widget.urlPhoto,
                tempFile
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fotografía actualizada con exito'),
              )
            );
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
            'Actualizar Foto',
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


