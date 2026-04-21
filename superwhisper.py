import os
import queue
import threading
import numpy as np
import sounddevice as sd
from faster_whisper import WhisperModel
from pynput import keyboard
import time
import sys

# --- Configuration ---
# Le modèle "base" est rapide, consomme peu de RAM (parfait pour du on-device Mac)
# et est suffisamment précis pour la traduction avec Whisper.
MODEL_SIZE = "base"
SAMPLE_RATE = 16000

print("\n🚀 Initialisation de SuperWhisper Local...")
print(f"📦 Chargement du modèle Whisper '{MODEL_SIZE}' (compression int8)...")

# Désactiver les avertissements liés à la duplication de librairies (fréquent sur macOS avec ML)
os.environ['KMP_DUPLICATE_LIB_OK'] = 'True'

try:
    # La compression int8 permet au modèle d'être hyper léger et rapide sur le CPU du Mac
    model = WhisperModel(MODEL_SIZE, device="cpu", compute_type="int8")
    print("✅ Modèle chargé avec succès.\n")
except Exception as e:
    print(f"❌ Erreur lors du chargement du modèle: {e}")
    sys.exit(1)

is_recording = False
audio_queue = queue.Queue()
keyboard_controller = keyboard.Controller()

def audio_callback(indata, frames, time_info, status):
    """Callback appelé par sounddevice pour chaque bloc audio capturé."""
    if status:
        pass # On ignore les avertissements mineurs
    if is_recording:
        audio_queue.put(indata.copy())

def process_audio():
    print("⏳ Traitement de l'audio et traduction FR -> EN...")
    audio_data = []
    while not audio_queue.empty():
        audio_data.append(audio_queue.get())
    
    if not audio_data:
        print("❌ Aucun audio capturé.")
        return

    # Concaténer les blocs numpy en un seul
    audio_np = np.concatenate(audio_data, axis=0)
    audio_np = audio_np.flatten()
    
    try:
        # task="translate" force Whisper à sortir le résultat en anglais
        segments, info = model.transcribe(audio_np, beam_size=5, task="translate")
        
        # Assembler les segments de texte
        text = "".join([segment.text for segment in segments]).strip()
        
        if text:
            print(f"📝 Résultat (EN): {text}")
            # Taper le texte avec le clavier virtuel dans la fenêtre active
            keyboard_controller.type(text + " ")
        else:
            print("❌ Aucune parole claire détectée.")
    except Exception as e:
         print(f"❌ Erreur de transcription: {e}")

def toggle_recording():
    global is_recording
    if not is_recording:
        print("\n🎙️  Enregistrement DÉMARRÉ... (Parlez en français. Appuyez sur Option+Espace pour arrêter)")
        # Vider la file d'attente
        while not audio_queue.empty():
            audio_queue.get()
        is_recording = True
    else:
        print("\n🛑 Enregistrement ARRÊTÉ.")
        is_recording = False
        # Le traitement est asynchrone pour ne pas bloquer l'écoute du clavier
        threading.Thread(target=process_audio).start()

print("Démarrage du flux audio...")
try:
    # Ouvrir le flux micro
    stream = sd.InputStream(samplerate=SAMPLE_RATE, channels=1, dtype='float32', callback=audio_callback)
    stream.start()
    
    print("="*60)
    print("✨ SUPERWHISPER LOCAL EST PRÊT ! ✨")
    print("👉 Raccourci: 'Option + Espace' pour DÉMARRER l'enregistrement.")
    print("👉 Raccourci: 'Option + Espace' à nouveau pour ARRÊTER et écrire (EN).")
    print("\n⚠️  IMPORTANT: Le Terminal doit avoir l'autorisation 'Accessibilité'")
    print("    dans (Réglages Système > Confidentialité et sécurité > Accessibilité)")
    print("="*60)

    # <alt> correspond à la touche Option (⌥) sur macOS
    with keyboard.GlobalHotKeys({'<alt>+<space>': toggle_recording}) as h:
        h.join()
        
except KeyboardInterrupt:
    print("\nFermeture du programme...")
except Exception as e:
    print(f"Erreur fatale: {e}")
finally:
    if 'stream' in locals():
        stream.stop()
        stream.close()