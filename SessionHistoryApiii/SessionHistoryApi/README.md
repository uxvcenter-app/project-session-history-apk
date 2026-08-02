# Session History API (ASP.NET Core + SQLite)

Backend REST pour l'app Flutter "Session History" : inscription avec
vérification d'email (code à 6 chiffres), connexion JWT, et gestion des
sessions (CRUD + recherche).

## Stack

- ASP.NET Core 8 Web API
- Entity Framework Core + **SQLite** (fichier `sessionhistory.db`, aucun serveur à installer)
- Authentification JWT (Bearer token)
- Mots de passe hashés avec BCrypt
- Envoi d'email via SMTP (`System.Net.Mail`)
- Swagger UI pour tester l'API facilement

## Installation

### Prérequis
- [.NET 8 SDK](https://dotnet.microsoft.com/download)

### 1. Restaurer les dépendances
```bash
cd SessionHistoryApi
dotnet restore
```

### 2. Configurer l'envoi d'email (obligatoire pour l'inscription)

Ouvrez `appsettings.json` et remplissez la section `Email` :

```json
"Email": {
  "SmtpHost": "smtp.gmail.com",
  "SmtpPort": 587,
  "SenderEmail": "votre.email@gmail.com",
  "SenderName": "Session History",
  "SenderPassword": "VOTRE_MOT_DE_PASSE_APPLICATION",
  "EnableSsl": true
}
```

**Important pour Gmail** : vous ne pouvez pas utiliser votre mot de passe Gmail normal.
Il faut créer un **"mot de passe d'application"** :
1. Activez la validation en 2 étapes sur votre compte Google
2. Allez sur https://myaccount.google.com/apppasswords
3. Créez un mot de passe d'application pour "Mail"
4. Collez ce mot de passe (16 caractères) dans `SenderPassword`

Vous pouvez aussi utiliser un autre fournisseur SMTP (Outlook, SendGrid, Mailtrap
pour les tests, etc.) en changeant `SmtpHost`/`SmtpPort`.

### 3. Changer la clé JWT

Dans `appsettings.json`, remplacez `Jwt:Key` par une chaîne aléatoire d'au
moins 32 caractères (ne gardez jamais la valeur par défaut en production).

### 4. Lancer l'API

```bash
dotnet run
```

La base SQLite (`sessionhistory.db`) est créée automatiquement au premier
démarrage. Swagger est disponible sur `https://localhost:xxxx/swagger`
(le port exact s'affiche dans le terminal au lancement).

## Endpoints

| Méthode | Route                       | Description                                  | Auth |
|---------|------------------------------|-----------------------------------------------|------|
| POST    | `/api/auth/register`         | Crée le compte, envoie le code par email      | Non  |
| POST    | `/api/auth/verify-email`     | Vérifie le code, retourne un token JWT        | Non  |
| POST    | `/api/auth/resend-code`      | Renvoie un nouveau code                       | Non  |
| POST    | `/api/auth/login`            | Connexion (refusée si email non vérifié)      | Non  |
| GET     | `/api/sessions`               | Liste des sessions de l'utilisateur connecté  | Oui  |
| GET     | `/api/sessions/{id}`          | Détail d'une session                          | Oui  |
| POST    | `/api/sessions`               | Créer une session                             | Oui  |
| PUT     | `/api/sessions/{id}`          | Modifier une session                          | Oui  |
| DELETE  | `/api/sessions/{id}`          | Supprimer une session                         | Oui  |
| GET     | `/api/sessions/search?q=...`  | Recherche full-text                           | Oui  |

Pour les routes protégées, ajoutez l'en-tête :
```
Authorization: Bearer <token reçu à la connexion/vérification>
```

## Exemple de flux complet (avec curl)

```bash
# 1. Inscription
curl -X POST https://localhost:xxxx/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"fullName":"Ihssane Ghalmi","email":"ihssane@example.com","password":"MonMotDePasse1"}'

# 2. Vérification (code reçu par email)
curl -X POST https://localhost:xxxx/api/auth/verify-email \
  -H "Content-Type: application/json" \
  -d '{"email":"ihssane@example.com","code":"123456"}'
# -> retourne un token JWT

# 3. Créer une session (avec le token reçu)
curl -X POST https://localhost:xxxx/api/sessions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -d '{"title":"Flutter Dev","category":"work","date":"2026-07-11T00:00:00Z","time":"10:30","content":"...","tags":["flutter"]}'
```

## Prochaine étape : connecter l'app Flutter

Pour que l'app mobile utilise cette API au lieu de la base SQLite locale,
il faut ajouter côté Flutter :
- Un `ApiService` (package `http` ou `dio`) qui appelle ces endpoints
- Un écran de saisie du code de vérification après l'inscription
- Le stockage du token JWT (`flutter_secure_storage` recommandé)
- Une stratégie de synchronisation (garder SQLite en local comme cache + sync
  vers l'API, ou basculer entièrement sur l'API)

Dites-le moi si vous voulez que je code cette partie Flutter également.
