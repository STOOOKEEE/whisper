# SuperWhisper Natif (macOS Swift) 🎙️➡️🇬🇧

Une application macOS en ligne de commande (CLI) écrite en **Swift** pur, permettant de capturer de l'audio en français (ou toute autre langue), de le traduire instantanément en anglais grâce à l'IA d'OpenAI (Whisper), et d'écrire le résultat de manière active dans la fenêtre que vous utilisez.

C'est la version "vraie" et optimisée pour macOS, utilisant `whisper.cpp` avec l'accélération matérielle Apple Silicon (Metal/Accelerate) au lieu de Python.

**Particularités :**
- **100% Local & Natif :** Écrit en Swift.
- **Ultra-rapide :** Utilise `whisper.cpp` (C/C++) sous le capot. Moins de RAM, pas d'environnement virtuel Python lourd.
- **Raccourci Global :** `Option + Espace` lance et arrête l'enregistrement, où que vous soyez.
- **Injection Directe :** Utilise le presse-papier et les API d'accessibilité (Cmd+V) pour coller instantanément le résultat.

## Prérequis
- Un Mac sous **macOS 13 (Ventura) ou ultérieur**.
- **Xcode Command Line Tools** (`xcode-select --install`).
- Autorisations **Accessibilité** et **Microphone** pour l'application Terminal/iTerm.

## Installation

1. Téléchargez le modèle Whisper (fichier `.bin`) :
   ```bash
   chmod +x download_model.sh
   ./download_model.sh
   ```

2. Compilez l'application en mode "Release" (pour une vitesse d'exécution maximale) :
   ```bash
   swift build -c release
   ```

## Utilisation

Lancez le programme en lui passant le chemin du modèle téléchargé :
```bash
./.build/release/SuperWhisper models/ggml-base.bin
```

1. Placez votre curseur dans l'application où vous voulez écrire (Notes, Navigateur, Slack, etc.).
2. Appuyez sur **Option + Espace** (`⌥ + Espace`).
3. Parlez en français.
4. Appuyez à nouveau sur **Option + Espace**.
5. Le texte traduit en anglais va s'écrire tout seul !

## Technique
* `Swift Package Manager` pour la gestion des dépendances.
* `SwiftWhisper` (Wrapper Swift pour `whisper.cpp`).
* `AVFoundation` pour l'enregistrement audio natif 16kHz PCM.
* `CGEvent` et API Accessibilité pour l'interception du clavier et l'injection du texte.
