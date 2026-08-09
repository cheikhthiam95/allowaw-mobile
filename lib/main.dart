import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/local_notifications.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/messages_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr');
  runApp(const AllowawApp());
}

class AllowawApp extends StatefulWidget {
  const AllowawApp({super.key});

  @override
  State<AllowawApp> createState() => _AllowawAppState();
}

class _AllowawAppState extends State<AllowawApp> {
  late final AuthProvider _auth;
  late final FavoritesProvider _favorites;
  late final MessagesProvider _messages;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    _favorites = FavoritesProvider();
    _messages = MessagesProvider();
    // Construit UNE seule fois : `refreshListenable: _auth` (voir
    // core/router.dart) fait déjà réévaluer les redirections à chaque
    // changement d'auth sans recréer le routeur — le recréer à chaque fois
    // (ancien code) perdait tout l'historique de navigation à chaque
    // connexion/déconnexion.
    _router = buildRouter(_auth);
    _auth.addListener(_onAuthChanged);
    _auth.bootstrap();
    LocalNotifications.init(
      onTap: (payload) {
        final id = int.tryParse(payload ?? '');
        if (id != null) _router.push('/messages/$id');
      },
    );
  }

  void _onAuthChanged() {
    if (_auth.isAuthenticated) {
      _favorites.load();
      _messages.startPolling();
    } else {
      _favorites.reset();
      _messages.stopPolling();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _favorites),
        ChangeNotifierProvider.value(value: _messages),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
      ],
      child: MaterialApp.router(
        title: 'Allowaw',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
