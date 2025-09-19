import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _lang = 'ml';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _lang = prefs.getString('lang') ?? 'ml');
  }

  Future<void> _save(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', v);
    setState(() => _lang = v);
    // NOTE: for full app locale change, hoist this into an app-level provider
    // and rebuild MaterialApp.locale. For now, we just persist.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('Language')),

          RadioListTile<String>(
              value: 'en', groupValue: _lang, onChanged: (v) => _save(v!), title: const Text('English')),

          RadioListTile<String>(
              value: 'ml', groupValue: _lang, onChanged: (v) => _save(v!), title: const Text('Malayalam')),

          const Divider(),
          const ListTile(title: Text('Other toggles (GPS, captions, etc.) go here')),
        ],
      ),
    );
  }
}