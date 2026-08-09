import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messages_provider.dart';
import '../../services/conversation_service.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_views.dart';

class ConversationDetailScreen extends StatefulWidget {
  final int conversationId;
  const ConversationDetailScreen({super.key, required this.conversationId});

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

// Même délai que côté web (Messages/Show.jsx) — le temps qu'un vrai
// échange ait pu avoir lieu avant de demander "avez-vous conclu ?".
const _ratingPromptDelay = Duration(hours: 24);

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final _service = ConversationService();
  final _bodyController = TextEditingController();
  final _scrollController = ScrollController();

  Conversation? _conversation;
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  bool? _pendingConcluded;
  int _pendingStars = 0;
  bool _submittingRating = false;

  @override
  void initState() {
    super.initState();
    // Pas de notification locale pour cette conversation tant qu'elle est
    // ouverte à l'écran — pas besoin de se notifier soi-même.
    context.read<MessagesProvider>().setActiveConversation(widget.conversationId);
    _load();
  }

  @override
  void dispose() {
    context.read<MessagesProvider>().setActiveConversation(null);
    // Les messages viennent d'être marqués lus côté serveur (voir #show
    // dans l'API) — on rafraîchit tout de suite le badge plutôt que
    // d'attendre jusqu'à 25s le prochain poll.
    context.read<MessagesProvider>().refreshNow();
    _bodyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _service.show(widget.conversationId);
      setState(() {
        _conversation = detail.conversation;
        _messages = detail.messages;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _bodyController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _bodyController.clear();
    try {
      final msg = await _service.sendMessage(conversationId: widget.conversationId, body: text);
      setState(() => _messages.add(msg));
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submitRating() async {
    if (_pendingConcluded == null || _submittingRating) return;
    setState(() => _submittingRating = true);
    try {
      await _service.rateContact(
        conversationId: widget.conversationId,
        concluded: _pendingConcluded!,
        stars: _pendingStars > 0 ? _pendingStars : null,
      );
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submittingRating = false);
    }
  }

  /// "Avez-vous conclu ?" — uniquement pour l'acheteur (auteur du premier
  /// contact), une fois le délai passé, et tant qu'il n'a pas déjà répondu.
  /// C'est le signal de confiance central de la plateforme (voir
  /// ContactRating côté Rails) : pas de paiement/escrow à observer, donc
  /// c'est la seule preuve qu'une mise en relation a fonctionné.
  Widget _buildRatingBanner(Conversation conv) {
    if (conv.rating != null) {
      return Container(
        width: double.infinity,
        color: AppColors.primary50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Merci pour votre retour — ${conv.rating!.concluded ? "transaction conclue" : "non conclue"}'
                '${conv.rating!.stars != null ? " · ${conv.rating!.stars}★" : ""}',
                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final createdAt = conv.createdAt;
    if (!conv.isRater || createdAt == null || DateTime.now().difference(createdAt) < _ratingPromptDelay) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: AppColors.goldLight.withValues(alpha: 0.18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avez-vous conclu avec ${conv.otherUser.fullName} ?',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _RatingChoiceButton(
                label: 'Oui, conclu',
                selected: _pendingConcluded == true,
                selectedColor: AppColors.primary,
                onTap: () => setState(() => _pendingConcluded = true),
              ),
              const SizedBox(width: 8),
              _RatingChoiceButton(
                label: 'Non',
                selected: _pendingConcluded == false,
                selectedColor: AppColors.inkMuted,
                onTap: () => setState(() => _pendingConcluded = false),
              ),
              if (_pendingConcluded != null) ...[
                const SizedBox(width: 10),
                ...List.generate(5, (i) {
                  final n = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _pendingStars = n),
                    child: Icon(
                      Icons.star,
                      size: 18,
                      color: n <= _pendingStars ? AppColors.gold : AppColors.line,
                    ),
                  );
                }),
              ],
            ],
          ),
          if (_pendingConcluded != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: _submittingRating ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _submittingRating
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Envoyer mon avis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: _ChatSkeleton());
    if (_error != null) return Scaffold(appBar: AppBar(), body: ErrorView(message: _error!, onRetry: _load));

    final conv = _conversation!;
    final myId = context.read<AuthProvider>().currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conv.otherUser.fullName, style: const TextStyle(fontSize: 16)),
            Text(conv.listingTitle, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () => context.push('/listings/${conv.listingSlug}')),
        ],
      ),
      body: Column(
        children: [
          _buildRatingBanner(conv),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isMine = m.userId == myId;
                return Align(
                  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                    decoration: BoxDecoration(
                      color: isMine ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(isMine ? 14 : 2),
                        bottomRight: Radius.circular(isMine ? 2 : 14),
                      ),
                      border: isMine ? null : Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(m.body, style: TextStyle(color: isMine ? Colors.white : AppColors.ink)),
                        const SizedBox(height: 2),
                        Text(
                          formatRelativeDate(m.createdAt),
                          style: TextStyle(fontSize: 10, color: isMine ? Colors.white70 : AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bodyController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Votre message...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.line)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _sending ? null : _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;
  const _RatingChoiceButton({required this.label, required this.selected, required this.selectedColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? selectedColor : AppColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.ink),
        ),
      ),
    );
  }
}

/// Skeleton d'une conversation en cours de chargement — quelques bulles
/// alternées gauche/droite pour ne pas afficher un écran vide brutal.
class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.centerLeft, child: SkeletonBox(width: 180, height: 40, borderRadius: BorderRadius.circular(14))),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerRight, child: SkeletonBox(width: 140, height: 34, borderRadius: BorderRadius.circular(14))),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: SkeletonBox(width: 210, height: 50, borderRadius: BorderRadius.circular(14))),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerRight, child: SkeletonBox(width: 100, height: 34, borderRadius: BorderRadius.circular(14))),
          ],
        ),
      ),
    );
  }
}
