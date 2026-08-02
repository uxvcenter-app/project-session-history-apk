# Session History – Module de gestion locale de sessions

Application mobile Flutter (Android / iOS) permettant de stocker, gérer et
rechercher des sessions localement sur l'appareil (SQLite), avec
authentification locale et fonctions IA légères (résumé automatique,
extraction de mots-clés, suggestion de catégorie).

## Stack technique

| Domaine              | Techno                                   |
|-----------------------|-------------------------------------------|
| UI / Mobile           | Flutter / Dart (Android & iOS)            |
| Base de données locale| SQLite (`sqflite`)                        |
| Gestion d'état        | Provider                                  |
| Authentification      | Locale (hash SHA-256 + SharedPreferences) |
| Graphiques             | `fl_chart`                                |
| IA locale              | Heuristiques Dart (fréquence de mots, scoring de phrases) |
| Versioning             | Git                                       |

Le sujet mentionne un backend ASP.NET Core optionnel : l'architecture
actuelle est **offline-first** (100% fonctionnelle sans serveur). Une
couche `ApiService` peut être ajoutée plus tard pour synchroniser les
sessions vers une API REST ASP.NET Core (voir section "Étapes suivantes").

## Structure du projet

```
lib/
├── main.dart                     # Point d'entrée + injection des providers
├── core/
│   └── theme/                    # Couleurs et thème global (violet, fidèle à la maquette)
├── models/                       # SessionModel, CategoryModel, UserModel
├── services/
│   ├── database_service.dart     # Toutes les requêtes SQLite (CRUD + stats)
│   ├── auth_service.dart         # Inscription / connexion locale
│   └── ai_service.dart           # Résumé, mots-clés, classification automatique
├── providers/
│   ├── auth_provider.dart
│   └── session_provider.dart
├── widgets/                      # SessionCard, CustomTextField (réutilisables)
└── screens/
    ├── auth/                     # Splash, Welcome, Login, Register
    ├── home/                     # Dashboard + navigation basse
    ├── sessions/                 # Liste, détail, ajout, édition
    ├── search/
    ├── statistics/                # Graphiques (camembert + barres)
    ├── categories/
    └── settings/
```

## Fonctionnalités implémentées

- Authentification locale (inscription / connexion / déconnexion, session persistée)
- Dashboard avec statistiques (total, ce mois-ci, catégories, favoris)
- CRUD complet des sessions (titre, catégorie, date, heure, contenu, tags)
- Recherche full-text (titre, contenu, tags)
- Filtres (Toutes / Favoris / par catégorie)
- Statistiques : répartition par catégorie (camembert) + activité sur 7 jours (barres)
- Écran Catégories avec compteur de sessions
- Paramètres (dark mode toggle UI, export/import placeholders, suppression des données)
- **Fonctions IA locales, sans réseau :**
  - Extraction automatique de mots-clés (fréquence de mots pondérée)
  - Résumé automatique (scoring de phrases par mots-clés)
  - Suggestion automatique de catégorie à partir du titre/contenu

## Installation

```bash
flutter pub get
flutter run
```

Prérequis : Flutter SDK ≥ 3.3, un émulateur Android ou un simulateur iOS
(ou un appareil physique).

## Étapes suivantes suggérées (pour aller plus loin dans votre stage)

1. **Synchronisation backend** : créer une API ASP.NET Core (`SessionsController`,
   `AuthController`) exposant les mêmes opérations, avec Entity Framework Core
   + SQL Server/PostgreSQL, puis ajouter un `ApiService` Dart (package `http` ou `dio`)
   avec synchronisation bidirectionnelle et gestion des conflits.
2. **Authentification robuste** : remplacer le hash simple par un flux JWT
   (access + refresh token) une fois le backend en place.
3. **Vrai NLP** : remplacer `ai_service.dart` par un appel à un modèle de langage
   (API Anthropic/OpenAI) ou un modèle on-device (TensorFlow Lite) pour un
   résumé/classification plus précis.
4. **Tests** : ajouter des tests unitaires (`ai_service`, `database_service`)
   et des tests de widgets (`flutter_test`).
5. **CI/CD** : pipeline GitHub Actions (`flutter analyze`, `flutter test`, build APK).

## Git

```bash
git init
git add .
git commit -m "Initial commit: Session History module"
```
