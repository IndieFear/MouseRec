## MouseRec 🖱️⌨️

**MouseRec** est une application macOS qui permet d’**enregistrer** vos mouvements de souris / clics / frappes clavier, puis de les **rejouer** automatiquement, avec contrôle de la vitesse et du nombre de répétitions.

Ce dépôt contient :
- le projet Xcode (`MouseRec.xcodeproj`)
- le code source de l’app (`MouseRec/`)
- les tests (`MouseRecTests/`, `MouseRecUITests/`)

---

## Fonctionnalités principales

- **Enregistrement global**
  - Capture des mouvements de souris, clics, glisser-déposer, touches clavier
  - Fonctionne même quand l’app est en arrière‑plan (avec les bonnes permissions)

- **Lecture automatisée**
  - Rejoue la séquence exactement comme enregistrée
  - Contrôle de la **vitesse** (x1, x2, x3, x5)
  - Modes de **répétition** : une fois, boucle infinie, nombre personnalisé

- **Raccourcis globaux**
  - `⌘⇧R` : démarrer / arrêter l’enregistrement
  - `⌘⇧P` : démarrer / arrêter la lecture
  - Les hotkeys ne sont **pas** enregistrés dans la séquence (pour éviter les boucles infinies)

- **Intégration Menu Bar**
  - Icône dans la barre de menu avec état visuel :
    - 🐭 : idle
    - 🔴 : enregistrement
    - 🟢 : lecture
  - Possibilité de cacher la fenêtre principale et de ne garder que l’icône de barre de menu

---

## Prérequis

- **macOS** : 11.0 ou supérieur
- **Xcode** : 15+ (idéalement la version utilisée dans ce repo)
- Compte développeur Apple (si vous voulez signer / distribuer l’app)

---

## Installation et lancement rapide

1. **Cloner le dépôt**

```bash
git clone https://github.com/IndieFear/MouseRec.git
cd MouseRec/MouseRec
```

2. **Ouvrir le projet dans Xcode**

Ouvrez `MouseRec.xcodeproj`, sélectionnez la cible `MouseRec`.

3. **Configurer les capacités (entitlements)**

Voir `CONFIGURATION.md` pour le détail, mais en résumé :
- Dans **Signing & Capabilities**, désactiver / supprimer **App Sandbox**
- Vérifier que le fichier `MouseRec.entitlements` est bien associé à la cible

4. **Vérifier `Info.plist`**

Assurez‑vous que :
- le chemin **Info.plist File** pointe vers `MouseRec/Info.plist`
- la clé `ITSAppUsesNonExemptEncryption` est à `NO` (si vous n’utilisez que le chiffrement système)

5. **Lancer l’app**

- Choisissez votre Mac comme cible
- `Cmd + R` pour lancer
- Au premier lancement, macOS demandera les **permissions d’accessibilité** (voir section suivante)

---

## Permissions d’accessibilité (obligatoire)

Pour enregistrer et rejouer des événements globaux, MouseRec doit être autorisée dans :
**Réglages Système → Confidentialité et sécurité → Accessibilité**.

Le flux est automatisé côté app (voir aussi `CONFIGURATION.md`) :

1. Au premier lancement, MouseRec essaie de poster un petit `CGEvent`
2. Cela force macOS à **ajouter MouseRec dans la liste Accessibilité**
3. L’app appelle `AXIsProcessTrustedWithOptions` avec l’option de prompt
4. Vous voyez :
   - un popup système Apple demandant les permissions
   - une alerte dans l’app avec un bouton **Open Settings**
5. Cliquez sur **Open Settings** :
   - les réglages s’ouvrent sur la page Accessibilité
   - cochez la case **MouseRec**
   - redémarrez l’app

Sans ces permissions :
- l’enregistrement / lecture ne fonctionnera pas
- les raccourcis globaux peuvent être bloqués

---

## Utilisation

### Enregistrer une séquence

1. Lancer l’app
2. Cliquer sur **Record** ou utiliser `⌘⇧R`
3. Effectuer vos actions (souris + clavier)
4. Cliquer de nouveau sur **Record** ou `⌘⇧R` pour arrêter  
   → le nombre d’événements enregistrés apparaît dans l’interface / la barre de menu.

### Configurer la lecture

- **Speed** : choisir x1, x2, x3 ou x5
- **Repeat** :
  - `Once` : une seule lecture
  - `Loop` : boucle infinie (arrêt manuel)
  - `Custom` : définir un nombre de répétitions (1–99)

### Lancer la lecture

1. S’assurer qu’il y a au moins un enregistrement
2. Cliquer sur **Play** ou utiliser `⌘⇧P`
3. Pour arrêter : cliquer de nouveau ou refaire `⌘⇧P`

### Mode Menu Bar

- Cliquer sur le bouton en haut à droite de la fenêtre pour la cacher
- L’icône disparaît du Dock et reste uniquement dans la barre de menu
- Depuis l’icône Menu Bar, vous pouvez :
  - lancer / arrêter l’enregistrement
  - lancer / arrêter la lecture
  - réafficher la fenêtre
  - quitter l’application

---

## Architecture du code

**Côté app (Swift / SwiftUI) :**

- `MouseRecApp.swift`  
  Point d’entrée de l’app (`@main`), configuration de l’`AppDelegate` et du `MenuBarManager`.

- `ContentView.swift`  
  Interface SwiftUI principale :
  - boutons Record / Play
  - réglages de vitesse et de répétition
  - intégration avec `MenuBarManager` et `HotkeyManager`

- `EventRecorder.swift`  
  Cœur métier :
  - création d’un **CGEventTap** via `CFMachPort` pour capturer les événements globaux
  - stockage des événements (`RecordedEvent`)
  - logique de **replay** (timing, vitesse, boucles)
  - filtrage des hotkeys (`⌘⇧R`, `⌘⇧P`) pour ne pas les rejouer

- `HotkeyManager.swift`  
  Gestion des raccourcis clavier globaux (via APIs type Carbon / EventHotKey) et callbacks vers `ContentView`.

- `MenuBarManager.swift`  
  Gestion de l’icône de barre de menu :
  - création du status item
  - mise à jour des menus et états (recording / playing / idle)
  - gestion de l’affichage / masquage de la fenêtre principale

- `Info.plist`  
  Descriptions des permissions (Accessibilité, Apple Events si nécessaire), catégorie d’app, etc.

- `MouseRec.entitlements`  
  Capacités de l’app (sandbox désactivé pour autoriser le tap global, etc.).

Les tests sont dans :
- `MouseRecTests/`
- `MouseRecUITests/`

---

## Développement & contributions

- **Lancer les tests** (depuis Xcode) :
  - `Cmd + U` sur la cible `MouseRecTests` ou `MouseRecUITests`
- **Style de code** :
  - Swift 5, SwiftUI pour l’UI
  - Préférence pour les types explicites et les noms clairs
  - Pas de commentaires redondants : uniquement pour expliquer des choix non évidents (ex : gestion du `CFMachPort`, cycle de vie du tap, etc.)

Si vous voulez contribuer :

- Ouvrez une **issue** pour discuter d’une fonctionnalité / bug
- Forkez le repo, créez une branche (`feature/...` ou `fix/...`)
- Ouvrez une **Pull Request** avec une description claire (FR ou EN)

---

## Sécurité & responsabilités

MouseRec capture et rejoue des événements globaux, ce qui peut inclure :
- des frappes clavier potentiellement sensibles
- des clics dans d’autres apps

Utilisation recommandée :
- uniquement sur vos propres machines
- éviter de partager des séquences contenant des données sensibles
- vérifier le code / binaire avant de l’exécuter en environnement de production

---

## Licence

Projet personnel de **Stanislas Peridy**.  
Utilisation à vos propres risques.  
Vous pouvez cloner et utiliser le projet pour un usage personnel ou pour l’étudier ; pour une redistribution ou un usage commercial, ouvrez d’abord une issue ou contactez l’auteur.
