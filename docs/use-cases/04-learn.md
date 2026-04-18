# UC-04 - Learn

## 1. Tóm tắt

Learn là thư viện nội dung nhẹ nhàng giúp người dùng chuẩn bị tinh thần và kỹ thuật trước hoặc sau khi luyện nói. Màn này không phải lớp học áp lực, không phải bài kiểm tra.

## 2. Actor

- Người muốn học kỹ thuật thở, pacing, confidence.
- Người cần chuẩn bị trước phỏng vấn/thuyết trình.
- Người muốn giảm hesitation một cách nhẹ nhàng.

## 3. Entry point

- Tab `Learn`.
- CTA từ Results coach card.
- CTA từ Challenge detail.

## 4. Preconditions

- Có danh sách lesson tĩnh hoặc từ backend.
- Không cần microphone để đọc lesson.

## 5. Functional requirements

### FR-01: Browse categories

Hiển thị categories:

- Breathing.
- Pacing.
- Confidence.
- Reducing Hesitation.

### FR-02: Hiển thị lesson cards

Mỗi lesson card có:

- Thumbnail/visual.
- Title.
- Short description.
- Duration.
- CTA.

### FR-03: Xem lesson detail

Lesson detail có:

- Header.
- Nội dung ngắn.
- Steps hoặc tips.
- CTA cuối bài để Practice hoặc Challenge.

### FR-04: Không tạo cảm giác thi

Learn không có:

- Quiz bắt buộc.
- Score.
- Fail/pass.
- Countdown.

## 6. Main flow

1. User mở Learn tab.
2. App hiển thị categories và featured lesson.
3. User chọn category hoặc lesson.
4. App mở lesson detail.
5. User đọc bài.
6. User tap CTA:
   - `Try this in Practice`
   - hoặc `Use in a Challenge`.

## 7. Alternative flows

### AF-01: Không có lesson

Hiển thị:

- `Lessons could not load right now.`
- CTA: `Try again`.

### AF-02: User hoàn thành lesson

Hiển thị:

- Chip `Read`.
- CTA gợi ý về Practice.

## 8. Learn list UI layout 390x844

```text
SafeArea
  Header y 8-112
    Learn calmly
    Small lessons for easier speaking.

  CategoryChips y 128-172
    Breathing | Pacing | Confidence | Reducing Hesitation

  FeaturedLesson y 188-364
    One breath before the first word

  LessonList y 380-760
    LessonCard h 128-150
    LessonCard h 128-150
    LessonCard h 128-150

  BottomNav y 768-844
```

## 9. Lesson detail UI layout

```text
Header
  [Back]                  Breathing

HeroLessonBlock
  One breath before the first word
  2 min read

Content
  Why it helps
  3 gentle steps
  Practice phrase

Bottom CTA
  Try this in Practice
```

## 10. Lesson categories

### Breathing

Goal:

- Giúp user ổn định trước khi nói.

Lesson examples:

- `One breath before the first word`.
- `A slower exhale for longer sentences`.
- `Reset after a stuck moment`.

### Pacing

Goal:

- Giúp user nói với nhịp dễ theo dõi.

Lesson examples:

- `How to use pauses with confidence`.
- `Gentle pacing for interviews`.
- `Three short phrases instead of one long sentence`.

### Confidence

Goal:

- Giảm self-judgment.

Lesson examples:

- `Your pace is welcome here`.
- `Start with one sentence`.
- `Keeping going after a pause`.

### Reducing Hesitation

Goal:

- Gợi ý xử lý hesitation mà không coi là lỗi.

Lesson examples:

- `Speaking when you feel stuck`.
- `Turning repetition into emphasis`.
- `Use a bridge phrase calmly`.

## 11. Lesson card spec

Content:

- Thumbnail 72x72 hoặc full-width small banner.
- Category chip.
- Title.
- Description.
- Duration.
- CTA.

UI:

- Card radius: 24px.
- Background: white.
- Thumbnail: pastel illustration, không dùng ảnh gây áp lực.
- CTA: text button hoặc small pill.

Example:

```text
Breathing
One breath before the first word
A tiny reset before you begin speaking.
2 min read                         Read
```

## 12. Lesson detail content spec

Cấu trúc bài:

1. Intro 1-2 câu.
2. Why it helps.
3. 3 gentle steps.
4. Practice phrase.
5. CTA.

Example:

```text
One breath before the first word

Before speaking, take one quiet breath. You do not need to make it perfect. The goal is to give your first word a little more space.

Try this:
1. Relax your shoulders.
2. Breathe in gently.
3. Say the first word after the exhale begins.

Practice phrase:
"I would like to start with..."
```

## 13. Data model

```dart
class LessonItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String durationLabel;
  final IconData icon;
  final Color backgroundColor;
  final String ctaLabel;
  final List<String> sections;
}
```

## 14. Mapping Flutter

File mới:

- `lib/screens/learn_screen.dart`

Widgets:

- `_LearnHeader`
- `_LearnCategoryChips`
- `_FeaturedLessonCard`
- `_LessonCard`
- `_LessonDetailScreen`

MainShell:

- Thêm `LearnScreen` vào tab thứ 3.

Localization:

- `nav.learn`
- `learn.title`
- `learn.subtitle`
- `learn.category.breathing`
- `learn.category.pacing`
- `learn.category.confidence`
- `learn.category.reducingHesitation`

## 15. Acceptance criteria

- Learn tab xuất hiện trong bottom nav.
- Có đủ 4 categories.
- Có featured lesson và lesson cards.
- Lesson detail có nội dung đọc ngắn, steps và CTA.
- Không có quiz/score/fail state.
- CTA cuối lesson đưa được về Practice hoặc Challenge.
- UI không bị clinical hoặc giống bài kiểm tra.
