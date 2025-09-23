import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../db/isar_service.dart';
import '../models/property.dart';
import '../models/farmer.dart';

class ExportService {
  /// Exports the given property and basic metadata into a zip file.
  /// Returns the absolute path to the created zip.
  static Future<String> exportProperty({required int propertyId}) async {
    final isar = await IsarService.open();
    final property = await isar.propertys.get(propertyId);
    if (property == null) {
      throw StateError('Property $propertyId not found');
    }

    final tmp = await getTemporaryDirectory();
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final exportDir = Directory(
      '${tmp.path}${Platform.pathSeparator}property_export_${property.id}_$ts',
    );
    if (!exportDir.existsSync()) exportDir.createSync(recursive: true);

    // Build property metadata
    final meta = {
      'id': property.id,
      'name': property.name,
      'ownerId': property.ownerId,
      'type': property.type,
      'typeCode': property.typeCode,
      'address': property.address,
      'addressLine': property.addressLine,
      'street': property.street,
      'city': property.city,
      'pin': property.pin,
      'lat': property.lat,
      'lon': property.lon,
      'altitude': property.altitude,
      'directions': property.directions,
      'originLat': property.originLat,
      'originLon': property.originLon,
      'originAlt': property.originAlt,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'bhoomima',
      'version': 1,
    };

    final metaFile = File(
      '${exportDir.path}${Platform.pathSeparator}property_${property.id}.json',
    );
    await metaFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(meta),
    );

    // TODO: Add groups/points/logs into subfolders if needed in future iterations.

    // Zip the directory
    final zipPath =
        '${tmp.path}${Platform.pathSeparator}property_${property.id}_export.zip';
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    encoder.addDirectory(exportDir);
    encoder.close();

    return zipPath;
  }

  /// Exports a single farmer as a JSON file in the temporary directory.
  /// Returns the created File.
  static Future<File> exportFarmerJson({
    required int farmerId,
    bool anonymizePhones = false,
  }) async {
    final isar = await IsarService.open();
    final f = await isar.farmers.get(farmerId);
    if (f == null) throw StateError('Farmer not found');

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    final safeName = f.name.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    final out = File('${dir.path}/Farmer_${safeName}_$stamp.json');

    String? mask(String? s) {
      if (s == null || s.isEmpty) return s;
      final digits = s.replaceAll(RegExp(r'\D'), '');
      if (digits.length <= 4) return '****';
      return '****${digits.substring(digits.length - 4)}';
    }

    final data = {
      'spec_id': 'BM-SPEC-001',
      'spec_version': '0.6',
      'exported_at': DateTime.now().toIso8601String(),
      'farmer': {
        'id': f.id,
        'name': f.name,
        'mobile': anonymizePhones ? mask(f.mobile) : f.mobile,
        'whatsapp': anonymizePhones ? mask(f.whatsapp) : f.whatsapp,
        'village': f.village,
        'taluk': f.taluk,
        'preferredLanguageCode': f.preferredLanguageCode,
        'notes': f.notes,
        'consentExport': f.consentExport,
        'consentWhatsApp': f.consentWhatsApp,
      },
    };

    await out.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return out;
  }
}
