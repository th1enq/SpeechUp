import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();

  StreamSubscription<Amplitude>? _amplitudeSubscription;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<String> start({
    void Function(double level)? onAmplitude,
  }) async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw StateError('Microphone permission was not granted.');
    }

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/speechup_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((amplitude) {
      onAmplitude?.call(amplitude.current);
    });

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    return path;
  }

  Future<File?> stop() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    final path = await _recorder.stop();
    if (path == null || path.trim().isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  Future<void> cancel() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    if (await _recorder.isRecording()) {
      await _recorder.cancel();
    }
  }

  Future<bool> isRecording() => _recorder.isRecording();

  void dispose() {
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
  }
}
