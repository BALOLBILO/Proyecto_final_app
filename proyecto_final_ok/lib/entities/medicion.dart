class Medicion {
  final double co2;
  final double pm25;
  final double latitud;
  final double longitud;
  final String fechaHora;
  final int timestamp;

  Medicion({
    required this.co2,
    required this.pm25,
    required this.latitud,
    required this.longitud,
    required this.fechaHora,
    required this.timestamp,
  });

  factory Medicion.fromMap(Map<String, dynamic> data) {
    return Medicion(
      co2: (data['co2'] ?? 0).toDouble(),
      pm25: (data['pm25'] ?? 0).toDouble(),
      latitud: (data['latitud'] ?? 0).toDouble(),
      longitud: (data['longitud'] ?? 0).toDouble(),
      fechaHora: data['fechaHora'] ?? '',
      timestamp: (data['timestamp'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'co2': co2,
      'pm25': pm25,
      'latitud': latitud,
      'longitud': longitud,
      'fechaHora': fechaHora,
      'timestamp': timestamp,
    };
  }
}
