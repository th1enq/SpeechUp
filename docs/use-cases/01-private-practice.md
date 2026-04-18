# UC-01 - Private Practice

## 1. Tóm tắt

Người dùng mở app và bắt đầu luyện nói trong một không gian riêng tư. Đây là trải nghiệm chính của SpeechUp.

Màn hình phải tạo cảm giác:

- An toàn.
- Không bị chấm điểm khi đang nói.
- Không bị thúc ép bởi thời gian.
- Có người lắng nghe nhẹ nhàng.

## 2. Actor

- Người bị nói lắp.
- Người thiếu tự tin khi nói.
- Người học ngôn ngữ.
- Người chuẩn bị phỏng vấn/thuyết trình.

## 3. Entry point

- Tab `Practice` trong bottom navigation.
- Đây là tab mặc định khi vào `MainShell`.
- Có thể vào từ CTA trong Results, Learn hoặc Challenge.

## 4. Preconditions

- App đã mở.
- Nếu cần ghi âm thật: app cần quyền microphone.
- Nếu chưa có quyền microphone, hiển thị state xin quyền nhẹ nhàng.

## 5. Functional requirements

### FR-01: Hiển thị không gian luyện tập

App phải hiển thị:

- Header SpeechUp.
- Mic settings ở góc phải.
- Transcript panel lớn.
- Visualizer dịu.
- Record button lớn.
- Helper line.
- Bottom nav 4 tab.

### FR-02: Bắt đầu ghi âm

Khi người dùng tap `Tap to Start`:

- Kiểm tra microphone permission.
- Nếu có quyền, chuyển sang recording state.
- Nếu chưa có quyền, hiển thị permission state.
- Không hiển thị countdown.

### FR-03: Hiển thị transcript realtime

Trong lúc recording:

- Dòng hiện tại rõ nhất.
- Dòng trước mờ hơn.
- Dòng xa hơn mờ hơn nữa.
- Không highlight lỗi khi người dùng ngập ngừng.

### FR-04: Kết thúc ghi âm

Khi người dùng tap `Tap to Finish`:

- Dừng recording.
- Chuyển sang processing state.
- Điều hướng sang Results khi dữ liệu sẵn sàng.

### FR-05: Không tạo áp lực

Màn Practice không được có:

- Countdown.
- Loud alert.
- Flashing warning.
- Timer nổi bật.
- Score khi đang nói.
- Red error trong trạng thái luyện tập bình thường.

## 6. Main flow

1. Người dùng mở app.
2. App hiển thị tab Practice.
3. Transcript panel ở trạng thái idle.
4. Người dùng tap record.
5. App chuyển sang recording state.
6. Người dùng nói.
7. Transcript cập nhật theo thời gian thực.
8. Người dùng tap finish.
9. App hiển thị processing nhẹ.
10. App mở Results.

## 7. Alternative flows

### AF-01: Chưa cấp quyền microphone

1. Người dùng tap record.
2. App phát hiện chưa có quyền microphone.
3. Hiển thị permission card.
4. Người dùng tap `Allow microphone`.
5. Nếu cấp quyền, bắt đầu recording.
6. Nếu từ chối, giữ ở idle và hiển thị hướng dẫn mở settings.

### AF-02: Người dùng im lặng vài giây

1. App nhận âm lượng thấp.
2. Visualizer giảm biên độ.
3. Helper text đổi nhẹ thành `Pauses are welcome here`.
4. Không báo lỗi.

### AF-03: Lỗi speech recognition

1. App không nhận transcript.
2. Vẫn cho recording tiếp tục nếu microphone hoạt động.
3. Hiển thị helper nhẹ:
   - `I am still listening. Keep going when you are ready.`
4. Không dùng warning đỏ.

### AF-04: Người dùng thoát khi đang recording

1. Người dùng bấm back hoặc đổi tab.
2. App hỏi bằng bottom sheet nhẹ:
   - `Finish this practice?`
   - Actions: `Keep practicing`, `Finish now`, `Discard`
3. Không dùng dialog cảnh báo mạnh.

## 8. UI layout 390x844

```text
SafeArea
  Header y 8-56
    Logo + SpeechUp                          Mic settings

  TranscriptPanel y 72-452
    Private practice
    Transcript / placeholder

  Visualizer y 472-526
    Waveform or circular pulse

  RecordArea y 562-704
    Circular button 96x96
    Tap to Start / Tap to Finish
    Helper line

  BottomNav y 768-844
```

Measurements:

- Horizontal padding: 16px.
- Transcript panel width: 358px.
- Transcript panel height: 360-390px.
- Transcript panel radius: 28px.
- Record button: 96x96.
- Gap transcript to visualizer: 16-20px.
- Gap visualizer to button: 28-36px.

## 9. UI states

### State: Idle

Visual:

- Background: `calmBackground`.
- Transcript card: white.
- Placeholder text:
  - English: `Your words will appear here`
  - Vietnamese: `Lời nói của bạn sẽ hiện ở đây`
- Privacy line:
  - `Only you can see this session.`
- Waveform: pastel blue/mint opacity 0.35.
- Record button: mint.
- Icon: mic.
- Label: `Tap to Start`.
- Helper: `Take your time`.

### State: Permission required

Visual:

- Permission card trong hoặc dưới transcript panel.
- Icon mic trong circle pastel blue.
- Title: `Microphone access is needed`.
- Body: `SpeechUp only listens during your practice session.`
- Primary CTA: `Allow microphone`.
- Secondary CTA: `Open settings`.

Tone:

- Không dùng chữ `denied` làm heading.
- Không dùng đỏ.

### State: Recording

Visual:

- Transcript panel có text realtime.
- Current line: charcoal, 24-28px, weight 700.
- Previous line: secondary gray opacity 0.65.
- Older line: secondary gray opacity 0.45.
- Waveform animate.
- Record button: soft coral hoặc amber.
- Icon: stop.
- Label: `Tap to Finish`.
- Helper: `Speak naturally - I am listening`.

### State: Soft silence

Visual:

- Waveform dịu xuống.
- Transcript giữ nguyên.
- Helper: `Pauses are welcome here`.

### State: Processing

Visual:

- Record button disabled.
- Small loading indicator mint.
- Text: `Preparing your reflection...`
- Không dùng `Analyzing errors`.

## 10. Components

### `TranscriptPanel`

Props gợi ý:

```dart
final List<String> previousLines;
final String currentLine;
final bool isRecording;
final bool isEmpty;
```

Behavior:

- Empty: show placeholder.
- Recording: animate text update.
- Scroll không nên tự giật mạnh; nếu có nhiều dòng, chỉ giữ 3-5 dòng gần nhất.

### `GentleWaveform`

Props:

```dart
final bool isRecording;
final double inputLevel;
final bool reducedMotion;
```

Behavior:

- Idle: static hoặc very slow.
- Recording: animate theo input level.
- Reduced motion: static bars.

### `CircularRecordButton`

Props:

```dart
final bool isRecording;
final bool isProcessing;
final VoidCallback onTap;
```

Behavior:

- Disabled khi processing.
- Press feedback nhẹ.
- Semantic label đổi theo state.

## 11. Copy

English:

- `Private practice`
- `Your words will appear here`
- `Only you can see this session.`
- `Tap to Start`
- `Tap to Finish`
- `Take your time`
- `Speak naturally - I am listening`
- `Pauses are welcome here`
- `Preparing your reflection...`

Vietnamese:

- `Không gian luyện tập riêng tư`
- `Lời nói của bạn sẽ hiện ở đây`
- `Chỉ bạn nhìn thấy phiên luyện tập này.`
- `Chạm để bắt đầu`
- `Chạm để kết thúc`
- `Cứ từ từ, không cần vội`
- `Hãy nói tự nhiên - SpeechUp đang lắng nghe`
- `Khoảng dừng cũng là một phần của nhịp nói`
- `Đang chuẩn bị phản hồi nhẹ nhàng...`

## 12. Data and integration

Nguồn dữ liệu:

- Speech-to-text service hoặc mock transcript nếu chưa tích hợp.
- Microphone permission.
- Session metadata:
  - start time.
  - end time.
  - transcript.
  - duration.
  - optional audio path nếu có.

Output sang Results:

```dart
transcript: String
durationSeconds: int
sessionId: String?
```

Không cần lưu tự động nếu user chưa chọn Save Progress, trừ khi app hiện tại đã có cơ chế lưu bắt buộc. Nếu lưu tự động, cần thông báo rõ trong Profile/Privacy.

## 13. Mapping Flutter

File chính:

- `lib/screens/practice_screen.dart`

Thay đổi:

- Đưa Practice thành màn chính thay vì danh sách exercise.
- Header đổi action icon từ notification sang mic settings.
- Thêm `TranscriptPanel`, `GentleWaveform`, `CircularRecordButton`.
- `_RecordingScreen` hiện tại có thể:
  - Hợp nhất vào `PracticeScreen`, hoặc
  - Giữ làm route nhưng đổi UI theo spec này.

Component nên đặt ở:

- `lib/widgets/shared_widgets.dart` nếu dùng chung nhiều màn.
- Hoặc tạo `lib/widgets/practice_widgets.dart` nếu muốn tách rõ.

## 14. Acceptance criteria

- Khi mở app, Practice là màn đầu tiên.
- Có transcript panel lớn chiếm phần lớn upper screen.
- Record button là action nổi bật nhất.
- Recording state đổi sang coral/amber, không dùng đỏ gắt.
- Không có countdown hoặc timer gây áp lực.
- Khi im lặng, app không báo lỗi.
- Khi finish, app chuyển sang Results.
- UI không bị bottom nav che.
- Text không tràn trên 390x844 và 375x812.
