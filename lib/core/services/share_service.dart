import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../db/isar_service.dart';
import '../models/property.dart';
import '../models/farmer.dart';

class ShareService {
  static Future<void> sharePropertyAddress(int propertyId) async {
    final isar = await IsarService.open();
    final p = await isar.propertys.get(propertyId);
    if (p == null) return;

    final lines = <String>[];
    lines.add(p.name);
    if ((p.addressLine ?? '').isNotEmpty) lines.add(p.addressLine!);
    if ((p.street ?? '').isNotEmpty) lines.add(p.street!);
    final cityPin = [
      p.city,
      p.pin,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' - ');
    if (cityPin.isNotEmpty) lines.add(cityPin);

    if (p.lat != null && p.lon != null) {
      final maps = 'https://maps.google.com/?q=${p.lat},${p.lon}';
      lines.add(maps);
    }

    final text = lines.join('\n');
    await Share.share(text);
  }

  // BM-99 additions
  static String buildPropertyAddressText({required Property p, Farmer? owner}) {
    final parts = <String>[];
    parts.add(p.name);
    final addr = [
      p.addressLine,
      p.street,
      p.city,
      p.pin,
    ].where((e) => (e ?? '').isNotEmpty).join(', ');
    if (addr.isNotEmpty) parts.add(addr);
    if ((p.directions ?? '').isNotEmpty) {
      parts.add('Directions: ${p.directions}');
    }
    final coords = [
      if (p.lat != null && p.lon != null)
        '${p.lat!.toStringAsFixed(6)}, ${p.lon!.toStringAsFixed(6)}'
      else
        null,
      if (p.altitude != null)
        'alt ${p.altitude!.toStringAsFixed(0)} m'
      else
        null,
    ].whereType<String>().join(' ');
    if (coords.isNotEmpty) parts.add('Location: $coords');
    if (p.lat != null && p.lon != null) {
      parts.add(
        'Open Map: https://www.google.com/maps/search/?api=1&query=${p.lat!.toStringAsFixed(6)},${p.lon!.toStringAsFixed(6)}',
      );
    }
    parts.add('When: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    return parts.join('\n');
  }

  static String buildFarmerAddressText(Farmer f) {
    final parts = <String>[];
    parts.add('Farmer: ${f.name}');
    final loc = [
      f.village,
      f.taluk,
    ].where((e) => (e ?? '').isNotEmpty).join(', ');
    if (loc.isNotEmpty) parts.add('Location: $loc');
    if ((f.notes ?? '').isNotEmpty) parts.add('Notes: ${f.notes}');
    parts.add('When: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    return parts.join('\n');
  }

  static Future<void> shareText(String text) async {
    await Share.share(text);
  }

  static Future<bool> tryOpenWhatsAppToNumber(
    String phone,
    String message,
  ) async {
    final encoded = Uri.encodeComponent(message);
    final sanitized = phone.replaceAll(RegExp(r'\s+'), '');
    final waUri = Uri.parse('https://wa.me/$sanitized?text=$encoded');
    if (await canLaunchUrl(waUri)) {
      final ok = await launchUrl(waUri, mode: LaunchMode.externalApplication);
      if (ok) return true;
    }
    final scheme = Uri.parse('whatsapp://send?phone=$sanitized&text=$encoded');
    if (await canLaunchUrl(scheme)) {
      final ok = await launchUrl(scheme, mode: LaunchMode.externalApplication);
      if (ok) return true;
    }
    return false;
  }

  static String buildFarmerShareText(Farmer f) {
    final parts = <String>[];
    parts.add('Farmer: ${f.name}');
    if ((f.mobile ?? '').isNotEmpty) parts.add('Mobile: ${f.mobile}');
    if ((f.whatsapp ?? '').isNotEmpty) parts.add('WhatsApp: ${f.whatsapp}');
    final loc = [
      f.village,
      f.taluk,
    ].where((e) => (e ?? '').isNotEmpty).join(', ');
    if (loc.isNotEmpty) parts.add('Location: $loc');
    if ((f.preferredLanguageCode ?? '').isNotEmpty) {
      parts.add('Language: ${f.preferredLanguageCode}');
    }
    if ((f.notes ?? '').isNotEmpty) parts.add('Notes: ${f.notes}');
    parts.add('When: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    return parts.join('\n');
  }

  static Future<void> shareFarmer(Farmer f) async {
    final text = buildFarmerShareText(f);
    await Share.share(text);
  }
}
