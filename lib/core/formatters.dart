import 'package:intl/intl.dart';

final _priceFormat = NumberFormat.decimalPattern('fr');

String formatPrice(int? price, String currency, {String? priceType}) {
  if (price == null) return 'Sur devis';
  final base = '${_priceFormat.format(price)} $currency';
  switch (priceType) {
    case 'per_month':
      return '$base/mois';
    case 'per_day':
      return '$base/jour';
    default:
      return base;
  }
}

String formatRelativeDate(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return "À l'instant";
  if (diff.inMinutes < 60) return "il y a ${diff.inMinutes} min";
  if (diff.inHours < 24) return "il y a ${diff.inHours} h";
  if (diff.inDays < 7) return "il y a ${diff.inDays} j";
  return DateFormat('d MMM yyyy', 'fr').format(date);
}

const Map<String, String> listingTypeLabels = {
  'sale': 'Vente',
  'rent': 'Location',
  'service': 'Service',
  'job': 'Emploi',
};

const Map<String, String> accountTypeLabels = {
  'particular': 'Particulier',
  'professional': 'Professionnel',
  'artisan': 'Artisan',
};
