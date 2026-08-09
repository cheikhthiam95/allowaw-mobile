import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../services/category_service.dart';

/// Catégories actives — chargées une fois et réutilisées partout (accueil,
/// filtre de recherche, formulaire de dépôt d'annonce...) plutôt que
/// refaites à chaque écran.
class CategoriesProvider extends ChangeNotifier {
  final _service = CategoryService();

  List<Category> categories = [];
  bool loading = false;
  String? error;

  Future<void> load({bool force = false}) async {
    if (categories.isNotEmpty && !force) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      categories = await _service.index();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
