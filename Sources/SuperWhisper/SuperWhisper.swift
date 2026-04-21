import Foundation
import SwiftWhisper
import AVFoundation
import AppKit
import CoreGraphics

// ==========================================
// MARK: - AUDIO RECORDER
// ==========================================
class AudioRecorder {
    private let engine = AVAudioEngine()
    private var isRecording = false
    private var audioData: [Float] = []
    private var converter: AVAudioConverter?
    
    func startRecording() {
        guard !isRecording else { return }
        
        audioData.removeAll()
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false) else {
            print("❌ Impossible de créer le format audio cible")
            return
        }
        
        converter = AVAudioConverter(from: recordingFormat, to: targetFormat)
        
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] (buffer, time) in
            guard let self = self else { return }
            
            // Convert to 16kHz Mono Float32
            let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                outStatus.pointee = AVAudioConverterInputStatus.haveData
                return buffer
            }
            
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: AVAudioFrameCount(targetFormat.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate)) else { return }
            
            var error: NSError?
            let status = self.converter?.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
            
            if status != .error, let channelData = convertedBuffer.floatChannelData?[0] {
                let frameLength = Int(convertedBuffer.frameLength)
                let data = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
                self.audioData.append(contentsOf: data)
            }
        }
        
        do {
            try engine.start()
            isRecording = true
            print("\n🎙️  Enregistrement DÉMARRÉ... (Parlez en français. Appuyez sur Option+Espace pour arrêter)")
        } catch {
            print("❌ Erreur au démarrage du moteur audio: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() -> [Float] {
        guard isRecording else { return [] }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
        print("\n🛑 Enregistrement ARRÊTÉ.")
        return audioData
    }
}

// ==========================================
// MARK: - WHISPER MANAGER
// ==========================================
class WhisperManager {
    private var whisper: Whisper?
    
    init(modelPath: String) {
        let modelURL = URL(fileURLWithPath: modelPath)
        
        print("\n🚀 Initialisation de SuperWhisper Natif (Swift/C++)...")
        print("📦 Chargement du modèle Whisper...")
        
        self.whisper = Whisper(fromFileURL: modelURL)
        let params = WhisperParams()
        params.translate = true // Task="translate"
        params.language = .french // Input language
        params.print_special = false
        params.print_progress = false
        params.print_realtime = false
        params.print_timestamps = false
        self.whisper?.params = params
        
        print("✅ Modèle chargé avec succès.\n")
    }
    
    func translate(audioFrames: [Float]) async -> String? {
        guard let whisper = whisper else { return nil }
        print("⏳ Traitement de l'audio et traduction FR -> EN...")
        do {
            let segments = try await whisper.transcribe(audioFrames: audioFrames)
            let text = segments.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            return text
        } catch {
            print("❌ Erreur de transcription: \(error)")
            return nil
        }
    }
}

// ==========================================
// MARK: - TEXT INJECTOR
// ==========================================
class TextInjector {
    static func type(text: String) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Split text by lines if needed, or simply inject
        // A robust way to inject text is via Pasteboard, but direct key events mimic typing
        // For simplicity and speed without relying on clipboard history:
        
        // To be fast, we use pasteboard + Cmd+V to avoid delay for long texts
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Simuler Cmd+V
        let vKeyCode: CGKeyCode = 0x09 // 'v'
        
        if let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true) {
            keyDownEvent.flags = .maskCommand
            keyDownEvent.post(tap: .cgSessionEventTap)
        }
        
        if let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) {
            keyUpEvent.flags = .maskCommand
            keyUpEvent.post(tap: .cgSessionEventTap)
        }
        
        // Append space at the end to match Superwhisper UX
        if let spaceDown = CGEvent(keyboardEventSource: source, virtualKey: 49, keyDown: true) {
            spaceDown.post(tap: .cgSessionEventTap)
        }
        if let spaceUp = CGEvent(keyboardEventSource: source, virtualKey: 49, keyDown: false) {
            spaceUp.post(tap: .cgSessionEventTap)
        }
    }
}

// ==========================================
// MARK: - APP STATE
// ==========================================
class AppState {
    var isRecording = false
    let audioRecorder = AudioRecorder()
    let whisperManager: WhisperManager
    
    init(modelPath: String) {
        self.whisperManager = WhisperManager(modelPath: modelPath)
    }
    
    func toggleRecording() {
        if !isRecording {
            isRecording = true
            audioRecorder.startRecording()
        } else {
            let audioData = audioRecorder.stopRecording()
            isRecording = false
            
            if audioData.isEmpty {
                print("❌ Aucun audio capturé.")
                return
            }
            
            Task {
                if let text = await whisperManager.translate(audioFrames: audioData), !text.isEmpty {
                    print("📝 Résultat (EN): \(text)")
                    
                    // DispatchQueue.main.async is not strictly needed for CGEvent, but good practice
                    DispatchQueue.main.async {
                        TextInjector.type(text: text)
                    }
                } else {
                    print("❌ Aucune parole claire détectée.")
                }
            }
        }
    }
}

// ==========================================
// MARK: - MAIN ENTRY
// ==========================================

let args = CommandLine.arguments
guard args.count > 1 else {
    print("❌ Usage: SuperWhisper <chemin_vers_modele_ggml.bin>")
    exit(1)
}

let modelPath = args[1]
if !FileManager.default.fileExists(atPath: modelPath) {
    print("❌ Le fichier modèle est introuvable au chemin: \(modelPath)")
    exit(1)
}

let appState = AppState(modelPath: modelPath)

// Check Accessibility permissions
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
let accessEnabled = AXIsProcessTrustedWithOptions(options)
if !accessEnabled {
    print("\n⚠️  IMPORTANT: Autorisez ce programme (Terminal) dans:")
    print("    Réglages Système > Confidentialité et sécurité > Accessibilité")
    print("    Puis relancez le programme.")
    exit(1)
}

// Global Hotkey (Option + Space)
// Option = 524288 (0x80000) or 524576 (left option). Let's use CGEventFlags.maskAlternate
let eventMask = (1 << CGEventType.keyDown.rawValue)
guard let eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(eventMask),
    callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            
            // Space is 49. Option mask is .maskAlternate
            if keyCode == 49 && flags.contains(.maskAlternate) {
                let state = Unmanaged<AppState>.fromOpaque(refcon!).takeUnretainedValue()
                state.toggleRecording()
                return nil // Swallow event
            }
        }
        return Unmanaged.passRetained(event)
    },
    userInfo: Unmanaged.passUnretained(appState).toOpaque()
) else {
    print("❌ Impossible de créer l'EventTap. Avez-vous donné les droits d'accessibilité ?")
    exit(1)
}

let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)

print(String(repeating: "=", count: 60))
print("✨ SUPERWHISPER NATIF EST PRÊT ! ✨")
print("👉 Raccourci: 'Option + Espace' pour DÉMARRER l'enregistrement.")
print("👉 Raccourci: 'Option + Espace' à nouveau pour ARRÊTER et traduire/écrire.")
print(String(repeating: "=", count: 60))

// Request microphone access
AVCaptureDevice.requestAccess(for: .audio) { granted in
    if !granted {
        print("❌ Accès au microphone refusé. Activez-le dans les réglages système.")
        exit(1)
    }
}

CFRunLoopRun()
