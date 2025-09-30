import 'package:flutter/material.dart';
import 'modules/groups/groups_screen.dart';
import 'modules/settings/settings_screen.dart';
import 'modules/parameters/parameters_screen.dart';
import 'modules/farmers/farmers_screen.dart';

void openTopMenu(BuildContext context, String value) {
  switch (value) {
    case 'props':
      () async {
        await Future.delayed(const Duration(milliseconds: 10));
        if (!context.mounted) return;
        Navigator.of(context).pushNamed('/properties');
      }();
      break;

    case 'groups':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GroupsScreen()),
      );
      break;

    case 'workers':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FarmersScreen()),
      );
      break;

    case 'settings':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      break;
    case 'params':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ParametersScreen()),
      );
      break;
  }
}
