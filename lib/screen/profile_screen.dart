import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String profileImage =
      'images/cat.png'; // asegúrate de declararla en pubspec.yaml
  final String username = 'Usuario123';
  final String firstName = 'Juan';
  final String lastName = 'Pérez';
  final String birthYear = '1995';
  final String gender = 'Masculino';
  final String email = 'juan.perez@example.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            // Nombre de usuario
            Text(
              username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Foto de perfil
            CircleAvatar(radius: 60, backgroundImage: AssetImage(profileImage)),
            const SizedBox(height: 32),

            // Información del usuario con diseño de dos líneas
            ProfileItem(label: 'Nombre:', value: firstName),
            ProfileItem(label: 'Apellido:', value: lastName),
            ProfileItem(label: 'Año de nacimiento:', value: birthYear),
            ProfileItem(label: 'Sexo:', value: gender),
            ProfileItem(label: 'Correo electrónico:', value: email),
          ],
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
