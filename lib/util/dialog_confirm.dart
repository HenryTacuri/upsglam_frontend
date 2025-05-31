import 'package:flutter/material.dart';
import 'package:upsglam/auth/auth_screen.dart';

Future<void> dialogConfirm(BuildContext context, String message) {
  
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Usuario creado correctamente',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
                          // ignore: use_build_context_synchronously
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
            child: const Text('Ok'),
          )
        ],
      );
    }
  );

} 
