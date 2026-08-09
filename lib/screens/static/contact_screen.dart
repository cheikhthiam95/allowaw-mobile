import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/contact_service.dart';

const _subjects = [
  'Signaler un bug',
  'Problème avec mon annonce',
  'Problème de compte',
  'Question générale',
  'Autre',
];

/// Équivalent Contact.jsx.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _service = ContactService();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _body = TextEditingController();
  String _subject = _subjects.first;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _service.send(name: _name.text.trim(), email: _email.text.trim(), subject: _subject, body: _body.text.trim());
      setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nous contacter')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _sent
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 48),
                    const SizedBox(height: 12),
                    const Text('Message envoyé !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Notre équipe vous répondra rapidement.', style: TextStyle(color: AppColors.inkMuted)),
                  ],
                ),
              )
            : Form(
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
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (v) => (v == null || !v.contains('@')) ? 'E-mail invalide' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _subject,
                      decoration: const InputDecoration(labelText: 'Sujet'),
                      items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _subject = v!),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _body,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Message', alignLabelWithHint: true),
                      validator: (v) => (v == null || v.trim().length < 10) ? '10 caractères minimum' : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _sending ? null : _submit,
                      child: _sending
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Envoyer'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
