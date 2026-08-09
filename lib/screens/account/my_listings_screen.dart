import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/listing.dart';
import '../../services/listing_service.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_views.dart';

const _statusLabels = {
  'draft': 'Brouillon',
  'pending': 'En attente',
  'active': 'Active',
  'sold': 'Vendue',
  'expired': 'Expirée',
  'rejected': 'Rejetée',
};

const _statusColors = {
  'pending': AppColors.warning,
  'active': AppColors.success,
  'sold': AppColors.inkMuted,
  'expired': AppColors.inkMuted,
  'rejected': AppColors.danger,
};

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final _service = ListingService();
  List<Listing> _listings = [];
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
      final listings = await _service.myListings();
      setState(() => _listings = listings);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(Listing l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Supprimer cette annonce ?'),
        content: Text(l.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Supprimer', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.destroy(l.slug);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes annonces'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/listings/new'))],
      ),
      body: _loading
          ? const SkeletonListTiles()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _listings.isEmpty
                  ? EmptyView(
                      message: "Vous n'avez pas encore d'annonce",
                      emoji: '📦',
                      action: ElevatedButton(onPressed: () => context.push('/listings/new'), child: const Text('Déposer une annonce')),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _listings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final l = _listings[i];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: l.thumbnail != null
                                    ? Image.network(l.thumbnail!, width: 56, height: 56, fit: BoxFit.cover)
                                    : Container(width: 56, height: 56, color: AppColors.primary50, child: const Icon(Icons.image, color: AppColors.inkMuted)),
                              ),
                              title: Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(formatPrice(l.price, l.currency, priceType: l.priceType)),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (_statusColors[l.status] ?? AppColors.inkMuted).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _statusLabels[l.status] ?? l.status,
                                      style: TextStyle(fontSize: 11, color: _statusColors[l.status] ?? AppColors.inkMuted, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') context.push('/listings/${l.slug}/edit');
                                  if (v == 'view') context.push('/listings/${l.slug}');
                                  if (v == 'delete') _delete(l);
                                },
                                itemBuilder: (c) => const [
                                  PopupMenuItem(value: 'view', child: Text('Voir')),
                                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                  PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: AppColors.danger))),
                                ],
                              ),
                              onTap: () => context.push('/listings/${l.slug}'),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
