import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cooli/utils/urls.dart';

class LocationResult {
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final String? placeId;

  const LocationResult({
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });

  String get fullAddress => subtitle.isNotEmpty ? '$title, $subtitle' : title;
}

class RideMapSelectionResult {
  final LocationResult pickup;
  final LocationResult drop;
  final bool isPickupActive;

  const RideMapSelectionResult({
    required this.pickup,
    required this.drop,
    this.isPickupActive = false,
  });

  LocationResult get selected => isPickupActive ? pickup : drop;
}

class RideLocationService {
  final Dio _dio;
  static const String apiKey = googleMapsApiKey;

  RideLocationService({Dio? dio}) : _dio = dio ?? Dio();

  /// Google Places Search Autocomplete (Using official Google Maps API)
  Future<List<LocationResult>> searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const [];

    // 1. Google Places Autocomplete API
    try {
      final legacyUrl =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(cleanQuery)}&components=country:in&key=$apiKey';
      final res = await _dio.get(
        legacyUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      if (res.statusCode == 200 && res.data is Map && res.data['status'] == 'OK') {
        final predictions = res.data['predictions'] as List?;
        if (predictions != null && predictions.isNotEmpty) {
          return predictions.map((item) {
            final mainText = item['structured_formatting']?['main_text']?.toString() ??
                item['description']?.toString() ??
                cleanQuery;
            final secondaryText = item['structured_formatting']?['secondary_text']?.toString() ?? '';
            return LocationResult(
              title: mainText,
              subtitle: secondaryText,
              latitude: 0.0,
              longitude: 0.0,
              placeId: item['place_id']?.toString(),
            );
          }).toList();
        }
      }
    } catch (_) {}

    // 2. Google Places API (New) fallback
    try {
      final newPlacesUrl = 'https://places.googleapis.com/v1/places:autocomplete';
      final response = await _dio.post(
        newPlacesUrl,
        data: {'input': cleanQuery},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
          },
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final suggestions = response.data['suggestions'] as List?;
        if (suggestions != null && suggestions.isNotEmpty) {
          return suggestions.map((s) {
            final p = s['placePrediction'];
            final mainText = p?['structuredFormat']?['mainText']?['text']?.toString() ?? cleanQuery;
            final secondaryText = p?['structuredFormat']?['secondaryText']?['text']?.toString() ?? '';
            return LocationResult(
              title: mainText,
              subtitle: secondaryText,
              latitude: 0.0,
              longitude: 0.0,
              placeId: p?['placeId']?.toString(),
            );
          }).toList();
        }
      }
    } catch (_) {}

    return const [];
  }

  /// Resolves coordinates for a place using Google Place Details or Google Geocoding
  Future<LatLng?> getPlaceCoordinates({String? placeId, String? query}) async {
    if (placeId != null && placeId.isNotEmpty) {
      try {
        final url =
            'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$apiKey';
        final res = await _dio.get(
          url,
          options: Options(
            sendTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
          ),
        );
        if (res.statusCode == 200 && res.data is Map && res.data['status'] == 'OK') {
          final loc = res.data['result']?['geometry']?['location'];
          if (loc != null) {
            final lat = double.tryParse(loc['lat']?.toString() ?? '');
            final lng = double.tryParse(loc['lng']?.toString() ?? '');
            if (lat != null && lng != null) {
              return LatLng(lat, lng);
            }
          }
        }
      } catch (_) {}
    }

    if (query != null && query.isNotEmpty) {
      try {
        final url =
            'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$apiKey';
        final res = await _dio.get(
          url,
          options: Options(
            sendTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
          ),
        );
        if (res.statusCode == 200 && res.data is Map && res.data['status'] == 'OK') {
          final results = res.data['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final loc = results[0]['geometry']?['location'];
            if (loc != null) {
              final lat = double.tryParse(loc['lat']?.toString() ?? '');
              final lng = double.tryParse(loc['lng']?.toString() ?? '');
              if (lat != null && lng != null) {
                return LatLng(lat, lng);
              }
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  /// Regional human-readable fallback when offline - NEVER shows raw coordinates
  static ({String title, String subtitle}) _getRegionFallback(double lat, double lng) {
    if (lat >= 9.85 && lat <= 10.15 && lng >= 76.15 && lng <= 76.45) {
      return (title: 'Kochi Area', subtitle: 'Ernakulam, Kerala');
    }
    if (lat >= 8.40 && lat <= 8.65 && lng >= 76.80 && lng <= 77.05) {
      return (title: 'Thiruvananthapuram', subtitle: 'Kerala');
    }
    if (lat >= 11.15 && lat <= 11.35 && lng >= 75.70 && lng <= 75.90) {
      return (title: 'Kozhikode', subtitle: 'Kerala');
    }
    if (lat >= 10.45 && lat <= 10.60 && lng >= 76.15 && lng <= 76.30) {
      return (title: 'Thrissur', subtitle: 'Kerala');
    }
    if (lat >= 11.70 && lat <= 12.10 && lng >= 75.25 && lng <= 75.80) {
      return (title: 'Kannur', subtitle: 'Kerala');
    }
    if (lat >= 12.80 && lat <= 13.15 && lng >= 77.45 && lng <= 77.75) {
      return (title: 'Bengaluru City', subtitle: 'Karnataka');
    }
    if (lat >= 12.90 && lat <= 13.20 && lng >= 80.10 && lng <= 80.35) {
      return (title: 'Chennai City', subtitle: 'Tamil Nadu');
    }
    if (lat >= 18.90 && lat <= 19.30 && lng >= 72.75 && lng <= 73.05) {
      return (title: 'Mumbai City', subtitle: 'Maharashtra');
    }
    if (lat >= 28.40 && lat <= 28.90 && lng >= 76.90 && lng <= 77.40) {
      return (title: 'New Delhi Region', subtitle: 'Delhi NCR');
    }
    // Kerala wide fallback
    if (lat >= 8.15 && lat <= 12.85 && lng >= 74.85 && lng <= 77.50) {
      return (title: 'Kerala', subtitle: 'India');
    }
    // India wide fallback
    if (lat >= 6.0 && lat <= 37.0 && lng >= 68.0 && lng <= 97.5) {
      return (title: 'Location in India', subtitle: 'India');
    }
    return (title: 'Current Spot', subtitle: 'Map Location');
  }

  /// Multi-tier Reverse Geocoder: Native Device Placemark -> Google Maps API -> OpenStreetMap Nominatim
  Future<LocationResult?> reverseGeocode(double lat, double lng) async {
    // 1. Tier 1: Device Native Geocoder (Uses Android/iOS native system geocoding without requiring API keys)
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final name = p.name?.trim() ?? '';
        final street = (p.street?.trim().isNotEmpty == true)
            ? p.street!.trim()
            : [p.subThoroughfare?.trim(), p.thoroughfare?.trim()]
                .where((s) => s != null && s.isNotEmpty)
                .join(' ');
        final subLocality = p.subLocality?.trim() ?? '';
        final locality = p.locality?.trim() ?? '';
        final subAdmin = p.subAdministrativeArea?.trim() ?? '';
        final admin = p.administrativeArea?.trim() ?? '';
        final postal = p.postalCode?.trim() ?? '';

        String title = '';
        if (name.isNotEmpty &&
            !name.contains('+') &&
            !name.toLowerCase().contains('unnamed')) {
          if (RegExp(r'^\d+$').hasMatch(name) && street.isNotEmpty && !street.toLowerCase().contains('unnamed')) {
            title = '$name, $street';
          } else {
            title = name;
          }
        } else if (street.isNotEmpty && !street.toLowerCase().contains('unnamed')) {
          title = street;
        } else if (subLocality.isNotEmpty) {
          title = subLocality;
        } else if (locality.isNotEmpty) {
          title = locality;
        } else if (subAdmin.isNotEmpty) {
          title = subAdmin;
        } else if (admin.isNotEmpty) {
          title = admin;
        }

        final subParts = <String>[];
        if (street.isNotEmpty && street != title && !street.toLowerCase().contains('unnamed') && !title.contains(street)) {
          subParts.add(street);
        }
        if (subLocality.isNotEmpty && subLocality != title && !subParts.contains(subLocality) && !title.contains(subLocality)) {
          subParts.add(subLocality);
        }
        if (locality.isNotEmpty && locality != title && !subParts.contains(locality) && !title.contains(locality)) {
          subParts.add(locality);
        }
        if (subAdmin.isNotEmpty && subAdmin != title && subAdmin != locality && !subParts.contains(subAdmin) && !title.contains(subAdmin)) {
          subParts.add(subAdmin);
        }
        if (admin.isNotEmpty && admin != title && !subParts.contains(admin) && !title.contains(admin)) {
          subParts.add(admin);
        }
        if (postal.isNotEmpty && !title.contains(postal) && !subParts.contains(postal)) {
          subParts.add(postal);
        }

        if (title.isNotEmpty) {
          final subtitle = subParts.join(', ');
          return LocationResult(
            title: title,
            subtitle: subtitle.isNotEmpty ? subtitle : (locality.isNotEmpty ? locality : 'Selected Address'),
            latitude: lat,
            longitude: lng,
          );
        }
      }
    } catch (e) {
      debugPrint('[RideLocationService] native geocoding error: $e');
    }

    // 2. Tier 2: Google Maps Geocoding REST API
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';
      final res = await _dio.get(
        url,
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      if (res.statusCode == 200 && res.data is Map && res.data['status'] == 'OK') {
        final results = res.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final first = results[0];
          final formatted = first['formatted_address']?.toString() ?? '';

          if (formatted.isNotEmpty && !formatted.toLowerCase().contains('plus code')) {
            String cleanFormatted = formatted;
            if (RegExp(r'^[A-Z0-9]{4,8}\+[A-Z0-9]{2,4}[,\s]+').hasMatch(cleanFormatted)) {
              cleanFormatted = cleanFormatted.replaceFirst(RegExp(r'^[A-Z0-9]{4,8}\+[A-Z0-9]{2,4}[,\s]+'), '');
            }
            final parts = cleanFormatted.split(',');
            final main = parts.isNotEmpty ? parts[0].trim() : cleanFormatted;
            final sub = parts.length > 1 ? parts.sublist(1).map((e) => e.trim()).join(', ') : '';
            return LocationResult(
              title: main,
              subtitle: sub,
              latitude: lat,
              longitude: lng,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[RideLocationService] google geocoding error: $e');
    }

    // 3. Tier 3: OpenStreetMap Nominatim Reverse Geocoding (Guaranteed address resolution worldwide)
    try {
      final osmUrl = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1';
      final res = await _dio.get(
        osmUrl,
        options: Options(
          headers: {'User-Agent': 'CooliUserApp/1.0 (contact@cooli.com)'},
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map;
        final address = data['address'] as Map?;
        if (data['display_name'] != null) {
          final raw = data['display_name'].toString();
          final parts = raw.split(',');
          final main = parts.isNotEmpty ? parts[0].trim() : raw;
          final sub = parts.length > 1
              ? parts.sublist(1).map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ')
              : '';
          return LocationResult(
            title: main,
            subtitle: sub,
            latitude: lat,
            longitude: lng,
          );
        } else if (address != null) {
          final road = address['road']?.toString() ?? address['pedestrian']?.toString();
          final suburb = address['suburb']?.toString() ?? address['neighbourhood']?.toString();
          final city = address['city']?.toString() ?? address['town']?.toString() ?? address['village']?.toString();
          final state = address['state']?.toString();
          final postcode = address['postcode']?.toString();
          final name = data['name']?.toString();

          final main = name?.isNotEmpty == true
              ? name!
              : (road?.isNotEmpty == true ? road! : (suburb?.isNotEmpty == true ? suburb! : (city ?? 'Selected Spot')));

          final subList = <String>[];
          if (road != null && road != main) subList.add(road);
          if (suburb != null && suburb != main) subList.add(suburb);
          if (city != null && city != main) subList.add(city);
          if (state != null) subList.add(state);
          if (postcode != null) subList.add(postcode);

          return LocationResult(
            title: main,
            subtitle: subList.join(', '),
            latitude: lat,
            longitude: lng,
          );
        }
      }
    } catch (e) {
      debugPrint('[RideLocationService] osm nominatim error: $e');
    }

    // 4. Tier 4: Regional Geographic Fallback (Human-readable, NEVER coordinates)
    final fallback = _getRegionFallback(lat, lng);
    return LocationResult(
      title: fallback.title,
      subtitle: fallback.subtitle,
      latitude: lat,
      longitude: lng,
    );
  }

  /// Distance calculation using haversine formula
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // pi / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(max(0.0, a))); // 2 * R, R = 6371 km
  }

  /// Calculates human-readable distance and estimated duration
  static String calculateRideEstimate({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dist = calculateDistanceKm(lat1, lon1, lat2, lon2);
    final timeMin = max(5, (dist / 25 * 60).round() + 4);
    return '${dist.toStringAsFixed(1)} km • $timeMin mins';
  }

  /// Retrieves user's live physical device GPS location with high accuracy
  Future<LocationResult?> getCurrentClientLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {}

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position? position;

        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (_) {}

        if (position == null) {
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 4),
              ),
            );
          } catch (_) {
            try {
              position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.medium,
                  timeLimit: Duration(seconds: 3),
                ),
              );
            } catch (_) {}
          }
        }

        if (position != null) {
          final geocoded = await reverseGeocode(position.latitude, position.longitude);
          if (geocoded != null && geocoded.title.isNotEmpty) {
            return LocationResult(
              title: geocoded.title,
              subtitle: geocoded.subtitle.isNotEmpty ? geocoded.subtitle : 'Current Device Spot',
              latitude: position.latitude,
              longitude: position.longitude,
            );
          }
          final fallback = _getRegionFallback(position.latitude, position.longitude);
          return LocationResult(
            title: fallback.title,
            subtitle: fallback.subtitle,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      }
    } catch (_) {}

    return null;
  }

  /// Decodes Google Directions encoded polyline into road LatLng coordinates
  static List<LatLng> decodePolyline(String encoded) {
    final List<LatLng> poly = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  /// Fetches comprehensive road travel navigation details (coordinates, road distance, duration)
  /// Uses OSRM Driving Road Routing engine (Tier 1) and Google Directions API (Tier 2).
  Future<RideRouteDetails?> getRouteDetails(LatLng start, LatLng end) async {
    // 1. Tier 1: OpenStreetMap / OSRM Driving Road Routing (returns authentic street coordinates)
    try {
      final osrmUrl =
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
      final res = await _dio.get(
        osrmUrl,
        options: Options(
          headers: {'User-Agent': 'CooliUserApp/1.0 (contact@cooli.com)'},
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      if (res.statusCode == 200 && res.data is Map && res.data['code'] == 'Ok') {
        final routes = res.data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes[0] as Map;
          final geometry = route['geometry'] as Map?;
          final rawCoords = geometry?['coordinates'] as List?;
          if (rawCoords != null && rawCoords.length >= 2) {
            final points = rawCoords.map<LatLng>((c) {
              final list = c as List;
              return LatLng((list[1] as num).toDouble(), (list[0] as num).toDouble());
            }).toList();

            final distMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
            final durSeconds = (route['duration'] as num?)?.toDouble() ?? 0.0;
            final distKm = distMeters > 0
                ? (distMeters / 1000.0)
                : calculateDistanceKm(start.latitude, start.longitude, end.latitude, end.longitude);
            final durMin = durSeconds > 0
                ? max(1, (durSeconds / 60.0).round())
                : max(5, (distKm / 25 * 60).round() + 4);

            return RideRouteDetails(
              coordinates: points,
              distanceKm: distKm,
              durationMinutes: durMin,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[RideLocationService] OSRM route error: $e');
    }

    // 2. Tier 2: Google Directions API
    try {
      final googleUrl =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&mode=driving&key=$apiKey';
      final res = await _dio.get(
        googleUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      if (res.statusCode == 200 && res.data is Map && res.data['status'] == 'OK') {
        final routes = res.data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes[0] as Map;
          final overview = route['overview_polyline']?['points']?.toString();
          if (overview != null && overview.isNotEmpty) {
            final decoded = decodePolyline(overview);
            if (decoded.length >= 2) {
              final legs = route['legs'] as List?;
              double distKm = calculateDistanceKm(start.latitude, start.longitude, end.latitude, end.longitude);
              int durMin = max(5, (distKm / 25 * 60).round() + 4);
              if (legs != null && legs.isNotEmpty) {
                final leg = legs[0] as Map;
                final distVal = (leg['distance']?['value'] as num?)?.toDouble();
                final durVal = (leg['duration']?['value'] as num?)?.toDouble();
                if (distVal != null) distKm = distVal / 1000.0;
                if (durVal != null) durMin = max(1, (durVal / 60.0).round());
              }
              return RideRouteDetails(
                coordinates: decoded,
                distanceKm: distKm,
                durationMinutes: durMin,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[RideLocationService] Google directions error: $e');
    }

    // 3. Fallback: Generate smoothed road points
    final fallbackPoints = generateRoadGridPoints(start, end);
    final fallbackDist = calculateDistanceKm(start.latitude, start.longitude, end.latitude, end.longitude);
    final fallbackMin = max(5, (fallbackDist / 25 * 60).round() + 4);
    return RideRouteDetails(
      coordinates: fallbackPoints,
      distanceKm: fallbackDist,
      durationMinutes: fallbackMin,
    );
  }

  /// Fetches road travel navigation path coordinates
  Future<List<LatLng>> getRouteCoordinates(LatLng start, LatLng end) async {
    final details = await getRouteDetails(start, end);
    if (details != null && details.coordinates.length >= 2) {
      return details.coordinates;
    }
    return generateRoadGridPoints(start, end);
  }

  /// Generates smoothed path waypoints when offline
  static List<LatLng> generateRoadGridPoints(LatLng start, LatLng end) {
    final points = <LatLng>[];
    const steps = 12;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = (1 - t) * start.latitude + t * end.latitude;
      final lng = (1 - t) * start.longitude + t * end.longitude;
      final sinOffset = sin(t * pi) * 0.0015;
      points.add(LatLng(lat + sinOffset, lng + sinOffset * 0.5));
    }
    points[0] = start;
    points[points.length - 1] = end;
    return points;
  }
}

/// Model encapsulating route navigation travel details
class RideRouteDetails {
  final List<LatLng> coordinates;
  final double distanceKm;
  final int durationMinutes;

  const RideRouteDetails({
    required this.coordinates,
    required this.distanceKm,
    required this.durationMinutes,
  });
}
