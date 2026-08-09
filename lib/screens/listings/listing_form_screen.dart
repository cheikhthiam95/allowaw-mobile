import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/category.dart';
import '../../models/listing.dart';
import '../../providers/categories_provider.dart';
import '../../services/listing_service.dart';
import '../../widgets/state_views.dart';

const _priceTypes = {
  'fixed': 'Prix fixe',
  'per_month': 'Par mois',
  'per_day': 'Par jour',
  'on_quote': 'Sur devis',
};

/// Dépôt (Listings/New.jsx) et édition (Listings/Edit.jsx) d'annonce —
/// un seul écran, comportement différent selon [editSlug].
class ListingFormScreen extends StatefulWidget {
  final String? editSlug;
  const ListingFormScreen({super.key, this.editSlug});

  bool get isEdit => editSlug != null;

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ListingService();
  final _picker = ImagePicker();

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController(text: 'Louga');
  final _neighborhood = TextEditingController();

  Category? _category;
  Subcategory? _subcategory;
  String _listingType = 'sale';
  String _priceType = 'fixed';
  bool _priceNegotiable = false;
  final List<File> _newPhotos = [];
  List<ListingPhoto> _existingPhotos = [];
  final Set<String> _purgeIds = {};

  bool _loadingListing = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoriesProvider>().load();
    });
    if (widget.isEdit) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loadingListing = true);
    try {
      final (listing, _) = await _service.show(widget.editSlug!);
      _title.text = listing.title;
      _description.text = listing.description ?? '';
      _price.text = listing.price?.toString() ?? '';
      _city.text = listing.city ?? 'Louga';
      _neighborhood.text = listing.neighborhood ?? '';
      _listingType = listing.listingType;
      _priceType = listing.priceType ?? 'fixed';
      _priceNegotiable = listing.priceNegotiable;
      _existingPhotos = listing.existingPhotos;
      final cats = context.read<CategoriesProvider>().categories;
      _category = cats.where((c) => c.id == listing.category.id).firstOrNull;
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingListing = false);
    }
  }

  Future<void> _pickPhotos() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      setState(() => _newPhotos.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      setState(() => _error = 'Choisissez une catégorie.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final fields = {
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'listing_type': _listingType,
      'price': _price.text.trim().isEmpty ? null : _price.text.trim(),
      'price_type': _priceType,
      'price_negotiable': _priceNegotiable,
      'category_id': _category!.id,
      'subcategory_id': _subcategory?.id,
      'city': _city.text.trim(),
      'neighborhood': _neighborhood.text.trim(),
    };

    try {
      if (widget.isEdit) {
        await _service.update(widget.editSlug!, fields, photos: _newPhotos, purgePhotoIds: _purgeIds.toList());
      } else {
        await _service.create(fields, photos: _newPhotos);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isEdit ? 'Annonce mise à jour.' : 'Annonce soumise ! Elle sera visible après validation.'),
      ));
      if (widget.isEdit) {
        context.pop();
      } else {
        context.go('/account/listings');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesProvider = context.watch<CategoriesProvider>();

    if (_loadingListing) {
      return Scaffold(appBar: AppBar(title: const Text('Modifier')), body: const LoadingView());
    }

    final allowedTypes = _category?.allowedListingTypes;
    if (allowedTypes != null && allowedTypes.isNotEmpty && !allowedTypes.contains(_listingType)) {
      _listingType = allowedTypes.first;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? "Modifier l'annonce" : 'Déposer une annonce')),
      body: categoriesProvider.loading
          ? const LoadingView()
          : Padding(
              padding: const EdgeInsets.all(20),
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
                    const Text('Catégorie', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Category>(
                      initialValue: _category,
                      hint: const Text('Choisir une catégorie'),
                      items: categoriesProvider.categories
                          .map((c) => DropdownMenuItem(value: c, child: Text('${c.icon ?? ''} ${c.name}')))
                          .toList(),
                      onChanged: (c) => setState(() {
                        _category = c;
                        _subcategory = null;
                      }),
                    ),
                    if (_category != null && _category!.subcategories.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<Subcategory>(
                        initialValue: _subcategory,
                        hint: const Text('Sous-catégorie (optionnel)'),
                        items: _category!.subcategories
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                            .toList(),
                        onChanged: (s) => setState(() => _subcategory = s),
                      ),
                    ],
                    if (allowedTypes != null && allowedTypes.length > 1) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        children: allowedTypes
                            .map((t) => ChoiceChip(
                                  label: Text(listingTypeLabels[t] ?? t),
                                  selected: _listingType == t,
                                  onSelected: (_) => setState(() => _listingType = t),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Titre'),
                      validator: (v) => (v == null || v.trim().length < 5) ? '5 caractères minimum' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _description,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
                      validator: (v) => (v == null || v.trim().length < 20) ? '20 caractères minimum' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _price,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Prix (FCFA)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _priceType,
                            decoration: const InputDecoration(labelText: 'Type de prix'),
                            items: _priceTypes.entries
                                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                .toList(),
                            onChanged: (v) => setState(() => _priceType = v!),
                          ),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      value: _priceNegotiable,
                      onChanged: (v) => setState(() => _priceNegotiable = v ?? false),
                      title: const Text('Prix négociable'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _city,
                            decoration: const InputDecoration(labelText: 'Ville'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _neighborhood,
                            decoration: const InputDecoration(labelText: 'Quartier'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Photos', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _PhotosPicker(
                      existing: _existingPhotos,
                      purged: _purgeIds,
                      newFiles: _newPhotos,
                      onTogglePurge: (blobId) => setState(() {
                        _purgeIds.contains(blobId) ? _purgeIds.remove(blobId) : _purgeIds.add(blobId);
                      }),
                      onRemoveNew: (f) => setState(() => _newPhotos.remove(f)),
                      onAdd: _pickPhotos,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.isEdit ? 'Enregistrer' : "Publier l'annonce"),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PhotosPicker extends StatelessWidget {
  final List<ListingPhoto> existing;
  final Set<String> purged;
  final List<File> newFiles;
  final ValueChanged<String> onTogglePurge;
  final ValueChanged<File> onRemoveNew;
  final VoidCallback onAdd;

  const _PhotosPicker({
    required this.existing,
    required this.purged,
    required this.newFiles,
    required this.onTogglePurge,
    required this.onRemoveNew,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...existing.map((p) {
          final isPurged = purged.contains(p.blobId);
          return Stack(
            children: [
              Opacity(
                opacity: isPurged ? 0.3 : 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(p.url, width: 80, height: 80, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => onTogglePurge(p.blobId),
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: isPurged ? AppColors.success : AppColors.danger,
                    child: Icon(isPurged ? Icons.undo : Icons.close, size: 13, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        }),
        ...newFiles.map((f) => Stack(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(f, width: 80, height: 80, fit: BoxFit.cover)),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => onRemoveNew(f),
                    child: const CircleAvatar(radius: 11, backgroundColor: AppColors.danger, child: Icon(Icons.close, size: 13, color: Colors.white)),
                  ),
                ),
              ],
            )),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line, style: BorderStyle.solid),
            ),
            child: const Icon(Icons.add_a_photo_outlined, color: AppColors.inkMuted),
          ),
        ),
      ],
    );
  }
}
