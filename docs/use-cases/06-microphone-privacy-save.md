# UC-06 - Microphone, Privacy, Save Progress

## 1. Tóm tắt

Use case này mô tả các tình huống liên quan đến quyền microphone, quyền riêng tư và lưu tiến độ. Đây là phần quan trọng vì SpeechUp phải tạo cảm giác an toàn và riêng tư.

## 2. Actor

- Người dùng mới chưa cấp quyền microphone.
- Người dùng quan tâm dữ liệu giọng nói/transcript.
- Người dùng muốn lưu hoặc không lưu tiến độ.

## 3. Entry points

- Tap record trong Practice.
- Tap `Answer with voice` trong Challenge.
- Tap `Save Progress` trong Results.
- Mở Privacy trong Profile.
- Mở Microphone settings trong Practice/Profile.

## 4. Functional requirements

### FR-01: Xin quyền microphone nhẹ nhàng

Khi cần microphone:

- Giải thích vì sao cần quyền.
- Nói rõ app chỉ nghe trong phiên luyện tập.
- Cho CTA cấp quyền.
- Không dùng warning đỏ.

### FR-02: Hiển thị privacy rõ ràng

App phải nói rõ:

- Practice mặc định riêng tư.
- User chọn có lưu hay không.
- Transcript không tự động chia sẻ.

### FR-03: Lưu progress có kiểm soát

Khi user tap `Save Progress`:

- Hiển thị saving state.
- Thành công: saved state.
- Thất bại: thông báo amber, cho retry.

### FR-04: Hỗ trợ Firebase unavailable

Nếu Firebase không supported:

- App vẫn hoạt động.
- Save Progress có thể:
  - lưu local nếu có,
  - hoặc báo `Sign in or enable sync to save progress`.

## 5. Microphone permission flow

```text
User taps Record
  -> Check permission
    -> Granted: start recording
    -> Not determined: show permission explanation then request
    -> Denied: show open settings guidance
    -> Permanently denied: show open settings guidance
```

## 6. Permission UI

Card content:

```text
Microphone access is needed
SpeechUp only listens during your practice session.

[Allow microphone]
[Open settings]
```

Vietnamese:

```text
Cần quyền microphone
SpeechUp chỉ lắng nghe trong phiên luyện tập của bạn.

[Cho phép microphone]
[Mở cài đặt]
```

UI:

- Card trắng.
- Icon mic trong circle pastel blue.
- Primary CTA mint.
- Secondary CTA outline.
- Không dùng red warning icon.

## 7. Privacy settings UI

Profile > Privacy:

Sections:

### Practice privacy

- Copy: `Your practice space is private by default.`
- Toggle: `Private mode`.
- Helper: `When on, SpeechUp asks before saving session details.`

### Transcript saving

- Toggle: `Save transcripts`.
- Helper: `Turn this off to save only summary insights.`

### Progress sync

- Toggle: `Sync progress`.
- Helper: `Use your account to keep progress across devices.`

### Data control

- Action: `Delete saved sessions`.
- Action: `Export progress summary` nếu cần sau.

## 8. Save Progress flow

```text
Results screen
  User taps Save Progress
    -> Validate user/session
    -> Saving state
      -> Success: Saved state + update profile stats
      -> Failure: Amber message + retry
```

## 9. Save Progress UI states

### Unsaved

- Button: `Save Progress`.
- Style: tertiary hoặc secondary.

### Saving

- Button disabled.
- Loading indicator nhỏ.
- Label: `Saving...`.

### Saved

- Button label: `Saved`.
- Check icon mint.
- Snackbar: `Saved to your progress`.

### Failed

- Message:
  - `Could not save right now. Try again.`
- CTA:
  - `Try again`.
- Color:
  - soft amber.

## 10. Firestore data behavior

Hiện dự án có:

- `FirestoreService`.
- `PracticeSession`.
- `UserProfile`.

Save nên cập nhật:

- Practice session document.
- `totalSessions`.
- `totalSpeakingMinutes`.
- Streak.

Nhưng UI nên tránh nói:

- "Uploading your voice" nếu chỉ lưu transcript/summary.
- "Analyzing mistakes".

Nếu lưu transcript:

- Nên có setting rõ.
- Recent session không hiển thị full transcript.

## 11. Error copy

Nên dùng:

- `Microphone access is needed to start.`
- `SpeechUp only listens during your practice session.`
- `Could not save right now. Try again.`
- `Your session is still here.`

Tránh:

- `Permission denied!`
- `Error!`
- `Failed to record!`
- `Upload failed!`

## 12. Mapping Flutter

Files:

- `lib/screens/practice_screen.dart`
- `lib/screens/analysis_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/services/firestore_service.dart`
- `lib/models/practice_session.dart`
- `lib/models/user_profile.dart`

Implementation notes:

- Permission UI nên là widget reusable.
- Save state nên nằm trong Results.
- Privacy settings nên nằm trong Profile.
- Firestore save failure không được pop màn hình Results.

## 13. Acceptance criteria

- User hiểu vì sao cần microphone trước hoặc khi request quyền.
- Permission denied không hiển thị đỏ gắt.
- Practice nói rõ tính riêng tư.
- Save Progress có unsaved/saving/saved/failed states.
- Save failed không làm mất kết quả.
- Profile có Privacy settings.
- Transcript không tự động hiển thị trong Recent Sessions.
