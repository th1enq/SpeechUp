# UC-02 - Results and Supportive Feedback

## 1. Tóm tắt

Sau khi người dùng kết thúc Practice hoặc Challenge, app hiển thị Results với phản hồi tích cực, riêng tư và có hướng dẫn nhẹ nhàng. Màn này thay thế cảm giác "phân tích lỗi" bằng "reflection/support".

## 2. Actor

- Người vừa hoàn thành một phiên luyện nói.

## 3. Entry point

- Từ Practice sau `Tap to Finish`.
- Từ Challenge detail sau khi trả lời bằng giọng nói.
- Từ Recent Session nếu user mở lại kết quả đã lưu.

## 4. Preconditions

- Có transcript hoặc session summary.
- Có duration.
- Có thể có metric thô: words per minute, pauses, repetitions, filler words.

## 5. Functional requirements

### FR-01: Hiển thị kết quả không phán xét

Results phải hiển thị metric theo cách tích cực:

- Speech rate -> pace insight.
- Pauses -> smart/natural pauses.
- Repetition -> repetition for emphasis.
- Filler/hesitation -> reducing hesitation suggestion, không gọi là lỗi.

### FR-02: Hiển thị 4 khối chính

Màn Results gồm:

1. Speech-rate gauge.
2. Fluency graph.
3. Quick stats.
4. AI coach feedback.

### FR-03: Có 3 action cuối màn

- `Practice Again`.
- `Continue to Challenge`.
- `Save Progress`.

### FR-04: Có trạng thái lưu

- Unsaved.
- Saving.
- Saved.
- Save failed.

## 6. Main flow

1. User kết thúc recording.
2. App hiển thị loading nhẹ: `Preparing your reflection...`.
3. Results mở.
4. Gauge animate vào vị trí.
5. Graph vẽ line nhẹ.
6. Quick stats fade in.
7. Coach card xuất hiện.
8. User chọn Practice Again, Continue to Challenge hoặc Save Progress.

## 7. Alternative flows

### AF-01: Transcript trống

Hiển thị:

- Title: `A quiet practice is still practice`.
- Body: `No words were captured this time. You can try again whenever you are ready.`
- Primary action: `Practice Again`.

Không hiển thị gauge/graph giả gây hiểu nhầm.

### AF-02: Không tính được metric

Hiển thị coach card và transcript summary nếu có.

Text:

- `We could not prepare all insights this time. Your session is still here.`

### AF-03: Lưu thất bại

Hiển thị snackbar/card nhỏ màu amber:

- `Could not save right now.`
- CTA: `Try again`.

Không mất kết quả đang xem.

## 8. UI layout 390x844

```text
Header y 8-56
  [Back]                  Results

ScrollView y 72-760
  SpeechRateGaugeCard h 220
  gap 16
  FluencyGraphCard h 190
  gap 16
  QuickStatsCard h 132
  gap 16
  CoachFeedbackCard h 160-190
  gap 20
  Actions
```

Nếu action sticky:

- Bottom action area cao 132-156px.
- ScrollView padding bottom tương ứng.
- `Save Progress` có thể là tertiary dưới hai button chính.

Nếu action trong scroll:

- Đơn giản hơn giai đoạn đầu.
- Đảm bảo padding bottom 112px để không bị nav/gesture che.

## 9. Header

UI:

- Background: calm background.
- Leading: back arrow 44x44.
- Title: `Results`, căn giữa.
- Có thể có action nhỏ bên phải để cân bằng layout nhưng không bắt buộc.

Không dùng:

- Close icon nếu flow là quay lại màn trước.
- Title `Analysis` hoặc `Kết quả phân tích` nếu muốn giảm cảm giác lâm sàng.

## 10. Speech-rate gauge card

Nội dung:

- Semi-circular gauge.
- Calm color bands:
  - Slow: pastel blue.
  - Steady: mint.
  - Fast: soft amber.
- Turtle icon ở đầu slow.
- Rabbit icon ở đầu fast.
- Current value: `118 words/min` hoặc `118 từ/phút`.
- Insight:
  - `Steady pace`
  - `A little fast, still clear`
  - `A gentle pace today`

UI:

- Card radius: 28px.
- Padding: 20-24px.
- Gauge height: 120-140px.
- Insight text: 20-22px, weight 800.
- Value text: 14-15px, secondary.

Rules:

- Không dùng score lớn kiểu 82/100 ở đầu màn.
- Không dùng red band.
- Không ghi "too fast" như lỗi.

## 11. Fluency graph card

Nội dung:

- Smooth line chart.
- Pause markers là dot nhỏ pastel amber/blue.
- Label:
  - `Natural pauses`
  - `Clear flow`
  - `Breathing space`

UI:

- Card radius: 24px.
- Graph area: 100-120px.
- Đường line: mint hoặc pastel blue.
- Marker: amber opacity 0.75.
- Axis tối giản hoặc không hiển thị axis nếu gây cảm giác kỹ thuật.

Rules:

- Không dùng graph quá dày.
- Không dùng spike đỏ.
- Không dùng label tiêu cực.

## 12. Quick stats card

Stats đề xuất:

| Label | Ví dụ | Ý nghĩa |
|---|---|---|
| Smart pauses | `6` | Khoảng dừng có ích |
| Clear moments | `8` | Đoạn rõ ràng |
| Speaking time | `1m 12s` | Thời lượng |
| Repetition for emphasis | `2` | Lặp lại để nhấn mạnh |

UI:

- 2x2 grid.
- Mỗi stat có icon nhẹ, value, label.
- Không dùng màu đỏ hoặc warning icon.

## 13. AI coach feedback card

Nội dung:

- Avatar/illustration mềm.
- Title: `Coach note`.
- Message cụ thể, ngắn, tích cực.
- Optional CTA: `Try one gentle pacing exercise`.

Ví dụ English:

```text
You kept going through pauses, which is a strong habit. Next time, try one slower breath before the second sentence.
```

Ví dụ Vietnamese:

```text
Bạn đã tiếp tục nói qua các khoảng dừng. Đây là một thói quen rất tốt. Lần tới, hãy thử hít chậm một nhịp trước câu thứ hai.
```

Rules:

- Không dùng "AI detected your mistakes".
- Không dùng quá nhiều lời khuyên một lúc.
- Tối đa 2 gợi ý cải thiện trong một card.

## 14. Actions

### `Practice Again`

- Primary mint.
- Quay lại Practice idle.
- Nếu có challenge context, có thể quay lại same challenge answer screen.

### `Continue to Challenge`

- Secondary pastel blue/outlined.
- Điều hướng sang Challenge tab.

### `Save Progress`

- Tertiary/text button hoặc small filled button.
- Khi saving: loading nhỏ.
- Khi saved: `Saved to your progress`.
- Khi failed: amber message.

## 15. UI states

### Loading

- Text: `Preparing your reflection...`
- Có skeleton card hoặc spinner nhỏ.
- Không dùng loading quá clinical.

### Normal

- Hiển thị đầy đủ 4 card.

### Saved

- Save button đổi thành `Saved`.
- Icon check mint.
- Snackbar nhẹ: `Saved to your progress`.

### Save failed

- Button quay lại `Save Progress`.
- Message amber: `Could not save right now. Try again.`

## 16. Data mapping

Input:

```dart
final String transcript;
final int durationSeconds;
```

Derived:

- `wordsPerMinute`.
- `speakingTime`.
- `pauseCount`.
- `clearMoments`.
- `repetitionsForEmphasis`.

UI mapping:

- `fillerWords` không hiển thị trực tiếp là lỗi.
- `fillerWords` có thể map thành:
  - `Hesitation moments`
  - hoặc dùng trong coach suggestion.

## 17. Mapping Flutter

File hiện tại:

- `lib/screens/analysis_screen.dart`

Refactor đề xuất:

- Rename UI title thành Results.
- Tạo widgets:
  - `_SpeechRateGaugeCard`
  - `_FluencyGraphCard`
  - `_QuickStatsCard`
  - `_CoachFeedbackCard`
  - `_ResultsActions`
- Có thể giữ class `AnalysisScreen` trong code giai đoạn đầu để tránh đổi route, nhưng UI/copy nên là Results.

## 18. Acceptance criteria

- Results không giống màn chấm điểm.
- Có back arrow và title centered.
- Có gauge bán nguyệt với turtle/rabbit.
- Có fluency graph với pause markers dịu.
- Quick stats dùng ngôn ngữ tích cực.
- Coach card có lời khuyên cụ thể, không phán xét.
- Có đủ 3 actions.
- Save state hoạt động rõ.
- Không có đỏ gắt trong feedback thông thường.
