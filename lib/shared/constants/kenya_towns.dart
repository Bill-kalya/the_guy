class KenyaTown {
  final String name;
  final String county;
  final double latitude;
  final double longitude;

  const KenyaTown({
    required this.name,
    required this.county,
    required this.latitude,
    required this.longitude,
  });
}

const kenyaTowns = <KenyaTown>[
  KenyaTown(name: 'Nairobi', county: 'Nairobi', latitude: -1.286389, longitude: 36.817223),
  KenyaTown(name: 'Mombasa', county: 'Mombasa', latitude: -4.0435, longitude: 39.6682),
  KenyaTown(name: 'Kisumu', county: 'Kisumu', latitude: -0.0917, longitude: 34.768),
  KenyaTown(name: 'Nakuru', county: 'Nakuru', latitude: -0.3031, longitude: 36.08),
  KenyaTown(name: 'Eldoret', county: 'Uasin Gishu', latitude: 0.5143, longitude: 35.2698),
  KenyaTown(name: 'Thika', county: 'Kiambu', latitude: -1.0333, longitude: 37.0667),
  KenyaTown(name: 'Kitui', county: 'Kitui', latitude: -1.3667, longitude: 38.0167),
  KenyaTown(name: 'Machakos', county: 'Machakos', latitude: -1.5177, longitude: 37.2634),
  KenyaTown(name: 'Nyeri', county: 'Nyeri', latitude: -0.4167, longitude: 36.95),
  KenyaTown(name: 'Meru', county: 'Meru', latitude: 0.05, longitude: 37.65),
  KenyaTown(name: 'Kakamega', county: 'Kakamega', latitude: 0.2844, longitude: 34.7523),
  KenyaTown(name: 'Nanyuki', county: 'Laikipia', latitude: 0.012, longitude: 37.0745),
  KenyaTown(name: 'Naivasha', county: 'Nakuru', latitude: -0.7172, longitude: 36.431),
  KenyaTown(name: 'Malindi', county: 'Kilifi', latitude: -3.2125, longitude: 40.1169),
  KenyaTown(name: 'Garissa', county: 'Garissa', latitude: -0.4569, longitude: 39.6584),
  KenyaTown(name: 'Kericho', county: 'Kericho', latitude: -0.3689, longitude: 35.2836),
  KenyaTown(name: 'Embu', county: 'Embu', latitude: -0.5312, longitude: 37.4506),
  KenyaTown(name: 'Lamu', county: 'Lamu', latitude: -2.2713, longitude: 40.902),
];
