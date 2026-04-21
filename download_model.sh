#!/bin/bash
echo "=== Téléchargement du modèle Whisper ==="
echo "Modèle : ggml-base.en.bin (Idéal pour la traduction vers l'anglais)"

mkdir -p models
cd models

if [ -f "ggml-base.bin" ]; then
    echo "✅ Le modèle est déjà téléchargé dans le dossier 'models'."
else
    echo "⏳ Téléchargement en cours (environ 140 Mo)..."
    curl -L -o ggml-base.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin
    echo "✅ Téléchargement terminé !"
fi
