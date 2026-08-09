import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';

/// Affiché après une inscription via Google, où le type de compte/téléphone
/// manquent encore. Équivalent Account/CompleteProfile.jsx.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _service = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  String _accountType = 'particular';
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = await _service.complete({'phone': _phone.text.trim(), 'account_type': _accountType});
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(user);
      context.go('/');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compléter mon profil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Encore une étape : indiquez votre téléphone et le type de compte pour profiter pleinement d\'Allowaw.',
                style: TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone', hintText: '+221 77 123 45 67'),
                validator: (v) => (v == null || v.length < 8) ? 'Téléphone invalide' : null,
              ),
              const SizedBox(height: 14),
              const Text('Type de compte', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: accountTypeLabels.entries
                    .map((e) => ChoiceChip(
                          label: Text(e.value),
                          selected: _accountType == e.key,
                          onSelected: (_) => setState(() => _accountType = e.key),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
