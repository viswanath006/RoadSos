import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import '../../../core/errors/location_failure.dart';
import '../domain/location_info.dart';

class LocationService {
  Future<LocationInfo> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationFailure.serviceDisabled();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationFailure.permissionDenied();
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationFailure.permissionDeniedForever();
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on LocationServiceDisabledException {
      throw LocationFailure.serviceDisabled();
    } on PermissionDeniedException {
      throw LocationFailure.permissionDenied();
    } on TimeoutException {
      throw LocationFailure.timeout();
    } catch (e) {
      throw LocationFailure.unknown(e.toString());
    }

    final address = await _reverseGeocode(position.latitude, position.longitude);

    try {
      final box = Hive.box('offline_settings_box');
      await box.put('last_latitude', position.latitude);
      await box.put('last_longitude', position.longitude);
      await box.put('last_address', address);
    } catch (_) {}

    return LocationInfo(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      timestamp: DateTime.now(),
    );
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return 'Address unavailable for this location';
      }
      final p = placemarks.first;
      final parts = <String>[
        if (p.name != null && p.name!.isNotEmpty) p.name!,
        if (p.street != null && p.street!.isNotEmpty) p.street!,
        if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
        if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
          p.administrativeArea!,
        if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode!,
        if (p.country != null && p.country!.isNotEmpty) p.country!,
      ];
      return parts.isEmpty ? 'Address unavailable' : parts.join(', ');
    } catch (_) {
      return 'Address unavailable (geocoding failed)';
    }
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
