import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/i18n/strings.dart';
import 'pharmacy_settings_repository.dart';

/// Écran de paramétrage de la pharmacie (raison sociale, devise, préfixe de
/// facture, logo) — utilisé pour le branding des factures/tickets imprimés.
class PharmacySettingsScreen extends ConsumerStatefulWidget {
  const PharmacySettingsScreen({super.key});

  static const demoTenantId = '00000000-0000-0000-0000-000000000001';

  @override
  ConsumerState<PharmacySettingsScreen> createState() =>
      _PharmacySettingsScreenState();
}

class _PharmacySettingsScreenState
    extends ConsumerState<PharmacySettingsScreen> {
  final _legalName = TextEditingController();
  final _currency = TextEditingController();
  final _invoicePrefix = TextEditingController();
  String? _logoPath;
  bool _loadedOnce = false;
  bool _saving = false;

  @override
  void dispose() {
    _legalName.dispose();
    _currency.dispose();
    _invoicePrefix.dispose();
    super.dispose();
  }

  void _loadIfNeeded(PharmacySettings? settings) {
    if (_loadedOnce || settings == null) return;
    _legalName.text = settings.legalName;
    _currency.text = settings.currency;
    _invoicePrefix.text = settings.invoicePrefix;
    _logoPath = settings.logoPath;
    _loadedOnce = true;
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final dir = await getApplicationSupportDirectory();
    final destPath = p.join(dir.path, 'pharmacy_logo${p.extension(picked.path)}');
    await File(picked.path).copy(destPath);
    setState(() => _logoPath = destPath);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(pharmacySettingsRepositoryProvider).upsert(
        tenantId: PharmacySettingsScreen.demoTenantId,
        legalName: _legalName.text.trim(),
        currency: _currency.text.trim(),
        invoicePrefix: _invoicePrefix.text.trim(),
        logoPath: _logoPath,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.of(context).settingsSaved)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(
      pharmacySettingsStreamProvider(PharmacySettingsScreen.demoTenantId),
    );
    final s = Strings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.pharmacySettingsTitle)),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.errorWith(e))),
        data: (settings) {
          _loadIfNeeded(settings);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: _logoPath != null
                        ? FileImage(File(_logoPath!))
                        : null,
                    child: _logoPath == null
                        ? const Icon(Icons.add_photo_alternate_outlined, size: 32)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickLogo,
                  child: Text(s.changeLogo),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _legalName,
                decoration: InputDecoration(
                  labelText: s.legalName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _currency,
                decoration: InputDecoration(
                  labelText: s.currencyHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _invoicePrefix,
                decoration: InputDecoration(
                  labelText: s.invoicePrefixLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.save),
              ),
            ],
          );
        },
      ),
    );
  }
}
