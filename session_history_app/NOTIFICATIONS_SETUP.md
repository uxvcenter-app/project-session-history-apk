# Notifications et messages

Cette version distingue deux types de retour utilisateur :

1. **Après ajout d'une session** : simple message dans l'application (SnackBar
   « ... a été ajoutée avec succès »), pas de notification système.
2. **À la date et l'heure d'une session future** : vraie notification système
   `Rappel de session` — c'est la seule action qui déclenche une notification.
3. **Après suppression** : annulation du rappel programmé + message dans
   l'application (SnackBar « ... a été supprimée »), pas de notification
   système.

Les rappels sont aussi reprogrammés lorsque la liste des sessions est rechargée depuis le backend, et une modification de date/heure remplace l'ancien rappel.

## Premier lancement Android

Android 13+ peut demander l'autorisation d'envoyer des notifications.
Pour un rappel exact, Android peut aussi ouvrir l'autorisation système **Alarmes et rappels** lors de la première programmation d'une session future.

## Commandes

```bash
flutter clean
flutter pub get
flutter run
```

## Test rapide

1. Lance l'application sur un vrai téléphone Android.
2. Accepte les notifications.
3. Ajoute une session avec une heure située 2 à 5 minutes dans le futur.
4. Vérifie le message immédiat dans l'application (pas dans le centre de
   notifications) confirmant l'ajout.
5. Ferme/minimise l'application et attends l'heure choisie : la notification
   système `Rappel de session` doit apparaître.
6. Crée une autre session future puis supprime-la : un message dans
   l'application confirme la suppression et son rappel ne doit plus sonner.
