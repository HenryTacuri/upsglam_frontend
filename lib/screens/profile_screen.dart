import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upsglam/auth/auth_screen.dart';
import 'package:upsglam/models/datauser_response.dart';
import 'package:upsglam/models/user_service.dart';
import 'package:upsglam/util/dialog.dart';

class ProfileScreen extends StatefulWidget {

  final String userUID; 

  const ProfileScreen({super.key, required this.userUID});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  DatauserResponse? userData;
  bool isLoading = true;

  @override
  void initState()  {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      final response = await UserService().dataUser(widget.userUID);
      setState(() {
        userData = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando datos de usuario: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  CircleAvatar(radius: 60, backgroundImage: userData?.photoUserProfile != null
                      ? NetworkImage(userData!.photoUserProfile)
                      : const AssetImage('images/person.png') as ImageProvider),
                  const SizedBox(height: 32),

                  Text(
                    userData?.username ?? 'Usuario',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  ProfileItem(label: 'Nombre:', value: userData?.firstName ?? '-'),
                  ProfileItem(label: 'Apellido:', value: userData?.lastName ?? '-'),
                  ProfileItem(label: 'Sexo:', value: userData?.gender ?? '-'),
                  ProfileItem(label: 'Correo electrónico:', value: userData?.userEmail ?? '-'),

                  const SizedBox(height: 32),
                  cerrarSesion(),
                ],
              ),
            ),
    );
  } 
  

  Widget cerrarSesion() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: InkWell(
        onTap: () async {
          try {
          showDialog(
              context: context,
              barrierDismissible: false, // para que no se cierre si tocan fuera
              builder: (_) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            await UserService().logout(widget.userUID);
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop(); 
            // Cerrar el diálogo de carga
            // ignore: use_build_context_synchronously
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthScreen())
            ); // Redirigir a l
          } catch (e) {
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop(); 
            // ignore: use_build_context_synchronously
            dialogBuilder(context, 'Error al cerrar sesión: $e');
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
            'Cerrar Sesión',
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
}

class ProfileItem extends StatelessWidget {
  final String label;
  final String value;

  const ProfileItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primera línea: etiqueta a la izquierda
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),

        // Segunda línea: valor centrado
        Center(child: Text(value, style: const TextStyle(fontSize: 16))),
        const SizedBox(height: 12),
        const Divider(thickness: 1),
        const SizedBox(height: 12),
      ],
    );
  }
}