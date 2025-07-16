import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ECORUTA')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Mediciones'),
            onTap: () {
              context.push('/mediciones');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Mapa'),
            onTap: () {
              // Acción o navegación
              print('Mapa');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.place),
            title: const Text('Lugar'),
            onTap: () {
              // Acción o navegación
              context.push('/lugar');
            },
          ),
        ],
      ),
    );
  }
}
