# UC-00 - Foundation, Navigation, Design System

## 1. Mục tiêu

Chuẩn hóa nền tảng giao diện cho toàn bộ SpeechUp theo hướng calm, private, safe, encouraging, đồng thời giữ lại đặc điểm hiện tại của app Flutter.

Use case này không phải một màn hình riêng, mà là nền tảng bắt buộc trước khi triển khai các use case còn lại.

## 2. Hiện trạng cần giữ

Các đặc điểm đang có trong dự án:

- App Flutter đã có `MainShell` dùng `IndexedStack`.
- Header SpeechUp xuất hiện ở nhiều màn hình.
- Card bo lớn 22-28px, bóng mềm.
- Palette xanh/navy/pastel đang tạo cảm giác thân thiện.
- Font hiện tại dùng `Plus Jakarta Sans`.
- Bottom navigation hiện có bo góc trên và shadow nhẹ.

Không nên phá bỏ ngay các thành phần này. Thiết kế mới phải mở rộng dần.

## 3. Navigation mục tiêu

Bottom navigation mới gồm 4 tab:

| Tab | Vai trò | Icon gợi ý | Màn Flutter |
|---|---|---|---|
| Practice | Home và trải nghiệm chính | `mic_rounded`, `graphic_eq_rounded` | `PracticeScreen` |
| Challenge | Luyện tình huống | `flag_rounded`, `chat_bubble_rounded` | `ChallengeScreen` hoặc `ConversationScreen` refactor |
| Learn | Thư viện bài học | `menu_book_rounded` | `LearnScreen` mới |
| Profile | Hồ sơ, tiến độ, cài đặt | `person_rounded` | `ProfileScreen` |

Yêu cầu:

- Practice là tab mặc định.
- Không hiển thị Home, Chat, Progress như tab chính trong phiên bản mới.
- `HomeScreen` có thể giữ trong code hoặc tách thành Today Summary.
- `ProgressScreen` nên gộp dần vào Profile.

## 4. Layout chuẩn

Frame tham chiếu: 390x844.

Quy tắc:

- SafeArea đầy đủ.
- Padding ngang: 16px cho màn mới.
- Gap nhỏ: 8px.
- Gap chuẩn: 16px.
- Gap section: 24px.
- Bottom nav: 72-80px.
- Scroll content padding bottom: tối thiểu 104px nếu có bottom nav.

Không dùng:

- Nội dung sát mép.
- Card lồng card không cần thiết.
- Text nhỏ dưới 13px cho nội dung quan trọng.
- Animation mạnh hoặc layout shift.

## 5. Design tokens

### Màu chính

| Token | Hex | Dùng cho |
|---|---:|---|
| `calmMint` | `#7FD8C3` | CTA chính, record idle, success, waveform |
| `calmBlue` | `#A9D6F5` | Secondary accent, chip, graph |
| `calmBackground` | `#F8F7F3` | Nền app |
| `surface` | `#FFFFFF` | Card, bottom nav, sheet |
| `calmText` | `#2F3640` | Heading, body chính |
| `calmTextSecondary` | `#6B7280` | Subtitle, helper |
| `calmAmber` | `#F4B96A` | Gợi ý nhẹ, save failed, attention |
| `calmCoral` | `#F28B82` | Recording/stop state |
| `calmMintSurface` | `#EAF8F4` | Selected chip, soft card |
| `calmBlueSurface` | `#EEF7FE` | Chart/card nền xanh |

### Token Flutter đề xuất

Thêm vào `lib/theme/app_colors.dart`, không xóa token cũ ngay:

```dart
static const Color calmMint = Color(0xFF7FD8C3);
static const Color calmBlue = Color(0xFFA9D6F5);
static const Color calmBackground = Color(0xFFF8F7F3);
static const Color calmText = Color(0xFF2F3640);
static const Color calmTextSecondary = Color(0xFF6B7280);
static const Color calmAmber = Color(0xFFF4B96A);
static const Color calmCoral = Color(0xFFF28B82);
static const Color calmMintSurface = Color(0xFFEAF8F4);
static const Color calmBlueSurface = Color(0xFFEEF7FE);
```

## 6. Typography

Ưu tiên:

- Be Vietnam Pro cho tiếng Việt.
- Inter cho UI quốc tế.
- Có thể giữ `Plus Jakarta Sans` giai đoạn đầu để giảm thay đổi.

Scale:

| Loại | Size | Weight | Line height |
|---|---:|---:|---:|
| Screen title | 26-30 | 800 | 1.15 |
| Section title | 18-22 | 700-800 | 1.25 |
| Body | 15-17 | 500 | 1.45 |
| Helper | 13-15 | 500 | 1.4 |
| Transcript current | 24-28 | 700 | 1.45 |
| Transcript previous | 20-22 | 500-600 | 1.45 |
| Bottom nav label | 11-12 | 600-700 | 1.2 |

## 7. Component chung

### `SpeechUpHeader`

Chức năng:

- Hiển thị logo/icon, chữ SpeechUp hoặc title màn hình.
- Có action bên phải tùy màn: mic settings, close, privacy, settings.

UI:

- Height: 48px.
- Icon circle: 44x44.
- Title: 18-20px, weight 800.
- Action button: 40-44px.

### `CalmCard`

Chức năng:

- Card nền cho panel, challenge, lesson, stats, settings.

UI:

- Background: white hoặc pastel surface.
- Radius: 24px, panel lớn 28px.
- Padding: 16-24px.
- Shadow: blur 18-24, offset 0/8, alpha 0.06-0.10.

### `SoftChip`

Chức năng:

- Category, difficulty, status.

UI:

- Height: 36-40px.
- Padding ngang: 14-16px.
- Radius: 18-20px.
- Selected: mint surface, text charcoal.
- Unselected: white, border xanh/xám rất nhạt.

### `PrimaryCalmButton`

UI:

- Height: 48-56px.
- Background: `calmMint`.
- Text: charcoal hoặc white tùy contrast thực tế.
- Radius: 16px.
- Press: scale 0.98, opacity 0.94.

### `SecondaryCalmButton`

UI:

- Height: 48-56px.
- Background: white hoặc transparent.
- Border: pastel blue/mint.
- Text: charcoal.
- Radius: 16px.

## 8. Motion rules

Được phép:

- Fade 150-250ms.
- Slide nhẹ 8-16px.
- Card lift 1-2px.
- Gauge/graph animate 900-1200ms.
- Waveform/pulse dịu 600-1200ms.

Không dùng:

- Nhấp nháy.
- Shake.
- Bounce mạnh.
- Confetti mặc định.
- Timer animation gây áp lực.

Reduced motion:

- Tắt pulse liên tục.
- Chart/gauge chỉ fade in.
- Tab transition chỉ crossfade rất nhẹ.

## 9. Accessibility

- Touch target tối thiểu 44x44.
- Body text tương phản tối thiểu 4.5:1.
- Transcript current không nhỏ hơn 22px.
- Icon-only button phải có semantic label.
- Record button:
  - Idle semantic: `Start recording`.
  - Recording semantic: `Finish recording`.
- Waveform decorative cần exclude semantics.
- Không truyền thông tin chỉ bằng màu.

## 10. Acceptance criteria

- Bottom nav mới có 4 tab.
- Practice là tab mặc định.
- Toàn app dùng được token calm mới mà không phá token cũ.
- Header/card/button/chip có style nhất quán.
- Không có UI luyện nói bình thường dùng đỏ gắt.
- Layout ổn trên 390x844, 375x812, 430x932.
