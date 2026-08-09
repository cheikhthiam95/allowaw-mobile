import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/account/account_dashboard_screen.dart';
import '../screens/account/complete_profile_screen.dart';
import '../screens/account/favorites_screen.dart';
import '../screens/account/my_listings_screen.dart';
import '../screens/account/profile_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/categories/category_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/listings/listing_detail_screen.dart';
import '../screens/listings/listing_form_screen.dart';
import '../screens/listings/listings_index_screen.dart';
import '../screens/messages/conversation_detail_screen.dart';
import '../screens/messages/conversations_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/shell.dart';
import '../screens/static/about_screen.dart';
import '../screens/static/contact_screen.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggingIn = ['/login', '/register', '/forgot-password', '/reset-password'].contains(state.matchedLocation);
      final needsAuth = _authRequiredPaths.any((p) => state.matchedLocation.startsWith(p)) ||
          state.matchedLocation.endsWith('/edit');

      if (auth.status == AuthStatus.unknown) return null; // attend le bootstrap
      if (needsAuth && !auth.isAuthenticated) return '/login?redirect=${Uri.encodeComponent(state.matchedLocation)}';
      if (loggingIn && auth.isAuthenticated) return '/';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
          GoRoute(path: '/search', builder: (c, s) => SearchScreen(initialQuery: s.uri.queryParameters['q'])),
          GoRoute(path: '/messages', builder: (c, s) => const ConversationsScreen()),
          GoRoute(path: '/account', builder: (c, s) => const AccountDashboardScreen()),
        ],
      ),
      GoRoute(path: '/login', builder: (c, s) => LoginScreen(redirectTo: s.uri.queryParameters['redirect'])),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (c, s) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (c, s) => ResetPasswordScreen(token: s.uri.queryParameters['token']),
      ),
      GoRoute(path: '/a-propos', builder: (c, s) => const AboutScreen()),
      GoRoute(path: '/contact', builder: (c, s) => const ContactScreen()),
      GoRoute(path: '/categories/:slug', builder: (c, s) => CategoryScreen(slug: s.pathParameters['slug']!)),
      GoRoute(path: '/listings', builder: (c, s) => const ListingsIndexScreen()),
      GoRoute(path: '/listings/new', builder: (c, s) => const ListingFormScreen()),
      GoRoute(path: '/listings/:slug', builder: (c, s) => ListingDetailScreen(slug: s.pathParameters['slug']!)),
      GoRoute(
        path: '/listings/:slug/edit',
        builder: (c, s) => ListingFormScreen(editSlug: s.pathParameters['slug']),
      ),
      GoRoute(path: '/account/listings', builder: (c, s) => const MyListingsScreen()),
      GoRoute(path: '/account/favorites', builder: (c, s) => const FavoritesScreen()),
      GoRoute(path: '/account/profile', builder: (c, s) => const ProfileScreen()),
      GoRoute(path: '/account/complete-profile', builder: (c, s) => const CompleteProfileScreen()),
      GoRoute(
        path: '/messages/:id',
        builder: (c, s) => ConversationDetailScreen(conversationId: int.parse(s.pathParameters['id']!)),
      ),
    ],
  );
}

const _authRequiredPaths = [
  '/account',
  '/messages',
  '/listings/new',
];

/// Aide pour construire le routeur avec le AuthProvider déjà présent dans
/// l'arbre de widgets (voir main.dart).
class RouterProvider extends StatelessWidget {
  final Widget Function(GoRouter router) builder;
  const RouterProvider({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return builder(buildRouter(auth));
  }
}
