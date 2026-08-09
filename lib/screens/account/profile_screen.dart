import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../widgets/phone_verification_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _businessName;
  late final TextEditingController _neighborhood;
  File? _newAvatar;

  bool _saving = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser!;
    final names = user.fullName.split(' ');
    _firstName = TextEditingController(text: names.isNotEmpty ? names.first : '');
    _lastName = TextEditingController(text: names.length > 1 ? names.sublist(1).join(' ') : '');
    _phone = TextEditingController(text: user.phone ?? '');
    _whatsapp = TextEditingController(text: user.whatsapp ?? '');
    _businessName = TextEditingController(text: user.businessName ?? '');
    _neighborhood = TextEditingController(text: user.neighborhood ?? '');
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (picked != null) setState(() => _newAvatar = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      final user = await _service.update({
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'phone': _phone.text.trim(),
        'whatsapp': _whatsapp.text.trim(),
        'business_name': _businessName.text.trim(),
        'neighborhood': _neighborhood.text.trim(),
      }, avatar: _newAvatar);
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(user);
      setState(() => _success = 'Profil mis à jour.');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ImageProvider? _avatarImage(String? avatarUrl) {
    if (_newAvatar != null) return FileImage(_newAvatar!);
    if (avatarUrl != null) return NetworkImage(avatarUrl);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary100,
                        backgroundImage: _avatarImage(user.avatarUrl),
                        child: _newAvatar == null && user.avatarUrl == null
                            ? Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.w700))
                            : null,
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(radius: 14, backgroundColor: AppColors.gold, child: Icon(Icons.camera_alt, size: 14, color: AppColors.ink)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_success != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(_success!, style: const TextStyle(color: AppColors.success)),
                ),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _firstName, decoration: const InputDecoration(labelText: 'Prénom'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _lastName, decoration: const InputDecoration(labelText: 'Nom'))),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: user.email,
                enabled: false,
                decoration: const InputDecoration(labelText: 'E-mail (non modifiable)'),
              ),
              const SizedBox(height: 14),
              TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Téléphone')),
              const SizedBox(height: 14),
              TextFormField(controller: _whatsapp, decoration: const InputDecoration(labelText: 'WhatsApp (si différent)')),
              if (user.accountType != 'particular') ...[
                const SizedBox(height: 14),
                TextFormField(controller: _businessName, decoration: const InputDecoration(labelText: 'Nom de l\'entreprise')),
              ],
              const SizedBox(height: 14),
              TextFormField(controller: _neighborhood, decoration: const InputDecoration(labelText: 'Quartier')),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enregistrer'),
              ),
              const SizedBox(height: 28),
              PhoneVerificationCard(
                verified: user.verified,
                onVerified: (updated) => context.read<AuthProvider>().updateUser(updated),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
