import 'package:flutter/material.dart';
import 'modules/groups/groups_screen.dart';
import 'modules/points/points_list_screen.dart';
import 'modules/party/party_screen.dart';
import 'modules/settings/settings_screen.dart';

void openTopMenu(BuildContext context, String value) {
  switch (value) {
  case 'props':
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Properties screen placeholder')));
  break;

  case 'groups':
  Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsScreen(propertyId: 1)));
  break;

  case 'workers':
  Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyScreen()));
  break;

  case 'settings':
  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  break;
  }
}