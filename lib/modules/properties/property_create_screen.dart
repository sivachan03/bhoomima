import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/property.dart';
import '../../core/repos/property_repo.dart';

class PropertyCreateScreen extends ConsumerStatefulWidget {
  const PropertyCreateScreen({super.key});

  @override
  ConsumerState<PropertyCreateScreen> createState() =>
      _PropertyCreateScreenState();
}

class _PropertyCreateScreenState extends ConsumerState<PropertyCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  final _streetCtl = TextEditingController();
  final _cityCtl = TextEditingController();
  final _pinCtl = TextEditingController();
  final _latCtl = TextEditingController();
  final _lonCtl = TextEditingController();
  final _altCtl = TextEditingController();
  final _dirCtl = TextEditingController();

  @override
  void dispose() {
    _nameCtl.dispose();
    _addressCtl.dispose();
    _streetCtl.dispose();
    _cityCtl.dispose();
    _pinCtl.dispose();
    _latCtl.dispose();
    _lonCtl.dispose();
    _altCtl.dispose();
    _dirCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(propertyRepoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtl,
                decoration: const InputDecoration(labelText: 'Address line'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _streetCtl,
                decoration: const InputDecoration(labelText: 'Street'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityCtl,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pinCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'PIN'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latCtl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lonCtl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Longitude'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _altCtl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Altitude (m)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dirCtl,
                decoration: const InputDecoration(
                  labelText: 'Directions (how to reach)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      // Cache navigator before async work to avoid using context after await
                      final nav = Navigator.of(context);
                      final p = Property()
                        ..name = _nameCtl.text.trim()
                        ..typeCode = 'locationOnly'
                        ..type = 'locationOnly'
                        ..addressLine = _emptyToNull(_addressCtl.text)
                        ..address = _emptyToNull(_addressCtl.text)
                        ..street = _emptyToNull(_streetCtl.text)
                        ..city = _emptyToNull(_cityCtl.text)
                        ..pin = _emptyToNull(_pinCtl.text)
                        ..lat = _parseD(_latCtl.text)
                        ..lon = _parseD(_lonCtl.text)
                        ..altitude = _parseD(_altCtl.text)
                        ..directions = _emptyToNull(_dirCtl.text);
                      final id = await repo.upsert(p);
                      nav.pop(id);
                    },
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _emptyToNull(String? s) =>
    (s == null || s.trim().isEmpty) ? null : s.trim();
double? _parseD(String? s) {
  if (s == null) return null;
  try {
    return s.trim().isEmpty ? null : double.parse(s.trim());
  } catch (_) {
    return null;
  }
}
