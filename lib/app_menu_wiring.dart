import 'package:flutter/material.dart';
import 'modules/groups/groups_screen.dart';
import 'modules/points/points_list_screen.dart';
import 'modules/settings/settings_screen.dart';
import 'modules/parameters/parameters_screen.dart';
import 'modules/properties/properties_screen.dart';

void openTopMenu(BuildContext context, String value) {
  switch (value) {
    case 'props':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PropertiesScreen()),
      );
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
        MaterialPageRoute(builder: (_) => const PartyScreen()),
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
