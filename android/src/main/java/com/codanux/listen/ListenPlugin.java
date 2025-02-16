package com.example.plugins;

import android.content.Intent;
import android.speech.RecognitionListener;
import android.speech.RecognizerIntent;
import android.speech.SpeechRecognizer;
import android.util.Log;

import androidx.annotation.Nullable;

import com.getcapacitor.CapacitorPlugin;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.annotation.Permission;
import com.getcapacitor.annotation.PermissionCallback;
import com.getcapacitor.annotation.PluginMethod;

import java.util.ArrayList;
import java.util.Locale;

@CapacitorPlugin(
        name = "Listen",
        permissions = {
                @Permission(strings = {"android.permission.RECORD_AUDIO"}, alias = "audio")
        }
)
public class ListenPlugin extends Plugin {
    private SpeechRecognizer speechRecognizer;
    private Intent recognizerIntent;
    private String currentLanguage = "en-US";

    @Override
    public void load() {
        super.load();
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(getContext());
        setupRecognitionListener();
        setupIntent();
    }

    private void setupIntent() {
        recognizerIntent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
        recognizerIntent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
        recognizerIntent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, currentLanguage);
        recognizerIntent.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true); // Kelime bazlı almak için
    }

    private void setupRecognitionListener() {
        speechRecognizer.setRecognitionListener(new RecognitionListener() {
            @Override
            public void onReadyForSpeech(@Nullable Bundle params) {
                Log.d("ListenPlugin", "Listening...");
            }

            @Override
            public void onResults(Bundle results) {
                ArrayList<String> matches = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
                if (matches != null && !matches.isEmpty()) {
                    sendWord(matches.get(0)); // Sonuçları gönder
                }
                restartListening(); // Dinlemeye devam et
            }

            @Override
            public void onPartialResults(Bundle partialResults) {
                ArrayList<String> matches = partialResults.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
                if (matches != null && !matches.isEmpty()) {
                    sendWord(matches.get(0)); // Parça parça kelime gönder
                }
            }

            @Override
            public void onError(int error) {
                Log.e("ListenPlugin", "Error: " + error);
                restartListening(); // Hata olursa tekrar başlat
            }

            // Kullanılmayan metodlar boş bırakıldı
            @Override public void onBeginningOfSpeech() {}
            @Override public void onEndOfSpeech() {}
            @Override public void onBufferReceived(byte[] buffer) {}
            @Override public void onRmsChanged(float rmsdB) {}
            @Override public void onEvent(int eventType, Bundle params) {}
        });
    }

    @PluginMethod
    public void requestPermission(PluginCall call) {
        if (getPermissionState("audio") == PermissionState.GRANTED) {
            call.resolve(new JSObject().put("status", "granted"));
        } else {
            requestPermissionForAlias("audio", call, "permissionCallback");
        }
    }

    @PermissionCallback
    private void permissionCallback(PluginCall call) {
        if (getPermissionState("audio") == PermissionState.GRANTED) {
            call.resolve(new JSObject().put("status", "granted"));
        } else {
            call.reject("Permission denied");
        }
    }

    @PluginMethod
    public void startListening(PluginCall call) {
        speechRecognizer.startListening(recognizerIntent);
        call.resolve();
    }

    @PluginMethod
    public void stopListening(PluginCall call) {
        speechRecognizer.stopListening();
        call.resolve();
    }

    @PluginMethod
    public void setLanguage(PluginCall call) {
        String lang = call.getString("language");
        if (lang == null || lang.isEmpty()) {
            call.reject("Language parameter missing");
            return;
        }
        currentLanguage = lang;
        setupIntent(); // Yeni dili ayarla
        call.resolve(new JSObject().put("status", "Language set to " + lang));
    }

    private void sendWord(String word) {
        JSObject data = new JSObject();
        data.put("word", word);
        notifyListeners("onWordReceived", data);
    }

    private void restartListening() {
        speechRecognizer.cancel();
        speechRecognizer.startListening(recognizerIntent);
    }
}
