import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MicrophoneSettings {
  final String localeId;
  final bool saveTranscripts;
  final bool privateMode;

  const MicrophoneSettings({
    required this.localeId,
    required this.saveTranscripts,
    required this.privateMode,
  });

  static const defaults = MicrophoneSettings(
    localeId: 'en_US',
    saveTranscripts: true,
    privateMode: true,
  );

  MicrophoneSettings copyWith({
    String? localeId,
    bool? saveTranscripts,
    bool? privateMode,
  }) {
    return MicrophoneSettings(
      localeId: localeId ?? this.localeId,
      saveTranscripts: saveTranscripts ?? this.saveTranscripts,
      privateMode: privateMode ?? this.privateMode,
    );
  }
}

class MicrophoneSettingsService {
  static const _localeKey = 'microphone_locale_id';
  static const _saveTranscriptsKey = 'privacy_save_transcripts';
  static const _privateModeKey = 'privacy_private_mode';

  Future<MicrophoneSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return MicrophoneSettings(
      localeId: prefs.getString(_localeKey) ?? MicrophoneSettings.defaults.localeId,
      saveTranscripts:
          prefs.getBool(_saveTranscriptsKey) ?? MicrophoneSettings.defaults.saveTranscripts,
      privateMode: prefs.getBool(_privateModeKey) ?? MicrophoneSettings.defaults.privateMode,
    );
  }

  Future<void> save(MicrophoneSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, settings.localeId);
    await prefs.setBool(_saveTranscriptsKey, settings.saveTranscripts);
    await prefs.setBool(_privateModeKey, settings.privateMode);
  }

  Future<PermissionStatus> microphoneStatus() => Permission.microphone.status;

  Future<PermissionStatus> requestMicrophone() => Permission.microphone.request();

  Future<bool> openSettings() => openAppSettings();
}
