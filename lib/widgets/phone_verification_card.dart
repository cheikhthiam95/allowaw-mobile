import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/user.dart';
import '../services/phone_verification_service.dart';

/// Carte de vérification du numéro — reflète la section correspondante de
/// Account/Profile.jsx côté web (mêmes textes, même logique : badge vert si
/// déjà vérifié, sinon "recevoir un code par WhatsApp" puis un champ à 6
/// chiffres).
class PhoneVerificationCard extends StatefulWidget {
  final bool verified;
  final ValueChanged<AppUser> onVerified;
  const PhoneVerificationCard({super.key, required this.verified, required this.onVerified});

  @override
  State<PhoneVerificationCard> createState() => _PhoneVerificationCardState();
}

class _PhoneVerificationCardState extends State<PhoneVerificationCard> {
  final _service = PhoneVerificationService();
  final _codeController = TextEditingController();

  bool _pending = false;
  bool _sending = false;
  bool _verifying = false;
  String? _info;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _error = null;
      _info = null;
    });
    try {
      final message = await _service.sendCode();
      setState(() {
        _pending = true;
        _info = message;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final user = await _service.verifyCode(_codeController.text.trim());
      widget.onVerified(user);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.verified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified, color: AppColors.success, size: 20),
            SizedBox(width: 10),
            Text('Numéro de téléphone vérifié', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13.5)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gpp_maybe_outlined, color: AppColors.inkMuted, size: 18),
              SizedBox(width: 8),
              Text('Vérifier mon numéro', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Un compte vérifié inspire davantage confiance aux acheteurs et vendeurs.',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ),
          if (_info != null && _pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_info!, style: const TextStyle(color: AppColors.success, fontSize: 13)),
            ),
          if (!_pending)
            ElevatedButton.icon(
              onPressed: _sending ? null : _sendCode,
              icon: _sending
                  ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.chat, size: 16),
              label: const Text('Recevoir un code par WhatsApp'),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(letterSpacing: 4, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      hintText: 'Code à 6 chiffres',
                      counterText: '',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: (_codeController.text.trim().length == 6 && !_verifying) ? _verifyCode : null,
                  child: _verifying
                      ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Valider'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _sending ? null : _sendCode,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
              child: const Text('Renvoyer le code', style: TextStyle(fontSize: 12.5)),
            ),
          ],
        ],
      ),
    );
  }
}
