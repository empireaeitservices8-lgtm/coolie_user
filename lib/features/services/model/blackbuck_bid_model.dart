class BlackbuckBidModel {
  final String id;
  final String transporterName;
  final double rating;
  final int reviewsCount;
  final String price;
  final String vehicleType;
  final String eta;
  final String imagePath;
  final String driverName;
  final String driverPhone;
  final String truckNumber;
  final String insuranceStatus;
  final int tripsCompleted;

  const BlackbuckBidModel({
    required this.id,
    required this.transporterName,
    required this.rating,
    required this.reviewsCount,
    required this.price,
    required this.vehicleType,
    required this.eta,
    required this.imagePath,
    required this.driverName,
    required this.driverPhone,
    required this.truckNumber,
    this.insuranceStatus = 'Verified & Insured',
    this.tripsCompleted = 320,
  });

  static List<BlackbuckBidModel> getSampleBids() {
    return const [
      BlackbuckBidModel(
        id: 'BID-001',
        transporterName: 'Sri Balaji Transport',
        rating: 4.8,
        reviewsCount: 256,
        price: '₹18,500',
        vehicleType: 'Open Body (20T)',
        eta: 'ETA: 3h 30m',
        imagePath: 'assets/images/dash_blackbuck_clean.png',
        driverName: 'Ramesh Balaji',
        driverPhone: '+91 98451 22340',
        truckNumber: 'KL 07 CD 4482',
        tripsCompleted: 450,
      ),
      BlackbuckBidModel(
        id: 'BID-002',
        transporterName: 'Kerala Logistics',
        rating: 4.6,
        reviewsCount: 189,
        price: '₹19,200',
        vehicleType: 'Container (15T)',
        eta: 'ETA: 4h 15m',
        imagePath: 'assets/images/splash_truck_clean.png',
        driverName: 'Suresh Menon',
        driverPhone: '+91 98765 43210',
        truckNumber: 'KL 11 AQ 9821',
        tripsCompleted: 280,
      ),
      BlackbuckBidModel(
        id: 'BID-003',
        transporterName: 'Nila Transports',
        rating: 4.5,
        reviewsCount: 120,
        price: '₹20,500',
        vehicleType: 'Open Body (20T)',
        eta: 'ETA: 4h 30m',
        imagePath: 'assets/images/cooli_truck_exact.png',
        driverName: 'Anil Kumar',
        driverPhone: '+91 94471 88920',
        truckNumber: 'KL 08 BX 1109',
        tripsCompleted: 195,
      ),
      BlackbuckBidModel(
        id: 'BID-004',
        transporterName: 'Coastal Freight',
        rating: 4.3,
        reviewsCount: 96,
        price: '₹21,000',
        vehicleType: 'Tipper (12T)',
        eta: 'ETA: 5h 10m',
        imagePath: 'assets/images/lorry_3d.png',
        driverName: 'Mathew George',
        driverPhone: '+91 98230 45671',
        truckNumber: 'KL 04 EP 6512',
        tripsCompleted: 140,
      ),
      BlackbuckBidModel(
        id: 'BID-005',
        transporterName: 'Southern Express Freight',
        rating: 4.9,
        reviewsCount: 340,
        price: '₹21,800',
        vehicleType: 'Container (20T)',
        eta: 'ETA: 3h 45m',
        imagePath: 'assets/images/truck_3d.png',
        driverName: 'Vijay Raghavan',
        driverPhone: '+91 97890 12345',
        truckNumber: 'KL 14 DF 7731',
        tripsCompleted: 520,
      ),
    ];
  }
}
