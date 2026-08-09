# allôwaw — app mobile

App Flutter (Android/iOS) pour [Allôwaw](https://allowaw.sn), le marché en ligne du Sénégal. Consomme l'API JSON `/api/v1` du site Rails ([louga-plus](https://github.com/cheikhthiam95/louga-plus)) — même backend, mêmes données, authentification par jeton JWT.

## Pages couvertes

Toutes les pages du site "client" (hors panel Admin, qui reste web uniquement) :

- **Accueil** — hero, catégories, annonces récentes, artisans
- **Recherche** — autocomplétion (annonces + catégories) et résultats
- **Catégorie** — fiche catégorie, sous-catégories, annonces paginées
- **Annonces** — liste, fiche détaillée (galerie photo, vendeur, annonces similaires), dépôt et modification
- **Authentification** — connexion, inscription, mot de passe oublié, réinitialisation
- **Compte** — tableau de bord, mes annonces, favoris, profil, compléter mon profil
- **Messagerie** — conversations et chat par annonce
- **À propos / Contact**

## Prérequis

- [Flutter](https://docs.flutter.dev/get-started/install) (canal stable, testé avec 3.44.9)
- Un émulateur Android/iOS, ou un appareil physique connecté

## Lancer en local

```bash
flutter pub get
flutter run
```

Par défaut l'app pointe vers **`https://dev.allowaw.sn/api/v1`** (environnement de dev, données de démonstration riches : ~150 comptes, ~600 annonces avec photos). Pour pointer vers la production :

```bash
flutter run --dart-define=API_BASE_URL=https://allowaw.sn/api/v1
```

## Compte de test

N'importe quel compte créé via l'écran "S'inscrire" fonctionne. Vous pouvez aussi utiliser un compte existant côté dev si vous en avez un.

## Architecture

```
lib/
  core/        # thème, client HTTP (dio + JWT), config, formatage
  models/      # classes de données (User, Listing, Category, Conversation...)
  services/    # appels API par domaine (un fichier par ressource REST)
  providers/   # état applicatif partagé (auth, catégories, favoris)
  screens/     # un dossier par section, un fichier par écran
  widgets/     # composants réutilisés entre écrans (carte annonce, états vides/erreur...)
```

- **Auth** : jeton JWT stocké de façon sécurisée (`flutter_secure_storage`), envoyé en
  `Authorization: Bearer <token>` sur chaque requête authentifiée.
- **Routing** : `go_router`, avec redirections automatiques vers `/login` pour les pages
  qui nécessitent d'être connecté.
- **État** : `provider` (ChangeNotifier) — volontairement simple, pas de génération de code.

## Ce qui n'est pas encore couvert (phase 2 possible)

- Panel Admin (reste un usage web/back-office)
- Notifications push
- Mode hors-ligne / cache local des annonces

## Backend

Le code serveur (Rails + API `/api/v1`) vit dans
[github.com/cheikhthiam95/louga-plus](https://github.com/cheikhthiam95/louga-plus).
Les endpoints API et la logique de sérialisation sont partagés avec le site web via des
concerns Rails (voir `app/controllers/concerns/` dans ce repo) — un seul endroit modifié
pour que le web et le mobile restent synchronisés.
