import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar/isar.dart';
import '../models/icon_item.dart';

class IconResolver {
  final Isar db;
  IconResolver(this.db);

  Future<Widget> buildIcon(String? code, {double size = 24}) async {
    if (code == null || code.isEmpty) {
      return Icon(Icons.location_on, size: size);
    }
    final item = await db.iconItems.where().codeEqualTo(code).findFirst();
    if (item == null || (item.assetPath ?? '').isEmpty) {
      return Icon(Icons.location_on, size: size);
    }
    return SvgPicture.asset(item.assetPath!, width: size, height: size);
  }
}
