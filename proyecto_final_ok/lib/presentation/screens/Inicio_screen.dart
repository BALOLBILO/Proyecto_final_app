import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proyecto_final_ok/presentation/lugar_provider.dart';

class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.place),
            title: const Text('Lugar'),
            onTap: () {
              ref.read(lugarPantalla.notifier).state = 1;
              context.push('/lugar');
            },
          ),
        ],
      ),
    );
  }
}
