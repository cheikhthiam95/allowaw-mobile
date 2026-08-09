import 'package:flutter/foundation.dart';
import '../services/favorite_service.dart';

/// Suit l'ensemble des ids d'annonces favorites de l'utilisateur connecté,
/// pour que le cœur (favori) reste synchronisé sur tous les écrans
/// (accueil, recherche, fiche annonce...) sans recharger depuis l'API à
/// chaque fois qu'on l'affiche.
class FavoritesProvider extends ChangeNotifier {
  final _service = FavoriteService();

  final Map<int, int> _listingIdToFavoriteId = {}; // listingId -> favoriteId
  List<FavoriteItem> items = [];
  bool loaded = false;

  bool isFavorited(int listingId) => _listingIdToFavoriteId.containsKey(listingId);
  int? favoriteIdFor(int listingId) => _listingIdToFavoriteId[listingId];

  Future<void> load() async {
    items = await _service.index();
    _listingIdToFavoriteId
      ..clear()
      ..addEntries(items.map((f) => MapEntry(f.listing.id, f.id)));
    loaded = true;
    notifyListeners();
  }

  void hydrateFromListing(int listingId, bool isFavorited, int? favoriteId) {
    if (isFavorited && favoriteId != null) {
      _listingIdToFavoriteId[listingId] = favoriteId;
    }
  }

  Future<void> toggle(int listingId) async {
    if (isFavorited(listingId)) {
      final favId = _listingIdToFavoriteId[listingId]!;
      _listingIdToFavoriteId.remove(listingId);
      notifyListeners();
      await _service.remove(favId);
      items.removeWhere((f) => f.listing.id == listingId);
    } else {
      final favId = await _service.add(listingId);
      _listingIdToFavoriteId[listingId] = favId;
      notifyListeners();
    }
  }

  void reset() {
    _listingIdToFavoriteId.clear();
    items = [];
    loaded = false;
  }
}
