# UC-05 - Profile, Progress, Settings

## 1. Tóm tắt

Profile là nơi người dùng xem hành trình luyện tập, trạng thái cá nhân và quản lý cài đặt. Màn này cần giữ cảm giác riêng tư, khích lệ và có kiểm soát.

## 2. Actor

- Người dùng đã hoặc chưa đăng nhập.
- Người muốn xem tiến độ luyện nói.
- Người muốn chỉnh microphone, language, privacy, notifications, mode.

## 3. Entry point

- Tab `Profile`.
- CTA từ Save Progress hoặc settings icon.

## 4. Preconditions

- Có thể có Firebase user.
- Có thể có local stats.
- Nếu chưa đăng nhập, vẫn hiển thị profile guest/offline.

## 5. Functional requirements

### FR-01: Hiển thị identity

Profile header gồm:

- Avatar.
- Name.
- Encouraging tagline.

### FR-02: Hiển thị stats

Stats gồm:

- Streak.
- Total sessions.
- Speaking minutes.

### FR-03: Hiển thị progress

Progress gồm:

- Gentle progress chart.
- Recent session history.
- Insight tích cực cho mỗi session.

### FR-04: Hiển thị settings

Settings gồm:

- Microphone.
- Language.
- Privacy.
- Notifications.
- Mode selection.
- Optional playful mode.

### FR-05: Hỗ trợ guest/offline

Nếu chưa login:

- Hiển thị user name mặc định.
- CTA `Sign in to sync progress`.
- Không khóa toàn bộ app.

## 6. Main flow

1. User mở Profile.
2. App hiển thị avatar, name, tagline.
3. App hiển thị stats row.
4. App hiển thị progress chart.
5. App hiển thị recent sessions.
6. App hiển thị settings.
7. User mở một setting và chỉnh.

## 7. Alternative flows

### AF-01: Chưa có session

Hiển thị empty state:

- `Your journey starts with one calm session.`
- CTA: `Start Practice`.

### AF-02: Chưa đăng nhập

Hiển thị:

- `Guest`
- `Sign in to sync progress`
- Vẫn cho xem local settings.

### AF-03: Không tải được progress

Hiển thị:

- `Progress could not load right now.`
- `Try again`
- Không ẩn settings.

## 8. UI layout 390x844

```text
SafeArea
  ProfileHeader y 8-180
    Avatar
    Name
    Tagline

  StatsRow y 196-296
    Streak | Sessions | Minutes

  ProgressCard y 312-512
    Gentle progress this week
    Chart

  RecentSessions y 528-680
    Today - Practice - smart pauses
    Yesterday - Interview - steady pace

  Settings y 696+
    Microphone
    Language
    Privacy
    Notifications
    Mode selection

  BottomNav y 768-844
```

Vì nội dung dài, màn Profile nên dùng scroll.

## 9. Profile header spec

Content:

- Avatar 72-88px.
- Name 22-26px, weight 800.
- Tagline 14-15px, secondary.
- Optional privacy badge: `Private by default`.

Example:

```text
Bao
Building confidence one calm session at a time
```

Vietnamese:

```text
Bao
Mỗi phiên luyện tập là một bước nói tự tin hơn
```

## 10. Stats row spec

3 stat cards hoặc one card with 3 columns:

- Streak.
- Sessions.
- Minutes.

UI:

- Card radius: 24px.
- Each stat:
  - Value 20-24px, weight 800.
  - Label 12-14px.
  - Icon nhỏ pastel.

Không dùng:

- Flame đỏ gây áp lực streak.
- Warning mất streak.

## 11. Progress card spec

Content:

- Title: `Gentle progress this week`.
- Subtitle: `Small steps still count.`
- Chart:
  - Line/bar nhẹ.
  - Mint/blue.
  - Không dùng đỏ giảm tiến độ.

Nếu giảm tiến độ:

- Copy: `A lighter week is okay. You can restart anytime.`
- Không dùng negative trend red.

## 12. Recent sessions spec

Mỗi item:

- Date.
- Session type.
- Insight tích cực.
- Optional duration.

Examples:

- `Today - Practice - 4 smart pauses`
- `Yesterday - Interview - steady pace`
- `Apr 12 - Presentation - clear opening`

Không hiển thị:

- Full transcript nhạy cảm.
- Error count.
- Bad score.

## 13. Settings spec

### Microphone

Row:

- Icon mic.
- Title: `Microphone`.
- Subtitle: permission status.
- Chevron.

Detail:

- Explain only listens during session.
- CTA open settings if permission denied.

### Language

Options:

- English.
- Vietnamese.
- Other future languages.

### Privacy

Options:

- Private mode.
- Save transcript toggle.
- Sync progress toggle.

Copy:

- `Your practice space is private by default.`
- `You choose what to save.`

### Notifications

Options:

- Gentle reminders.
- Practice rhythm reminders.

Rules:

- No guilt copy.
- No "You are losing streak" alerts.

### Mode selection

Options:

- Calm mode default.
- Playful mode optional.

## 14. Mapping Flutter

File hiện tại:

- `lib/screens/profile_screen.dart`
- `lib/screens/progress_screen.dart`

Thay đổi:

- Gộp phần progress summary từ `ProgressScreen` vào `ProfileScreen`.
- Thêm settings rows.
- Thêm privacy card.
- Thêm guest/offline state.

Data source:

- `FirestoreService.getUserProfile`.
- `FirestoreService.getUserSessions`.
- Local defaults nếu Firebase không supported.

## 15. Acceptance criteria

- Profile có avatar, name, tagline.
- Có streak, total sessions, speaking minutes.
- Có progress chart hoặc placeholder.
- Có recent sessions với insight tích cực.
- Có settings microphone, language, privacy, notifications, mode selection.
- Guest user vẫn dùng được.
- Không dùng copy tạo áp lực streak.
- Không hiển thị transcript nhạy cảm trong recent history.
