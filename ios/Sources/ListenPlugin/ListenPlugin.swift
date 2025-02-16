import Foundation
import Capacitor
import Speech
import AVFoundation

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(ListenPlugin)
public class ListenPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ListenPlugin"
    public let jsName = "Listen"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "requestPermission", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "startListening", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopListening", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setLanguage", returnType: CAPPluginReturnPromise)
    ]
    
    private let implementation = Listen()
    private var speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var currentLocale = "en-US"

    @objc func setLanguage(_ call: CAPPluginCall) {
       guard let lang = call.getString("language") else {
           call.reject("Language parameter missing")
           return
       }
       self.currentLocale = lang
       self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: lang))
       call.resolve(["status": "Language set to \(lang)"])
    }

    @objc func requestPermission(_ call: CAPPluginCall) {
       SFSpeechRecognizer.requestAuthorization { status in
           switch status {
           case .authorized:
               call.resolve(["status": "granted"])
           case .denied:
               call.reject("Permission denied")
           case .restricted, .notDetermined:
               call.reject("Permission not granted")
           @unknown default:
               call.reject("Unknown status")
           }
       }
    }

    @objc func startListening(_ call: CAPPluginCall?) {
        if audioEngine.isRunning {
            call?.reject("AudioEngine is already running")
            return
        }

        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: self.currentLocale))

        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)

        node.removeTap(onBus: 0)

        node.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { buffer, _ in
            self.request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            call?.reject("Audio Engine error")
            self.restartListeningAfterDelay()
            return
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request, let recognizer = speechRecognizer else {
            call?.reject("Request creation failed")
            self.restartListeningAfterDelay()
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let result = result {
                if let lastSegment = result.bestTranscription.segments.last {
                    let wordData: [String: Any] = [
                        "word": lastSegment.substring,
                        "timestamp": lastSegment.timestamp,
                        "duration": lastSegment.duration
                    ]

                    self.notifyListeners("onWordReceived", data: wordData)
                }
            }
            if error != nil {
                self.stopAudioEngine()
                self.restartListeningAfterDelay()
            }
        }
        call?.resolve()
    }

    private func restartListeningAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startListening(nil) // 1 saniye bekleyip tekrar başlat
        }
    }

    @objc func stopListening(_ call: CAPPluginCall) {
        stopAudioEngine()
        call.resolve()
    }

    private func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            request = nil
            recognitionTask?.cancel()
            recognitionTask = nil
        }
    }

}
