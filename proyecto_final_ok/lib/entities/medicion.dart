class Medicion {
  final double co2;
  final double pm25;
  final double pm10;
  final double tvoc;
  final double nh3;
  final double co;
  final double latitud;
  final double longitud;
  final String fechaHora;
  final int timestamp;

  Medicion({
    required this.co2,
    required this.pm25,
    required this.pm10,
    required this.tvoc,
    required this.nh3,
    required this.co,
    required this.latitud,
    required this.longitud,
    required this.fechaHora,
    required this.timestamp,
  });

  factory Medicion.fromMap(Map<String, dynamic> data) {
    return Medicion(
      co2: (data['co2'] ?? 0).toDouble(),
      pm25: (data['pm25'] ?? 0).toDouble(),
      pm10: (data['pm10'] ?? 0).toDouble(),
      tvoc: (data['tvoc'] ?? 0).toDouble(),
      nh3: (data['nh3'] ?? 0).toDouble(),
      co: (data['co'] ?? 0).toDouble(),
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
      'pm10': pm10,
      'tvoc': tvoc,
      'nh3': nh3,
      'co': co,
      'latitud': latitud,
      'longitud': longitud,
      'fechaHora': fechaHora,
      'timestamp': timestamp,
    };
  }
}
