# UC-03 - Challenge

## 1. Tóm tắt

Challenge giúp người dùng luyện nói trong các tình huống đời thật như giao tiếp hằng ngày, phỏng vấn, thuyết trình, gọi đồ ăn và tự giới thiệu.

Màn này nên được phát triển từ `ConversationScreen` hiện có, vì dự án đã có scenario nền.

## 2. Actor

- Người muốn luyện nói theo tình huống cụ thể.
- Người chuẩn bị phỏng vấn/thuyết trình.
- Người học ngôn ngữ muốn thực hành giao tiếp.

## 3. Entry point

- Tab `Challenge`.
- CTA `Continue to Challenge` từ Results.
- CTA từ Learn lesson.

## 4. Preconditions

- Có danh sách challenge.
- Không bắt buộc đăng nhập để xem challenge.
- Cần quyền microphone khi bắt đầu answer bằng voice.

## 5. Functional requirements

### FR-01: Browse challenge categories

Hiển thị filter ngang:

- Daily Communication.
- Interview.
- Presentation.
- Ordering Food.
- Self Introduction.

### FR-02: Hiển thị challenge cards

Mỗi card có:

- Title.
- Description.
- Difficulty.
- Duration.
- Start button.
- Icon/visual.

### FR-03: Xem challenge detail

Detail có:

- Scenario context.
- Prompt hints.
- Large answer/record action.
- Không có timer bắt buộc.

### FR-04: Ghi âm câu trả lời

Khi user tap `Answer with voice`:

- Dùng pattern recording giống Practice.
- Sau khi finish, chuyển Results hoặc hiển thị feedback ngắn.

## 6. Main flow

1. User mở tab Challenge.
2. App hiển thị title, subtitle, category filters.
3. User chọn category.
4. App lọc challenge cards.
5. User tap Start.
6. App mở Challenge Detail.
7. User đọc scenario context và prompt hints.
8. User tap Answer with voice.
9. App ghi âm câu trả lời.
10. User finish.
11. App mở Results.

## 7. Alternative flows

### AF-01: Category không có challenge

Hiển thị empty state:

- `No challenges here yet`
- `Try another category or start a free practice session.`
- CTA: `Go to Practice`.

### AF-02: User chưa muốn ghi âm

Trong detail, cho phép:

- Back về danh sách.
- Lưu challenge vào later nếu muốn triển khai sau.

### AF-03: User dừng giữa chừng

Nếu đang recording:

- Hiển thị bottom sheet:
  - `Finish this answer?`
  - `Keep answering`
  - `Finish now`
  - `Discard`

## 8. Challenge list UI layout 390x844

```text
SafeArea
  Header y 8-112
    Challenge
    Practice real moments at your own pace.

  CategoryFilter y 128-172
    Daily Communication | Interview | Presentation | Ordering Food | Self Introduction

  ChallengeList y 188-760
    ChallengeCard h 156-180
    ChallengeCard h 156-180
    ChallengeCard h 156-180

  BottomNav y 768-844
```

## 9. Challenge detail UI layout

```text
Header
  [Back]                  Interview

ScenarioContextCard
  You are answering: "Tell me about yourself."

PromptHints
  Start with your name
  Mention one strength
  Pause before your final sentence

AnswerAction
  [Large record button or pill]
  Answer with voice
  No rush. You can try again.
```

## 10. Challenge categories

### Daily Communication

Use cases:

- Gọi điện.
- Hỏi đường.
- Chào hỏi.
- Nói chuyện với đồng nghiệp.

Tone:

- Nhẹ nhàng, đời thường.

### Interview

Use cases:

- Tell me about yourself.
- Strengths and weaknesses.
- Why this role.
- Describe a project.

Tone:

- Tự tin, rõ ràng, không tạo áp lực thi cử.

### Presentation

Use cases:

- Mở đầu bài thuyết trình.
- Giải thích một ý tưởng.
- Kết luận ngắn.

Tone:

- Có cấu trúc, khuyến khích pause.

### Ordering Food

Use cases:

- Gọi đồ uống.
- Hỏi menu.
- Yêu cầu thay đổi món.

Tone:

- Thân thiện, ngắn.

### Self Introduction

Use cases:

- Giới thiệu bản thân 30 giây.
- Giới thiệu mục tiêu học.
- Giới thiệu kinh nghiệm.

Tone:

- Cá nhân, an toàn.

## 11. Challenge card spec

Content:

- Icon circle 48x48.
- Title: 17-18px, weight 800.
- Description: 13-15px, secondary.
- Difficulty chip: Easy, Medium, Growing.
- Duration: `2-3 min`, `5 min`.
- Start button: `Start`.

UI:

- Card radius: 24px.
- Background: white hoặc soft blue/mint surface.
- Padding: 18-20px.
- Shadow mềm.
- Watermark icon có thể dùng opacity 0.05 như Practice card hiện tại.

Example:

```text
Ordering a coffee
Practice asking for a drink and one small change.
Easy · 2-3 min                    Start
```

## 12. Challenge detail spec

### Scenario context card

Content:

- Category chip.
- Scenario title.
- Situation paragraph.

Example:

```text
Interview
Tell me about yourself
You are in the first minute of an interview. Give a short, calm introduction.
```

### Prompt hints

UI:

- 2-3 hint rows.
- Icon check/leaf/dot nhẹ.
- Không bắt user phải làm đủ.

Example:

- `Start with your name`
- `Mention one strength`
- `Pause before your final sentence`

### Answer action

UI:

- Nút lớn hoặc record circle.
- Label: `Answer with voice`.
- Helper: `No rush. You can try again.`

## 13. Data model

```dart
class ChallengeItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final String durationLabel;
  final IconData icon;
  final Color accentColor;
  final List<String> promptHints;
  final String scenarioContext;
}
```

Seed data từ scenario hiện có:

| Existing scenario | New category |
|---|---|
| Gọi đồ uống tại quán cà phê | Ordering Food |
| Phỏng vấn xin việc | Interview |
| Gọi điện cho khách hàng | Daily Communication |
| Thuyết trình trước nhóm | Presentation |

## 14. Mapping Flutter

File hiện tại:

- `lib/screens/conversation_screen.dart`

Thay đổi:

- Có thể đổi tên class thành `ChallengeScreen` sau.
- Thêm category filters.
- Refactor `_Scenario` thành model nhiều field hơn.
- `_ScenarioCard` đổi thành `_ChallengeCard`.
- `_ConversationChat` có thể giữ làm challenge detail/chat mode, nhưng entry list phải giống Challenge.

Localization:

- Thêm keys:
  - `nav.challenge`
  - `challenge.title`
  - `challenge.subtitle`
  - `challenge.answerWithVoice`

## 15. Acceptance criteria

- Challenge tab có category filter ngang.
- Challenge card có đủ title, description, difficulty, duration, start.
- Existing scenarios được tái sử dụng.
- Challenge detail có context, prompt hints và answer action.
- Không có timer bắt buộc.
- Recording trong Challenge giữ tinh thần calm như Practice.
- Finish challenge mở Results hoặc feedback phù hợp.
