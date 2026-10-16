import 'dart:math' as math;

class BlackbuckLoadModel {
  final String id;
  final int? numericId;
  final int? userId;
  final String status;
  final bool isNew;
  final String loadingPoint;
  final String loadingAddressNote;
  final String unloadingPoint;
  final String unloadingAddressNote;
  final String distance;
  final double? distanceInKm;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropLatitude;
  final double? dropLongitude;
  final String truckType;
  final String capacity;
  final String wheelers;
  final String product;
  final String paymentTerms;
  final String totalLoad;
  final String pricingTitle;
  final String totalEarnings;
  final String paymentNote;
  final String transporterName;
  final String contactPerson;
  final String phoneNumber;
  final double rating;
  final String loadsFrom;
  final String vehicleCategory;
  final String route;
  final String? pickupCity;
  final String? pickupState;
  final String? dropCity;
  final String? dropState;
  final String? pickupDate;
  final String? pickupTime;
  final String? expectedFareMin;
  final String? expectedFareMax;
  final String? specialRequirements;
  final String? createdAt;
  final String? updatedAt;
  final String? bookingId;
  final String? bookingStatus;
  final String? finalFare;
  final String? bidAmount;
  final String? driverName;
  final String? driverMobileNumber;
  final String? truckNumber;
  final int? etaHours;
  final String? podOtp;
  final int? transporterId;
  final int? bidId;
  final String? userMobile;
  final String? statusDisplay;
  final String? materialTypeDisplay;
  final String? truckTypeDisplay;
  final String? podPhoto;
  final String? podSignature;
  final String? driverAssignedTime;
  final String? deliveryTime;

  const BlackbuckLoadModel({
    required this.id,
    this.numericId,
    this.userId,
    this.status = 'bidding',
    this.isNew = false,
    required this.loadingPoint,
    this.loadingAddressNote = 'Address will be shared on call',
    required this.unloadingPoint,
    this.unloadingAddressNote = 'Address will be shared on call',
    required this.distance,
    this.distanceInKm,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropLatitude,
    this.dropLongitude,
    required this.truckType,
    required this.capacity,
    required this.wheelers,
    required this.product,
    this.paymentTerms = 'Advance 80% / To Pay',
    required this.totalLoad,
    this.pricingTitle = 'Pricing and Payment Details (Negotiable)',
    this.totalEarnings = 'Will be shared on call',
    this.paymentNote =
        'Full amount will be paid to the driver at the unloading point',
    required this.transporterName,
    required this.contactPerson,
    required this.phoneNumber,
    this.rating = 4.5,
    required this.loadsFrom,
    required this.vehicleCategory,
    this.route = 'Kochi - Calicut',
    this.pickupCity,
    this.pickupState,
    this.dropCity,
    this.dropState,
    this.pickupDate,
    this.pickupTime,
    this.expectedFareMin,
    this.expectedFareMax,
    this.specialRequirements,
    this.createdAt,
    this.updatedAt,
    this.bookingId,
    this.bookingStatus,
    this.finalFare,
    this.bidAmount,
    this.driverName,
    this.driverMobileNumber,
    this.truckNumber,
    this.etaHours,
    this.podOtp,
    this.transporterId,
    this.bidId,
    this.userMobile,
    this.statusDisplay,
    this.materialTypeDisplay,
    this.truckTypeDisplay,
    this.podPhoto,
    this.podSignature,
    this.driverAssignedTime,
    this.deliveryTime,
  });

  /// Helper to check if driver is assigned
  bool get hasDriverAssigned =>
      (driverName != null && driverName!.trim().isNotEmpty) ||
      (truckNumber != null && truckNumber!.trim().isNotEmpty);

  /// Helper to get formatted status badge label
  String get statusBadgeLabel {
    if (bookingStatus != null &&
        bookingStatus!.toLowerCase() == 'confirmed') {
      return 'CONFIRMED';
    }
    if (statusDisplay != null && statusDisplay!.isNotEmpty) {
      return statusDisplay!.toUpperCase();
    }
    if (isConfirmedBooking) {
      return 'CONFIRMED';
    }
    switch (status.toLowerCase()) {
      case 'bidding':
        return 'BIDDING OPEN';
      case 'bid_accepted':
        return 'BID ACCEPTED';
      case 'created':
      case 'open':
        return 'NEW LOAD';
      case 'in_transit':
        return 'IN TRANSIT';
      case 'completed':
        return 'COMPLETED';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Helper to check if load is currently accepting bids
  bool get isBiddingOpen =>
      !isConfirmedBooking &&
      (status.toLowerCase() == 'bidding' || status.toLowerCase() == 'open');

  /// Helper to check if a bid was accepted
  bool get isBidAccepted => status.toLowerCase() == 'bid_accepted';

  /// Helper to check if load has a confirmed booking
  bool get isConfirmedBooking =>
      (bookingStatus != null &&
          bookingStatus!.toLowerCase() == 'confirmed') ||
      isBidAccepted;

  /// Helper to get formatted final fare
  String get formattedFinalFare {
    if (finalFare != null && finalFare!.isNotEmpty) {
      return _formatRupees(finalFare!);
    }
    if (bidAmount != null && bidAmount!.isNotEmpty) {
      return _formatRupees(bidAmount!);
    }
    return totalEarnings;
  }

  /// Formatted Pickup Schedule (e.g. "10 Oct 2026 • 09:00 AM")
  String get formattedPickupSchedule {
    if (pickupDate == null || pickupDate!.isEmpty) return '';
    try {
      final dateParts = pickupDate!.split('-');
      if (dateParts.length == 3) {
        final year = dateParts[0];
        final monthNum = int.tryParse(dateParts[1]) ?? 1;
        final day = dateParts[2];
        const monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        final monthStr = monthNames[(monthNum - 1).clamp(0, 11)];

        String timeStr = '';
        if (pickupTime != null && pickupTime!.isNotEmpty) {
          final timeParts = pickupTime!.split(':');
          if (timeParts.length >= 2) {
            int hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = timeParts[1];
            final period = hour >= 12 ? 'PM' : 'AM';
            if (hour > 12) hour -= 12;
            if (hour == 0) hour = 12;
            final hourStr = hour.toString().padLeft(2, '0');
            timeStr = ' • $hourStr:$minute $period';
          }
        }
        return '$day $monthStr $year$timeStr';
      }
    } catch (_) {}
    return '$pickupDate ${pickupTime ?? ''}'.trim();
  }

  /// Distance in km calculated from pickup latitude/longitude and drop latitude/longitude
  /// using the standard Haversine formula
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double p = 0.017453292519943295; // pi / 180
    final double a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(math.max(0.0, a))); // 2 * R, R = 6371 km
  }

  static List<BlackbuckLoadModel> getSampleLoads() {
    return [
      const BlackbuckLoadModel(
        id: 'LOAD-2026-002',
        numericId: 2,
        userId: 1,
        status: 'bidding',
        isNew: true,
        loadingPoint: 'Kochi, Kerala',
        loadingAddressNote: 'Exact loading point shared on call',
        unloadingPoint: 'Calicut, Kerala',
        unloadingAddressNote: 'Unloading point confirmed with receiver',
        pickupLatitude: 9.931200,
        pickupLongitude: 76.267300,
        dropLatitude: 11.258800,
        dropLongitude: 75.780400,
        distanceInKm: 156.9,
        distance: '156.9 km',
        truckType: 'Open Body (10-20T)',
        capacity: '15 TON',
        wheelers: '10-12 Wheeler',
        product: 'Construction Material',
        paymentTerms: 'Advance 80% / To Pay',
        totalLoad: '15 ton',
        pricingTitle: 'Pricing and Payment Details (Negotiable)',
        totalEarnings: '₹ 18,000 - ₹ 22,000',
        paymentNote:
            'Full amount will be paid to the driver at the unloading point',
        transporterName: 'COOLIE FREIGHT NETWORK',
        contactPerson: 'Dispatch Manager',
        phoneNumber: '+91 98451 23456',
        rating: 4.8,
        loadsFrom: 'Kochi',
        vehicleCategory: 'Open',
        route: 'Kochi - Calicut',
        pickupCity: 'Kochi',
        pickupState: 'Kerala',
        dropCity: 'Calicut',
        dropState: 'Kerala',
        pickupDate: '2026-10-10',
        pickupTime: '09:00:00',
        expectedFareMin: '18000.00',
        expectedFareMax: '22000.00',
      ),
      const BlackbuckLoadModel(
        id: 'LOAD-2026-001',
        numericId: 1,
        userId: 1,
        status: 'bid_accepted',
        isNew: false,
        loadingPoint: 'Kochi, Kerala',
        loadingAddressNote: 'Exact loading point shared on call',
        unloadingPoint: 'Calicut, Kerala',
        unloadingAddressNote: 'Unloading point confirmed with receiver',
        pickupLatitude: 9.931200,
        pickupLongitude: 76.267300,
        dropLatitude: 11.258800,
        dropLongitude: 75.780400,
        distanceInKm: 156.9,
        distance: '156.9 km',
        truckType: 'Open Body (10-20T)',
        capacity: '15 TON',
        wheelers: '10-12 Wheeler',
        product: 'Construction Material',
        paymentTerms: 'Advance 80% / To Pay',
        totalLoad: '15 ton',
        pricingTitle: 'Pricing and Payment Details (Negotiable)',
        totalEarnings: '₹ 18,000 - ₹ 22,000',
        paymentNote:
            'Full amount will be paid to the driver at the unloading point',
        transporterName: 'COOLIE FREIGHT NETWORK',
        contactPerson: 'Dispatch Manager',
        phoneNumber: '+91 98451 23456',
        rating: 4.6,
        loadsFrom: 'Kochi',
        vehicleCategory: 'Open',
        route: 'Kochi - Calicut',
        pickupCity: 'Kochi',
        pickupState: 'Kerala',
        dropCity: 'Calicut',
        dropState: 'Kerala',
        pickupDate: '2026-10-10',
        pickupTime: '09:00:00',
        expectedFareMin: '18000.00',
        expectedFareMax: '22000.00',
      ),
      const BlackbuckLoadModel(
        id: 'BL-1003',
        isNew: true,
        loadingPoint: 'Aluva, Kerala',
        loadingAddressNote: 'Address will be shared on call',
        unloadingPoint: 'Salem, Tamil Nadu',
        unloadingAddressNote: 'Address will be shared on call',
        pickupLatitude: 10.1076,
        pickupLongitude: 76.3516,
        dropLatitude: 11.6643,
        dropLongitude: 78.1460,
        distanceInKm: 263.2,
        distance: '263.2 km',
        truckType: 'Container Box',
        capacity: '18-20 TON',
        wheelers: '10 Wheeler',
        product: 'Plastic Granules',
        paymentTerms: 'Advance 80%',
        totalLoad: '18-20 ton',
        pricingTitle: 'Pricing and Payment Details (Fixed)',
        totalEarnings: '₹ 24,500',
        paymentNote: '80% advance via bank transfer on loading, 20% on POD',
        transporterName: 'DECCAN CARGO MOVERS',
        contactPerson: 'Rajesh Varma',
        phoneNumber: '+91 97401 55432',
        rating: 4.0,
        loadsFrom: 'Aluva',
        vehicleCategory: 'Container',
        route: 'Aluva - Salem',
      ),
      const BlackbuckLoadModel(
        id: 'BL-1004',
        isNew: false,
        loadingPoint: 'Ernakulam, Kerala',
        loadingAddressNote: 'Address will be shared on call',
        unloadingPoint: 'Bengaluru, Karnataka',
        unloadingAddressNote: 'Address will be shared on call',
        pickupLatitude: 9.9816,
        pickupLongitude: 76.2999,
        dropLatitude: 12.9716,
        dropLongitude: 77.5946,
        distanceInKm: 365.4,
        distance: '365.4 km',
        truckType: '32 Ft Multi-Axle',
        capacity: '25-30 TON',
        wheelers: '14 Wheeler',
        product: 'FMCG / Packaged Food',
        paymentTerms: 'To Pay',
        totalLoad: '26 ton',
        pricingTitle: 'Pricing and Payment Details (Negotiable)',
        totalEarnings: '₹ 32,000 - ₹ 36,000',
        paymentNote:
            'Full amount will be paid to the driver at the unloading point',
        transporterName: 'SOUTH EXPRESS LOGISTICS',
        contactPerson: 'K. Venkatesh Rao',
        phoneNumber: '+91 98220 89412',
        rating: 4.5,
        loadsFrom: 'Ernakulam',
        vehicleCategory: 'Open',
        route: 'Ernakulam - Bengaluru',
      ),
    ];
  }

  factory BlackbuckLoadModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['load_id']?.toString() ??
        json['id']?.toString() ??
        'LOAD-2026-002';
    final numericId = int.tryParse(json['id']?.toString() ?? '');
    final userId = int.tryParse(json['user']?.toString() ?? '');
    final status = json['status']?.toString().toLowerCase() ?? 'bidding';

    final pickupLoc = json['pickup_location']?.toString() ?? '';
    final pickupCity = json['pickup_city']?.toString() ?? '';
    final pickupState = json['pickup_state']?.toString() ?? '';

    final dropLoc = json['drop_location']?.toString() ?? '';
    final dropCity = json['drop_city']?.toString() ?? '';
    final dropState = json['drop_state']?.toString() ?? '';

    String loadingPoint = pickupLoc.isNotEmpty
        ? pickupLoc
        : (pickupCity.isNotEmpty ? pickupCity : 'Kochi');
    if (pickupState.isNotEmpty && !loadingPoint.contains(pickupState)) {
      loadingPoint = '$loadingPoint, $pickupState';
    }

    String unloadingPoint = dropLoc.isNotEmpty
        ? dropLoc
        : (dropCity.isNotEmpty ? dropCity : 'Calicut');
    if (dropState.isNotEmpty && !unloadingPoint.contains(dropState)) {
      unloadingPoint = '$unloadingPoint, $dropState';
    }

    final minFare = json['expected_fare_min']?.toString();
    final maxFare = json['expected_fare_max']?.toString();

    String priceText = 'Will be shared on call';
    if (minFare != null && maxFare != null) {
      final formattedMin = _formatRupees(minFare);
      final formattedMax = _formatRupees(maxFare);
      priceText = '$formattedMin - $formattedMax';
    } else if (minFare != null) {
      priceText = _formatRupees(minFare);
    }

    final rawTruck = json['truck_type']?.toString() ?? 'open_body_10_20t';
    final truckName = _formatTruckType(rawTruck);
    String category = 'Open';
    final lowerTruck = rawTruck.toLowerCase();
    if (lowerTruck.contains('container')) {
      category = 'Container';
    } else if (lowerTruck.contains('trailer') ||
        lowerTruck.contains('flatbed')) {
      category = 'Trailer';
    } else if (lowerTruck.contains('tipper')) {
      category = 'Tipper';
    } else if (lowerTruck.contains('lcv')) {
      category = 'LCV';
    } else if (lowerTruck.contains('tanker')) {
      category = 'Tanker';
    } else if (lowerTruck.contains('dumper')) {
      category = 'Dumper';
    } else if (lowerTruck.contains('bulker')) {
      category = 'Bulker';
    }

    final rawWeight = json['load_weight']?.toString() ?? '15';
    final weightTon =
        double.tryParse(rawWeight)?.toStringAsFixed(0) ?? rawWeight;

    final rawMaterial =
        json['material_type']?.toString() ?? 'construction_material';
    final product = _formatMaterial(rawMaterial);

    // Calculate distance strictly from pickup latitude & longitude and drop latitude & longitude
    final pLat = double.tryParse(json['pickup_latitude']?.toString() ?? '');
    final pLng = double.tryParse(json['pickup_longitude']?.toString() ?? '');
    final dLat = double.tryParse(json['drop_latitude']?.toString() ?? '');
    final dLng = double.tryParse(json['drop_longitude']?.toString() ?? '');

    double? calculatedKm;
    String distStr = '';
    if (json['distance_km'] != null &&
        json['distance_km'].toString().isNotEmpty) {
      calculatedKm = double.tryParse(json['distance_km'].toString());
      if (calculatedKm != null) {
        distStr = '${calculatedKm.toStringAsFixed(1)} km';
      }
    }
    if (distStr.isEmpty &&
        pLat != null &&
        pLng != null &&
        dLat != null &&
        dLng != null) {
      calculatedKm = calculateDistanceKm(
        lat1: pLat,
        lon1: pLng,
        lat2: dLat,
        lon2: dLng,
      );
      distStr = '${calculatedKm.toStringAsFixed(1)} km';
    } else if (distStr.isEmpty &&
        json['distance'] != null &&
        json['distance'].toString().isNotEmpty) {
      distStr = json['distance'].toString();
      if (!distStr.toLowerCase().contains('km')) {
        distStr = '$distStr km';
      }
    } else if (distStr.isEmpty) {
      distStr = '156.9 km';
    }

    final cityFrom = pickupCity.isNotEmpty
        ? pickupCity
        : (pickupLoc.isNotEmpty
            ? pickupLoc.split(',').first.trim()
            : 'Kochi');
    final cityTo = dropCity.isNotEmpty
        ? dropCity
        : (dropLoc.isNotEmpty ? dropLoc.split(',').first.trim() : 'Calicut');

    return BlackbuckLoadModel(
      id: rawId,
      numericId: numericId,
      userId: userId,
      status: status,
      isNew: status == 'created' || status == 'open',
      loadingPoint: loadingPoint,
      loadingAddressNote: json['loading_address_note']?.toString() ??
          'Exact loading address shared on call',
      unloadingPoint: unloadingPoint,
      unloadingAddressNote: json['unloading_address_note']?.toString() ??
          'Unloading address confirmed with consignee',
      distance: distStr,
      distanceInKm: calculatedKm,
      pickupLatitude: pLat,
      pickupLongitude: pLng,
      dropLatitude: dLat,
      dropLongitude: dLng,
      truckType: truckName,
      capacity: '$weightTon TON',
      wheelers: json['wheelers']?.toString() ?? '10-12 Wheeler',
      product: product,
      paymentTerms:
          json['payment_terms']?.toString() ?? 'Advance 80% / To Pay',
      totalLoad: '$weightTon ton',
      pricingTitle: 'Pricing and Payment Details (Negotiable)',
      totalEarnings: priceText,
      paymentNote:
          'Full amount will be paid to the driver at the unloading point',
      transporterName: json['transporter_name']?.toString() ??
          'COOLIE FREIGHT NETWORK',
      contactPerson: json['contact_person']?.toString() ?? 'Dispatch Manager',
      phoneNumber: json['phone_number']?.toString() ?? '+91 98451 23456',
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : 4.8,
      loadsFrom: cityFrom,
      vehicleCategory: category,
      route: '$cityFrom - $cityTo',
      pickupCity: pickupCity,
      pickupState: pickupState,
      dropCity: dropCity,
      dropState: dropState,
      pickupDate: json['pickup_date']?.toString(),
      pickupTime: json['pickup_time']?.toString(),
      expectedFareMin: minFare,
      expectedFareMax: maxFare,
      specialRequirements: json['special_requirements']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      bookingId: json['booking_id']?.toString(),
      bookingStatus: json['booking_status']?.toString(),
      finalFare: json['final_fare']?.toString(),
    );
  }

  BlackbuckLoadModel copyWith({
    String? id,
    int? numericId,
    int? userId,
    String? status,
    bool? isNew,
    String? loadingPoint,
    String? loadingAddressNote,
    String? unloadingPoint,
    String? unloadingAddressNote,
    String? distance,
    double? distanceInKm,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropLatitude,
    double? dropLongitude,
    String? truckType,
    String? capacity,
    String? wheelers,
    String? product,
    String? paymentTerms,
    String? totalLoad,
    String? pricingTitle,
    String? totalEarnings,
    String? paymentNote,
    String? transporterName,
    String? contactPerson,
    String? phoneNumber,
    double? rating,
    String? loadsFrom,
    String? vehicleCategory,
    String? route,
    String? pickupCity,
    String? pickupState,
    String? dropCity,
    String? dropState,
    String? pickupDate,
    String? pickupTime,
    String? expectedFareMin,
    String? expectedFareMax,
    String? specialRequirements,
    String? createdAt,
    String? updatedAt,
    String? bookingId,
    String? bookingStatus,
    String? finalFare,
    String? bidAmount,
    String? driverName,
    String? driverMobileNumber,
    String? truckNumber,
    int? etaHours,
    String? podOtp,
    int? transporterId,
    int? bidId,
    String? userMobile,
    String? statusDisplay,
    String? materialTypeDisplay,
    String? truckTypeDisplay,
    String? podPhoto,
    String? podSignature,
    String? driverAssignedTime,
    String? deliveryTime,
  }) {
    return BlackbuckLoadModel(
      id: id ?? this.id,
      numericId: numericId ?? this.numericId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      isNew: isNew ?? this.isNew,
      loadingPoint: loadingPoint ?? this.loadingPoint,
      loadingAddressNote: loadingAddressNote ?? this.loadingAddressNote,
      unloadingPoint: unloadingPoint ?? this.unloadingPoint,
      unloadingAddressNote: unloadingAddressNote ?? this.unloadingAddressNote,
      distance: distance ?? this.distance,
      distanceInKm: distanceInKm ?? this.distanceInKm,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      dropLatitude: dropLatitude ?? this.dropLatitude,
      dropLongitude: dropLongitude ?? this.dropLongitude,
      truckType: truckType ?? this.truckType,
      capacity: capacity ?? this.capacity,
      wheelers: wheelers ?? this.wheelers,
      product: product ?? this.product,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      totalLoad: totalLoad ?? this.totalLoad,
      pricingTitle: pricingTitle ?? this.pricingTitle,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      paymentNote: paymentNote ?? this.paymentNote,
      transporterName: transporterName ?? this.transporterName,
      contactPerson: contactPerson ?? this.contactPerson,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      rating: rating ?? this.rating,
      loadsFrom: loadsFrom ?? this.loadsFrom,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      route: route ?? this.route,
      pickupCity: pickupCity ?? this.pickupCity,
      pickupState: pickupState ?? this.pickupState,
      dropCity: dropCity ?? this.dropCity,
      dropState: dropState ?? this.dropState,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupTime: pickupTime ?? this.pickupTime,
      expectedFareMin: expectedFareMin ?? this.expectedFareMin,
      expectedFareMax: expectedFareMax ?? this.expectedFareMax,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookingId: bookingId ?? this.bookingId,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      finalFare: finalFare ?? this.finalFare,
      bidAmount: bidAmount ?? this.bidAmount,
      driverName: driverName ?? this.driverName,
      driverMobileNumber: driverMobileNumber ?? this.driverMobileNumber,
      truckNumber: truckNumber ?? this.truckNumber,
      etaHours: etaHours ?? this.etaHours,
      podOtp: podOtp ?? this.podOtp,
      transporterId: transporterId ?? this.transporterId,
      bidId: bidId ?? this.bidId,
      userMobile: userMobile ?? this.userMobile,
      statusDisplay: statusDisplay ?? this.statusDisplay,
      materialTypeDisplay: materialTypeDisplay ?? this.materialTypeDisplay,
      truckTypeDisplay: truckTypeDisplay ?? this.truckTypeDisplay,
      podPhoto: podPhoto ?? this.podPhoto,
      podSignature: podSignature ?? this.podSignature,
      driverAssignedTime: driverAssignedTime ?? this.driverAssignedTime,
      deliveryTime: deliveryTime ?? this.deliveryTime,
    );
  }

  factory BlackbuckLoadModel.fromBookingJson(Map<String, dynamic> json) {
    final bookingId = json['booking_id']?.toString() ?? 'CL-20261005-4950';
    final bookingStatus =
        json['status']?.toString().toLowerCase() ?? 'confirmed';
    final finalFare = json['final_fare']?.toString();
    final truckNum = json['truck_number']?.toString();
    final driverName = json['driver_name']?.toString();
    final driverPhone = json['driver_mobile_number']?.toString();
    final podOtp = json['POD_otp']?.toString();
    final bookingCreatedAt = json['created_at']?.toString();
    final bookingUpdatedAt = json['updated_at']?.toString();

    final loadMap = (json['load_details'] is Map<String, dynamic>)
        ? json['load_details'] as Map<String, dynamic>
        : (json['load'] is Map<String, dynamic>
            ? json['load'] as Map<String, dynamic>
            : <String, dynamic>{});

    final bidMap = (json['bid_details'] is Map<String, dynamic>)
        ? json['bid_details'] as Map<String, dynamic>
        : (json['bid'] is Map<String, dynamic>
            ? json['bid'] as Map<String, dynamic>
            : <String, dynamic>{});

    // Parse base load from load_details if available, else json
    final baseLoad = loadMap.isNotEmpty
        ? BlackbuckLoadModel.fromJson(loadMap)
        : BlackbuckLoadModel.fromJson(json);

    // Bid details extraction
    final transporterName = bidMap['transporter_name']?.toString().trim();
    final bidAmt = bidMap['bid_amount']?.toString();
    final bidTruckType = bidMap['truck_type']?.toString();
    final etaHours = bidMap['eta_hours'] is int
        ? bidMap['eta_hours'] as int
        : int.tryParse(bidMap['eta_hours']?.toString() ?? '');
    final transporterId =
        int.tryParse(bidMap['transporter']?.toString() ?? '');
    final bidId = int.tryParse(
        json['bid']?.toString() ?? bidMap['id']?.toString() ?? '');

    // Formatted earnings/fare
    String fareDisplay = baseLoad.totalEarnings;
    if (finalFare != null && finalFare.isNotEmpty) {
      fareDisplay = _formatRupees(finalFare);
    } else if (bidAmt != null && bidAmt.isNotEmpty) {
      fareDisplay = _formatRupees(bidAmt);
    }

    return baseLoad.copyWith(
      bookingId: bookingId,
      bookingStatus: bookingStatus,
      finalFare: finalFare,
      bidAmount: bidAmt,
      driverName: (driverName != null && driverName.isNotEmpty)
          ? driverName
          : bidMap['driver_name']?.toString(),
      driverMobileNumber: (driverPhone != null && driverPhone.isNotEmpty)
          ? driverPhone
          : bidMap['driver_mobile_number']?.toString(),
      truckNumber: (truckNum != null && truckNum.isNotEmpty)
          ? truckNum
          : bidMap['truck_number']?.toString(),
      etaHours: etaHours,
      podOtp: podOtp,
      transporterId: transporterId,
      bidId: bidId,
      transporterName: (transporterName != null && transporterName.isNotEmpty)
          ? transporterName
          : baseLoad.transporterName,
      truckType: (bidTruckType != null && bidTruckType.isNotEmpty)
          ? bidTruckType
          : baseLoad.truckType,
      totalEarnings: fareDisplay,
      status: baseLoad.status.isNotEmpty ? baseLoad.status : 'bid_accepted',
      createdAt: bookingCreatedAt ?? baseLoad.createdAt,
      updatedAt: bookingUpdatedAt ?? baseLoad.updatedAt,
      userMobile: loadMap['user_mobile']?.toString() ?? baseLoad.userMobile,
      statusDisplay:
          loadMap['status_display']?.toString() ?? baseLoad.statusDisplay,
      materialTypeDisplay: loadMap['material_type_display']?.toString() ??
          baseLoad.materialTypeDisplay,
      truckTypeDisplay: loadMap['truck_type_display']?.toString() ??
          baseLoad.truckTypeDisplay,
      podPhoto: json['POD_photo']?.toString(),
      podSignature: json['POD_signature']?.toString(),
      driverAssignedTime: json['driver_assigned_time']?.toString(),
      deliveryTime: json['delivery_time']?.toString(),
    );
  }

  static String _formatRupees(String amountStr) {
    final d = double.tryParse(amountStr);
    if (d == null) return '₹ $amountStr';
    final intVal = d.round();
    final withCommas = intVal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '₹ $withCommas';
  }

  static String _formatTruckType(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('open_body')) {
      return 'Open Body (10-20T)';
    }
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  static String _formatMaterial(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'numeric_id': numericId,
        'user_id': userId,
        'status': status,
        'loading_point': loadingPoint,
        'unloading_point': unloadingPoint,
        'distance': distance,
        'distance_km': distanceInKm,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'drop_latitude': dropLatitude,
        'drop_longitude': dropLongitude,
        'truck_type': truckType,
        'capacity': capacity,
        'product': product,
        'transporter_name': transporterName,
        'phone_number': phoneNumber,
        'total_earnings': totalEarnings,
        'pickup_date': pickupDate,
        'pickup_time': pickupTime,
        'expected_fare_min': expectedFareMin,
        'expected_fare_max': expectedFareMax,
        'booking_id': bookingId,
        'booking_status': bookingStatus,
        'final_fare': finalFare,
      };
}

class TransportSearchLocation {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final String locationType;

  const TransportSearchLocation({
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.locationType,
  });

  factory TransportSearchLocation.fromJson(Map<String, dynamic> json) {
    return TransportSearchLocation(
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      radiusKm: (json['radius_km'] is num)
          ? (json['radius_km'] as num).toDouble()
          : double.tryParse(json['radius_km']?.toString() ?? '') ?? 50.0,
      locationType: json['location_type']?.toString() ?? 'pickup',
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
        'location_type': locationType,
      };
}

class TransportLocationSearchResult {
  final TransportSearchLocation? searchLocation;
  final int count;
  final List<BlackbuckLoadModel> results;

  const TransportLocationSearchResult({
    this.searchLocation,
    required this.count,
    required this.results,
  });

  factory TransportLocationSearchResult.fromJson(Map<String, dynamic> json) {
    TransportSearchLocation? searchLoc;
    if (json['search_location'] is Map<String, dynamic>) {
      searchLoc = TransportSearchLocation.fromJson(
        json['search_location'] as Map<String, dynamic>,
      );
    }

    final rawResults = json['results'];
    List<BlackbuckLoadModel> loadsList = [];
    if (rawResults is List) {
      loadsList = rawResults
          .whereType<Map<String, dynamic>>()
          .map((item) => BlackbuckLoadModel.fromJson(item))
          .toList();
    }

    return TransportLocationSearchResult(
      searchLocation: searchLoc,
      count: json['count'] is num
          ? (json['count'] as num).toInt()
          : loadsList.length,
      results: loadsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'search_location': searchLocation?.toJson(),
        'count': count,
        'results': results.map((r) => r.toJson()).toList(),
      };
}

class TransportTruckTypeFilter {
  final String truckType;
  final String truckTypeDisplay;
  final String? pickupCity;
  final String? dropCity;
  final String? pickupState;
  final String? dropState;
  final String? status;
  final String? userId;

  const TransportTruckTypeFilter({
    required this.truckType,
    required this.truckTypeDisplay,
    this.pickupCity,
    this.dropCity,
    this.pickupState,
    this.dropState,
    this.status,
    this.userId,
  });

  factory TransportTruckTypeFilter.fromJson(Map<String, dynamic> json) {
    return TransportTruckTypeFilter(
      truckType: json['truck_type']?.toString() ?? '',
      truckTypeDisplay: json['truck_type_display']?.toString() ?? '',
      pickupCity: json['pickup_city']?.toString(),
      dropCity: json['drop_city']?.toString(),
      pickupState: json['pickup_state']?.toString(),
      dropState: json['drop_state']?.toString(),
      status: json['status']?.toString(),
      userId: json['user_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'truck_type': truckType,
        'truck_type_display': truckTypeDisplay,
        'pickup_city': pickupCity,
        'drop_city': dropCity,
        'pickup_state': pickupState,
        'drop_state': dropState,
        'status': status,
        'user_id': userId,
      };
}

class TransportAvailableCities {
  final List<String> pickupCities;
  final List<String> dropCities;

  const TransportAvailableCities({
    this.pickupCities = const [],
    this.dropCities = const [],
  });

  factory TransportAvailableCities.fromJson(Map<String, dynamic> json) {
    final rawPickup = json['pickup_cities'];
    final rawDrop = json['drop_cities'];
    return TransportAvailableCities(
      pickupCities: (rawPickup is List)
          ? rawPickup.map((e) => e.toString()).toSet().toList()
          : const [],
      dropCities: (rawDrop is List)
          ? rawDrop.map((e) => e.toString()).toSet().toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'pickup_cities': pickupCities,
        'drop_cities': dropCities,
      };
}

class TransportTruckTypeSearchResult {
  final TransportTruckTypeFilter? filters;
  final TransportAvailableCities? availableCities;
  final int count;
  final List<BlackbuckLoadModel> results;

  const TransportTruckTypeSearchResult({
    this.filters,
    this.availableCities,
    required this.count,
    required this.results,
  });

  factory TransportTruckTypeSearchResult.fromJson(Map<String, dynamic> json) {
    TransportTruckTypeFilter? filterObj;
    if (json['filters'] is Map<String, dynamic>) {
      filterObj = TransportTruckTypeFilter.fromJson(
        json['filters'] as Map<String, dynamic>,
      );
    }

    TransportAvailableCities? citiesObj;
    if (json['available_cities'] is Map<String, dynamic>) {
      citiesObj = TransportAvailableCities.fromJson(
        json['available_cities'] as Map<String, dynamic>,
      );
    }

    final rawResults = json['results'];
    List<BlackbuckLoadModel> loadsList = [];
    if (rawResults is List) {
      loadsList = rawResults
          .whereType<Map<String, dynamic>>()
          .map((item) => BlackbuckLoadModel.fromJson(item))
          .toList();
    }

    return TransportTruckTypeSearchResult(
      filters: filterObj,
      availableCities: citiesObj,
      count: json['count'] is num
          ? (json['count'] as num).toInt()
          : loadsList.length,
      results: loadsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'filters': filters?.toJson(),
        'available_cities': availableCities?.toJson(),
        'count': count,
        'results': results.map((r) => r.toJson()).toList(),
      };
}

