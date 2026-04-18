# UC-07 - Optional Playful Mode

## 1. Tóm tắt

Playful Mode là chế độ tùy chọn giúp app có thêm yếu tố vui nhẹ như badge, journey metaphor, companion và growth visuals. Chế độ này không được bật mặc định và không được gây overstimulation.

## 2. Actor

- Người dùng muốn trải nghiệm vui hơn.
- Người dùng thích badge/hành trình phát triển.
- Người dùng vẫn cần cảm giác an toàn, không bị so sánh.

## 3. Entry point

- Profile > Mode selection.
- Profile > Optional playful mode toggle.

## 4. Preconditions

- User đang ở Profile.
- Calm mode là mặc định.

## 5. Functional requirements

### FR-01: Playful mode là optional

- Không bật mặc định.
- User chủ động bật/tắt trong Profile.

### FR-02: Có badges nhẹ

Badges gợi ý:

- `First calm start`.
- `3-day practice rhythm`.
- `Interview ready`.
- `Gentle pacing`.
- `Kept going`.

### FR-03: Có journey metaphor

Metaphor được phép:

- Cây/lá phát triển.
- Con đường nhẹ.
- Sóng đều.
- Vườn nhỏ.

Không dùng:

- Bảng xếp hạng cạnh tranh.
- Streak pressure.
- Thắng/thua.
- Punishment khi bỏ lỡ ngày.

### FR-04: Có soft AI companion

Companion:

- Avatar mềm.
- Nói ít.
- Không phán xét.
- Không chiếm màn hình Practice chính.

## 6. Main flow

1. User mở Profile.
2. User mở Mode selection.
3. User chọn Playful Mode.
4. App preview nhẹ thay đổi.
5. User confirm.
6. App áp dụng badges/growth visuals ở Profile, Results hoặc Learn.

## 7. Alternative flows

### AF-01: User tắt Playful Mode

1. User vào Profile > Mode selection.
2. Chọn Calm Mode.
3. App ẩn badge nổi bật và companion.
4. Dữ liệu tiến độ vẫn giữ nguyên.

### AF-02: Reduced motion bật

- Playful visuals không animate liên tục.
- Badge chỉ fade in.
- Không confetti.

## 8. UI placement

Không nên đưa playful mode quá nhiều vào Practice. Practice vẫn phải là không gian yên tĩnh.

Vị trí phù hợp:

- Profile:
  - Badge shelf.
  - Journey progress card.
- Results:
  - Small badge earned nếu thật sự nhẹ.
- Learn:
  - Growth visual trong lesson completion.

Vị trí không phù hợp:

- Transcript panel.
- Record button.
- During recording.

## 9. Mode selection UI

Profile row:

```text
Mode selection
Calm mode
```

Detail sheet:

```text
Choose your experience

Calm mode
A quiet, focused practice space.

Playful mode
Gentle badges and growth visuals.

[Apply]
```

## 10. Badge spec

Badge UI:

- Size: 72-96px.
- Shape: rounded square/circle.
- Colors: mint, pastel blue, soft amber.
- No neon.
- No red alert.

Badge content:

- Icon.
- Name.
- Short supportive description.

Example:

```text
First calm start
You began a private practice session.
```

## 11. Journey card spec

Profile card:

- Title: `Your speaking garden`.
- Subtitle: `Small sessions help it grow.`
- Visual:
  - Leaves/plants/smooth path.
- Progress:
  - Sessions this week.
  - Badges earned.

Rules:

- Nếu user không luyện vài ngày:
  - Không làm cây héo.
  - Không cảnh báo mất streak.
  - Copy: `You can restart anytime.`

## 12. Companion spec

Companion role:

- Xuất hiện trong Profile hoặc Results.
- Gợi ý ngắn.
- Không chen vào khi user đang nói.

Copy examples:

- `You made space for your words today.`
- `One calm session is enough for today.`
- `Try a slower breath next time.`

Không dùng:

- `You failed`.
- `You lost your streak`.
- `You must practice now`.

## 13. Data model

```dart
class UserModeSettings {
  final bool playfulModeEnabled;
  final bool reducedMotion;
}

class BadgeItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final DateTime? earnedAt;
}
```

## 14. Mapping Flutter

Files:

- `lib/screens/profile_screen.dart`
- Optional new widgets:
  - `PlayfulModeSheet`
  - `BadgeShelf`
  - `JourneyCard`
  - `SoftCompanionCard`

Storage:

- User profile setting if logged in.
- Local setting if not logged in.

## 15. Acceptance criteria

- Playful mode không bật mặc định.
- Có thể bật/tắt từ Profile.
- Practice không bị overstimulating.
- Không có confetti/loud reward mặc định.
- Badge copy khích lệ, không cạnh tranh.
- Không có punishment visual khi user bỏ lỡ ngày.
- Reduced motion được tôn trọng.
