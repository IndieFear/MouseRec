# MouseRec 🖱️⌨️

Une application macOS moderne pour enregistrer et rejouer les mouvements de souris et les frappes clavier.

## ✨ Fonctionnalités

- 🔴 **Enregistrement** : Capture tous les mouvements de souris, clics et frappes clavier
- ▶️ **Lecture** : Rejoue les actions enregistrées avec précision
- ⚡ **Vitesse variable** : Lecture à x1, x2, x3 ou x5
- 🔁 **Modes de répétition** : 
  - Une seule fois
  - Boucle infinie
  - Nombre personnalisé de répétitions
- 🎨 **Interface moderne** : Design compact et élégant
- 📍 **Menu Bar** : Icône dans la barre de menu avec changement selon l'état
  - 🐭 Emoji souris : Idle (prêt)
  - 🔴 Cercle rouge : Enregistrement en cours
  - 🟢 Cercle vert : Lecture en cours
- 👁️ **Mode caché** : Possibilité de cacher la fenêtre et utiliser uniquement l'icône dans la barre de menu
  - L'icône de l'application disparaît automatiquement du Dock quand la fenêtre est cachée
  - L'icône réapparaît dans le Dock quand la fenêtre est affichée

## 🚀 Installation

1. Ouvrez le projet dans Xcode
2. Compilez et lancez l'application
3. **Important** : Au premier lancement :
   - macOS affiche un dialogue système pour les permissions
   - L'application affiche une alerte avec des instructions
   - **MouseRec est automatiquement ajouté à la liste** dans Accessibilité
4. Cliquez sur "Open Settings" pour ouvrir les Préférences Système
5. MouseRec apparaît déjà dans la liste - **cochez simplement la case** à côté
6. Redémarrez l'application et profitez !

## 🔑 Permissions requises

### Permissions d'Accessibilité

Pour que MouseRec puisse enregistrer et rejouer les événements, vous devez accorder les permissions d'accessibilité :

**Processus automatique** :
1. L'application détecte automatiquement l'absence de permissions
2. Elle crée un événement CGEvent pour **forcer macOS à l'ajouter à la liste d'Accessibilité**
3. macOS affiche ensuite un dialogue système demandant les permissions
4. Une alerte de l'application vous guide vers les Préférences Système
5. Dans Accessibilité, **MouseRec est déjà dans la liste** - cochez simplement la case

**Comment ça marche** :
- L'application utilise `CGEvent.post()` pour s'enregistrer auprès du système
- Cette technique garantit que l'application apparaît automatiquement dans la liste
- Basé sur la [solution recommandée par la communauté](https://stackoverflow.com/questions/76807911/trying-to-add-my-app-to-system-settings-privacy-and-security-accessibility)

**Processus manuel** (si nécessaire) :
1. Allez dans **Préférences Système** > **Sécurité et confidentialité** > **Confidentialité** > **Accessibilité**
2. Cliquez sur le cadenas en bas à gauche et entrez votre mot de passe
3. Si MouseRec n'est pas dans la liste (rare), cliquez sur "+" pour l'ajouter
4. Cochez la case à côté de MouseRec

⚠️ **Sans ces permissions, l'application ne pourra pas fonctionner correctement.**

## 📋 Configuration Xcode

Pour compiler le projet, vous devez configurer quelques paramètres dans Xcode :

### 1. Désactiver le Sandboxing

Dans les paramètres du projet (`Project Settings` > `Signing & Capabilities`):
- Vérifiez que le fichier `MouseRec.entitlements` est bien lié
- Le sandboxing doit être désactivé (`com.apple.security.app-sandbox = false`)

### 2. Info.plist

Le fichier `Info.plist` contient les descriptions des permissions requises.

## 🎯 Utilisation

1. **Enregistrer** :
   - Cliquez sur le bouton "Enregistrer" ou utilisez **⌘⇧R**
   - Effectuez vos actions de souris et clavier
   - Cliquez à nouveau ou utilisez **⌘⇧R** pour arrêter l'enregistrement

2. **Configurer la lecture** :
   - Choisissez la vitesse de lecture (x1 à x5)
   - Sélectionnez le mode de répétition
   - Si vous choisissez "Nombre de fois", définissez le nombre de répétitions

3. **Lire** :
   - Cliquez sur "Lire" ou utilisez **⌘⇧P** pour rejouer l'enregistrement
   - Cliquez sur "Arrêter" ou utilisez **⌘⇧P** pour stopper la lecture

4. **Utiliser le Menu Bar** :
   - Cliquez sur l'icône en haut à droite de la fenêtre pour cacher la fenêtre
   - L'icône dans la barre de menu change de couleur selon l'état
   - Cliquez sur l'icône dans la barre de menu pour accéder aux commandes
   - Sélectionnez "Show Window" pour afficher à nouveau la fenêtre

## ⌨️ Raccourcis clavier

- **⌘⇧R** (Cmd + Shift + R) : Démarrer/Arrêter l'enregistrement
- **⌘⇧P** (Cmd + Shift + P) : Démarrer/Arrêter la lecture

**Note** : Les raccourcis clavier ne sont pas enregistrés dans la séquence pour éviter les boucles infinies lors de la lecture.

## ⚙️ Paramètres

### Vitesse de lecture
- **x1** : Vitesse normale
- **x2** : Deux fois plus rapide
- **x3** : Trois fois plus rapide
- **x5** : Cinq fois plus rapide

### Modes de répétition
- **Une fois** : Lecture unique
- **Boucle** : Répétition infinie (arrêt manuel requis)
- **Nombre de fois** : Nombre personnalisé de 1 à 99 répétitions

## 🛠️ Technologies

- **SwiftUI** : Interface utilisateur moderne
- **CoreGraphics** : Capture et simulation d'événements système
- **Concurrency** : Gestion asynchrone avec Swift Async/Await

## ⚠️ Notes importantes

- L'application nécessite **macOS 11.0+**
- Les permissions d'accessibilité sont **obligatoires**
- Le sandboxing doit être **désactivé** pour permettre la capture d'événements globaux
- Utilisez cette application de manière responsable

## 🔒 Sécurité

Cette application capture les événements globaux du système, ce qui nécessite des permissions élevées. Assurez-vous de :
- Télécharger uniquement depuis des sources fiables
- Vérifier le code source avant de compiler
- Ne jamais partager vos enregistrements s'ils contiennent des informations sensibles

## 📝 Licence

Projet personnel - Utilisez à vos propres risques.

---

Créé avec ❤️ par Stanislas Peridy

