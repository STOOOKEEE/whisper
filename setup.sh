#!/bin/bash
echo "=== Installation de SuperWhisper Local ==="

echo "1. Création de l'environnement virtuel (venv)..."
python3 -m venv venv

echo "2. Activation de l'environnement et mise à jour de pip..."
source venv/bin/activate
pip install --upgrade pip

echo "3. Installation des dépendances (cela peut prendre quelques minutes pour PyTorch et Whisper)..."
pip install -r requirements.txt

echo "=== Installation terminée ! ==="
echo ""
echo "Pour utiliser le programme, tapez :"
echo "source venv/bin/activate"
echo "python superwhisper.py"
