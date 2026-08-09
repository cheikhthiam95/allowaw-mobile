import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

/// Ouvert via le lien reçu par e-mail (deep link vers
/// allowaw://reset-password?token=... ou https://dev.allowaw.sn/... selon
/// la config de deep-linking retenue côté app). Le jeton peut aussi être
/// saisi manuellement si l'utilisateur le colle depuis l'e-mail web.
class ResetPasswordScreen extends StatefulWidget {
  final String? token;
  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _token;
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  final _service = AuthService();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _token = TextEditingController(text: widget.token ?? '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _service.resetPassword(
        token: _token.text.trim(),
        password: _password.text,
        passwordConfirmation: _passwordConfirmation.text,
      );
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(user);
      context.go('/');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau mot de passe'),
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ),
              if (widget.token == null)
                TextFormField(
                  controller: _token,
                  decoration: const InputDecoration(labelText: 'Code reçu par e-mail'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
                validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordConfirmation,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmer'),
                validator: (v) => v != _password.text ? 'Les mots de passe ne correspondent pas' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Réinitialiser'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
