import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../services/conversation_service.dart';
import '../../widgets/state_views.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _service = ConversationService();
  List<Conversation> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.index();
      setState(() => _conversations = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: Center(
          child: ElevatedButton(onPressed: () => context.push('/login'), child: const Text('Se connecter')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _conversations.isEmpty
                  ? const EmptyView(message: 'Aucune conversation pour le moment', emoji: '💬')
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _conversations.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final c = _conversations[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary100,
                              child: Text(
                                c.otherUser.fullName.isNotEmpty ? c.otherUser.fullName[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(c.otherUser.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              c.lastMessage != null ? '${c.listingTitle} — ${c.lastMessage!.body}' : c.listingTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (c.lastMessage != null)
                                  Text(formatRelativeDate(c.lastMessage!.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.inkMuted)),
                                if (c.unreadCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(10)),
                                    child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                              ],
                            ),
                            onTap: () => context.push('/messages/${c.id}'),
                          );
                        },
                      ),
                    ),
    );
  }
}
