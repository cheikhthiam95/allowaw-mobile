import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/favorites_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    _favorites = FavoritesProvider();
    _auth.addListener(_onAuthChanged);
    _auth.bootstrap();
  }

  void _onAuthChanged() {
    if (_auth.isAuthenticated) {
      _favorites.load();
    } else {
      _favorites.reset();
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
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
      ],
      child: RouterProvider(
        builder: (router) => MaterialApp.router(
          title: 'Allowaw',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
  }
}
