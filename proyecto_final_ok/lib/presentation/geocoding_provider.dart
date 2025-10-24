import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

/// Provider que obtiene una dirección textual a partir de latitud y longitud.
final direccionProvider = FutureProvider.family<String, (double, double)>((
  ref,
  coords,
) async {
  final (lat, lon) = coords;

  try {
    final placemarks = await placemarkFromCoordinates(lat, lon);

    if (placemarks.isEmpty) {
      return 'Ubicación desconocida';
    }

    final lugar = placemarks.first;

    // Construye una descripción legible
    final direccion = [
      lugar.street,
      lugar.locality,
      lugar.subAdministrativeArea,
      lugar.administrativeArea,
      lugar.country,
    ].where((e) => e != null && e.isNotEmpty).join(', ');

    return direccion.isNotEmpty ? direccion : 'Ubicación sin datos';
  } catch (e) {
    return 'Error al obtener dirección: $e';
  }
});
