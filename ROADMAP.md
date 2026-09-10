# 🚀 Session History - Roadmap d'Installation et d'Exécution

## 📋 Table des Matières
1. [Technologies et Versions](#technologies-et-versions)
2. [Installation des Outils](#installation-des-outils)
3. [Configuration Frontend (Flutter)](#configuration-frontend-flutter)
4. [Configuration Backend (ASP.NET Core)](#configuration-backend-aspnet-core)
5. [Exécution sur les Plateformes](#exécution-sur-les-plateformes)
6. [Ordre de Démarrage](#ordre-de-démarrage)
7. [Credentials de Test](#credentials-de-test)

---

## 🛠️ Technologies et Versions

| Technologie | Version | Rôle |
|---|---|---|
| **Flutter** | 3.44.5 stable | Application mobile |
| **Dart** | 3.12.2 | Langage Flutter |
| **DevTools** | 2.57.0 | Débogage Flutter |
| **ASP.NET Core** | .NET 8 | Backend REST API |
| **.NET SDK installé** | 9.0.306 | SDK visible |
| **SQLite** | - | Base locale (stockage des données) |
| **Android / iOS** | - | Plateformes cibles |

---

## 📥 Installation des Outils

### 1️⃣ Flutter
**Lien officiel:** https://docs.flutter.dev/install/manual

```bash
# Vérifier l'installation
flutter --version  # Doit afficher: Flutter 3.44.5
dart --version     # Doit afficher: Dart 3.12.2
flutter doctor -v  # Vérifier tous les outils
```

**⚠️ Note:** Dart est déjà inclus dans Flutter. Pas besoin d'installation séparée.

---

### 2️⃣ Dart
**Lien officiel:** https://dart.dev/get-dart

✅ *Déjà inclus avec Flutter* - Pas d'installation supplémentaire requise.

---

### 3️⃣ ASP.NET Core 8
**Lien officiel:** https://dotnet.microsoft.com/download/dotnet/8.0

```bash
# Vérifier l'installation
dotnet --version  # Doit afficher: version 9.0.306 ou supérieure
```

---

### 4️⃣ Android Studio (pour Android)
**Inclus dans le flux Flutter**

```bash
# Accessible via flutter doctor
flutter doctor -v
```

---

### 5️⃣ Xcode (pour iOS - Mac uniquement)
**Installation sur Mac uniquement**

```bash
# Après installation Flutter et .NET 8
flutter doctor -v
```

**⚠️ Important:** Xcode fonctionne **uniquement sur macOS**. Pas d'installation sur Windows.

---

## 🎨 Configuration Frontend (Flutter)

### Chemin du projet Frontend
```
C:\Users\HP\Downloads\project-session-history-apk-main\session_history_app
```

### Commandes principales
```bash
# Naviguer vers le dossier Flutter
cd C:\Users\HP\Downloads\project-session-history-apk-main\project-session-history-apk-main\session_history_app

# Vérifier les versions
flutter --version
dart --version

# Vérifier la configuration
flutter doctor -v

# Obtenir les dépendances
flutter pub get

# Analyser le code
flutter analyze

# Lister les appareils disponibles
flutter devices
```

### En cas de problème de cache
```bash
flutter clean
flutter pub get
```

---

## 🔌 Configuration Backend (ASP.NET Core)

### Chemin du projet Backend
```
C:\Users\HP\Downloads\project-session-history-apk-main\SessionHistoryApiii\SessionHistoryApi
```

### Commandes principales
```bash
# Naviguer vers le dossier Backend
cd C:\Users\HP\Downloads\project-session-history-apk-main\project-session-history-apk-main\SessionHistoryApiii\SessionHistoryApi

# Vérifier la version .NET
dotnet --version

# Restaurer les dépendances
dotnet restore

# Construire le projet
dotnet build

# Exécuter l'application
dotnet run
```

### Exécuter sur le réseau local (téléphone physique)
```bash
dotnet run --urls "http://0.0.0.0:5080"
```

### Tester le Backend
**URL Swagger:** http://localhost:5080/swagger

---

## 📱 Exécution sur les Plateformes

### 1️⃣ Android Emulator

#### Étapes:
1. Ouvrir **Android Studio**
2. Aller dans **Tools > Device Manager**
3. Créer un appareil virtuel et choisir une image Android
4. Démarrer l'émulateur avec le bouton **▶**
5. Démarrer le backend: `dotnet run`
6. Dans Flutter, utiliser comme adresse API: `http://10.0.2.2:5080`

#### Commandes:
```bash
flutter devices
flutter run
```

---

### 2️⃣ Téléphone Android Physique

#### Prérequis:
- Activer **Options développeur** sur le téléphone
- Activer **Débogage USB**
- Brancher le téléphone au PC

#### Étapes:
```bash
# Vérifier que le téléphone est détecté
adb devices

# Obtenir l'adresse IPv4 du PC
ipconfig

# Copier l'adresse IPv4 trouvée (ex: 192.168.x.x)
# Mettre dans Flutter: http://IP_DU_PC:5080

# Vérifier les appareils Flutter
flutter devices

# Lancer l'application
flutter run
```

**⚠️ Conditions:**
- PC et téléphone sur le **même Wi-Fi**
- Backend démarré avec: `dotnet run --urls "http://0.0.0.0:5080"`

---

### 3️⃣ iOS Simulator (Mac uniquement)

#### Prérequis:
- Utiliser un **Mac**
- Installer **Flutter**, **.NET 8** et **Xcode**
- Cloner le projet sur le Mac

#### Commandes:
```bash
# Démarrer le backend
cd C:\Users\HP\Downloads\project-session-history-apk-main\SessionHistoryApiii\SessionHistoryApi
dotnet restore
dotnet run

# Dans un autre terminal, démarrer le simulateur
cd C:\Users\HP\Downloads\project-session-history-apk-main\session_history_app
flutter pub get
open -a Simulator

# Lancer Flutter
flutter devices
flutter run
```

**Adresse API:** `http://127.0.0.1:5080`

---

### 4️⃣ iPhone Physique (Mac uniquement)

#### Prérequis:
- Brancher l'iPhone au Mac
- Accepter **"Faire confiance"**
- Activer le **Mode développeur** sur l'iPhone
- Mac et iPhone sur le **même Wi-Fi**

#### Étapes:
1. Ouvrir `ios/Runner.xcworkspace` dans **Xcode**
2. Dans **Signing & Capabilities**, choisir une équipe Apple
3. Démarrer le backend: `dotnet run --urls "http://0.0.0.0:5080"`
4. Trouver l'IP du Mac: `ipconfig getifaddr en0`
5. Mettre dans Flutter: `http://IP_DU_MAC:5080`

#### Commandes:
```bash
# Démarrer le backend
cd C:\Users\HP\Downloads\project-session-history-apk-main\SessionHistoryApiii\SessionHistoryApi
dotnet run

# Obtenir l'IP du Mac
ipconfig getifaddr en0

# Lancer Flutter
cd C:\Users\HP\Downloads\project-session-history-apk-main\session_history_app
flutter devices
flutter run
```

#### Créer un fichier iOS (.ipa):
```bash
flutter build ipa --release
```

**Installation:** Utiliser **Xcode** ou **TestFlight**

---

## 🎯 Ordre de Démarrage

### Démarrage Quotidien (3 Terminaux)

**Terminal 1 - Backend:**
```bash
cd C:\Users\HP\Downloads\project-session-history-apk-main\SessionHistoryApiii\SessionHistoryApi
dotnet run
```

**Terminal 2 - Appareil:**
```bash
# Pour Android Emulator
flutter devices

# Pour téléphone physique
adb devices  # Android
# ou
flutter devices  # iOS
```

**Terminal 3 - Application Flutter:**
```bash
cd C:\Users\HP\Downloads\project-session-history-apk-main\session_history_app
flutter devices
flutter run -d <ID>
```

---

## 🌐 Résumé Adresses Réseau

| Plateforme | Adresse API |
|---|---|
| **Android Emulator** | `http://10.0.2.2:5080` |
| **iOS Simulator** | `http://127.0.0.1:5080` |
| **Téléphone Physique (Android)** | `http://IP_DU_PC:5080` |
| **iPhone Physique** | `http://IP_DU_MAC:5080` |

---

## 🔐 Credentials de Test

**Email:** test10@gmail.com  
**Password:** TEST100

---

## 📊 Récapitulatif Plateforme

| OS | Windows | Mac |
|---|---|---|
| **Android Emulator** | ✅ | ✅ |
| **Android Téléphone** | ✅ | ✅ |
| **iOS Simulator** | ❌ | ✅ |
| **iPhone Physique** | ❌ | ✅ |

**Conclusion:**
- **Windows** → Android Emulator + Téléphone Android
- **Mac** → Android + iOS Simulator + iPhone Physique

---

## 🆘 Troubleshooting

### Problème de cache Flutter
```bash
flutter clean
flutter pub get
```

### Vérifier l'installation complète
```bash
flutter doctor -v
```

### Lister les appareils disponibles
```bash
flutter devices
```

### Réinitialiser Android Studio
```bash
flutter clean
cd android
rm -rf .gradle
```

---

**Dernière mise à jour:** 2026-09-10  
**Version de la Roadmap:** 1.0
