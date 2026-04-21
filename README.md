# SuperWhisper Local (Mac) 🎙️➡️🇬🇧

Une application macOS en ligne de commande permettant de capturer de l'audio en français (ou toute autre langue), de le traduire instantanément en anglais grâce à l'IA d'OpenAI (Whisper), et d'écrire le résultat de manière active dans la fenêtre que vous utilisez, tout comme l'application Superwhisper premium.

**Particularités :**
- **100% Local :** Tourne sur le CPU de votre Mac. Aucun abonnement, aucune API distante, données privées.
- **Ultra-rapide :** Utilise `faster-whisper` avec un modèle quantifié (compressé en int8) pour une performance optimale.
- **Raccourci Global :** `Option + Espace` lance et arrête l'enregistrement n'importe où.

## Prérequis

1. Python 3.9 ou plus
2. **Autorisations macOS :** Votre Terminal (ou l'éditeur de code que vous utilisez, par ex. VSCode, iTerm) doit avoir l'accès à **Accessibilité** (pour surveiller le clavier) et au **Microphone**.
   - Allez dans `Réglages Système` > `Confidentialité et sécurité` > `Accessibilité` (cochez votre Terminal).
   - Allez dans `Réglages Système` > `Confidentialité et sécurité` > `Microphone` (cochez votre Terminal).

## Installation Rapide

1. Exécutez le script d'installation :
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
   *(Ce script créera l'environnement virtuel et installera les paquets de `requirements.txt`)*

2. Activez l'environnement :
   ```bash
   source venv/bin/activate
   ```

## Utilisation

Lancez le programme :
```bash
python superwhisper.py
```

1. Placez votre curseur dans l'application où vous voulez écrire (Notes, Navigateur, Slack, etc.).
2. Appuyez sur **Option + Espace** (`⌥ + Espace`).
3. Parlez en français.
4. Appuyez à nouveau sur **Option + Espace** (`⌥ + Espace`).
5. Le texte traduit en anglais va s'écrire tout seul !

## Technique
* `faster-whisper` (Moteur CTranslate2 hyper optimisé)
* `pynput` (Gestion du raccourci clavier global et frappe)
* `sounddevice` & `numpy` (Capture audio)
