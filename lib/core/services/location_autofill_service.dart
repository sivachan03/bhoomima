// BM-76 — lib/core/services/location_autofill_service.dart
//
// Clean, efficient service for property autofill:
// - Offline: fetches lat/lon/altitude via Geolocator.
// - Online: reverse-geocodes using DEVICE LOCALE first; if empty, retries in 'en'.
// - No UI; pure service layer.

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

class LocationAutofillResult {
  final double lat;
  final double lon;
  final double? altitude; // meters
  final String? addressLine;
  final String? street;
  final String? city;
  final String? pin; // postal code

  const LocationAutofillResult({
    required this.lat,
    required this.lon,
    this.altitude,
    this.addressLine,
    this.street,
    this.city,
    this.pin,
  });
}

class LocationAutofillService {
  static Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi);
  }

  static Future<Position> _getPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException(
        'Location services are disabled.',
      );
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const PermissionDeniedException(
          'Location permissions are denied',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'Location permissions are permanently denied',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
  }

  static Future<(String?, String?, String?, String?)> _reverseDeviceLocale(
    double lat,
    double lon,
  ) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) return (null, null, null, null);
      final p = placemarks.first;
      final addressLine = [
        p.subThoroughfare,
        p.thoroughfare,
      ].where((e) => (e ?? '').isNotEmpty).join(' ').trim();
      final street = p.street?.isNotEmpty == true ? p.street : p.thoroughfare;
      final city = p.locality?.isNotEmpty == true
          ? p.locality
          : (p.subAdministrativeArea?.isNotEmpty == true
                ? p.subAdministrativeArea
                : p.administrativeArea);
      final pin = p.postalCode;
      return (addressLine.isEmpty ? null : addressLine, street, city, pin);
    } catch (_) {
      return (null, null, null, null);
    }
  }

  static Future<(String?, String?, String?, String?)> _reverseEnglish(
    double lat,
    double lon,
  ) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        lat,
        lon,
        localeIdentifier: 'en',
      );
      if (placemarks.isEmpty) return (null, null, null, null);
      final p = placemarks.first;
      final addressLine = [
        p.subThoroughfare,
        p.thoroughfare,
      ].where((e) => (e ?? '').isNotEmpty).join(' ').trim();
      final street = p.street?.isNotEmpty == true ? p.street : p.thoroughfare;
      final city = p.locality?.isNotEmpty == true
          ? p.locality
          : (p.subAdministrativeArea?.isNotEmpty == true
                ? p.subAdministrativeArea
                : p.administrativeArea);
      final pin = p.postalCode;
      return (addressLine.isEmpty ? null : addressLine, street, city, pin);
    } catch (_) {
      return (null, null, null, null);
    }
  }

  /// Public API: one-shot capture.
  /// - Always returns lat/lon/altitude (offline OK).
  /// - If online, try device-locale reverse geocoding, else fallback to English.
  static Future<LocationAutofillResult> capture() async {
    final pos = await _getPosition();

    String? addressLine, street, city, pin;
    if (await _hasInternet()) {
      (addressLine, street, city, pin) = await _reverseDeviceLocale(
        pos.latitude,
        pos.longitude,
      );
      final allEmpty = [
        addressLine,
        street,
        city,
        pin,
      ].every((s) => (s ?? '').trim().isEmpty);
      if (allEmpty) {
        (addressLine, street, city, pin) = await _reverseEnglish(
          pos.latitude,
          pos.longitude,
        );
      }
    }

    return LocationAutofillResult(
      lat: pos.latitude,
      lon: pos.longitude,
      altitude: pos.altitude.isFinite ? pos.altitude : null,
      addressLine: addressLine,
      street: street,
      city: city,
      pin: pin,
    );
  }
}

class PermissionDeniedException implements Exception {
  final String message;
  const PermissionDeniedException(this.message);
  @override
  String toString() => 'PermissionDeniedException: $message';
}

class LocationServiceDisabledException implements Exception {
  final String message;
  const LocationServiceDisabledException(this.message);
  @override
  String toString() => 'LocationServiceDisabledException: $message';
}
