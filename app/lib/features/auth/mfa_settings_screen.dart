import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/i18n/strings.dart';

/// Activation/désactivation de la double authentification (TOTP) sur le
/// compte connecté, via l'API MFA de Supabase Auth.
class MfaSettingsScreen extends ConsumerStatefulWidget {
  const MfaSettingsScreen({super.key});

  @override
  ConsumerState<MfaSettingsScreen> createState() => _MfaSettingsScreenState();
}

class _MfaSettingsScreenState extends ConsumerState<MfaSettingsScreen> {
  List<Factor>? _totpFactors;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final factors = await ref.read(authRepositoryProvider).mfaListFactors();
    setState(() {
      _totpFactors = factors.totp;
      _loading = false;
    });
  }

  Future<void> _disable(String factorId) async {
    final s = Strings.of(context);
    await ref.read(authRepositoryProvider).mfaUnenroll(factorId);
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s.mfaDisableSuccess)));
  }

  Future<void> _startEnrollment() async {
    final auth = ref.read(authRepositoryProvider);
    final enrollment = await auth.mfaEnrollTotp();
    if (!mounted) return;
    final verified = await showDialog<bool>(
      context: context,
      builder: (_) => _MfaEnrollDialog(
        factorId: enrollment.id,
        secret: enrollment.totp!.secret,
        uri: enrollment.totp!.uri,
      ),
    );
    if (verified == true) {
      await _refresh();
      if (!mounted) return;
      final s = Strings.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.mfaEnrollSuccess)));
    } else {
      await auth.mfaUnenroll(enrollment.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final enabled = (_totpFactors?.isNotEmpty ?? false);
    return Scaffold(
      appBar: AppBar(title: Text(s.mfaSettingsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: Icon(
                      enabled ? Icons.lock_outlined : Icons.lock_open_outlined,
                    ),
                    title: Text(s.mfaSettingsTitle),
                    subtitle: Text(
                      enabled ? s.mfaEnabledStatus : s.mfaDisabledStatus,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (enabled)
                    OutlinedButton(
                      onPressed: () => _disable(_totpFactors!.first.id),
                      child: Text(s.mfaDisableButton),
                    )
                  else
                    FilledButton(
                      onPressed: _startEnrollment,
                      child: Text(s.mfaEnrollButton),
                    ),
                ],
              ),
            ),
    );
  }
}

class _MfaEnrollDialog extends ConsumerStatefulWidget {
  const _MfaEnrollDialog({
    required this.factorId,
    required this.secret,
    required this.uri,
  });

  final String factorId;
  final String secret;
  final String uri;

  @override
  ConsumerState<_MfaEnrollDialog> createState() => _MfaEnrollDialogState();
}

class _MfaEnrollDialogState extends ConsumerState<_MfaEnrollDialog> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final s = Strings.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).mfaChallengeAndVerify(
            factorId: widget.factorId,
            code: _code.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException {
      setState(() => _error = s.mfaInvalidCode);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return AlertDialog(
      title: Text(s.mfaEnrollButton),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.mfaScanQrPrompt),
            const SizedBox(height: 8),
            SelectableText(
              widget.secret,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(s.mfaConfirmCodePrompt),
            const SizedBox(height: 8),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: s.mfaCodeLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: _loading ? null : _confirm,
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(s.mfaVerify),
        ),
      ],
    );
  }
}
