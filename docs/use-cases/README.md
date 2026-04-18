# SpeechUp Use Case Specifications

Tài liệu này phân rã từ `plan.md` thành các đặc tả riêng biệt theo từng use case. `plan.md` được giữ nguyên và đóng vai trò tài liệu định hướng tổng thể. Các file trong thư mục này dùng để triển khai chi tiết chức năng và giao diện.

## Danh sách đặc tả

| Mã | File | Mục đích |
|---|---|---|
| UC-00 | `00-foundation-navigation-design-system.md` | Nền tảng thiết kế, navigation, token, component chung |
| UC-01 | `01-private-practice.md` | Màn Practice chính: realtime transcript, visualizer, record action |
| UC-02 | `02-results-feedback.md` | Màn Results: gauge, graph, stats, AI coach, action |
| UC-03 | `03-challenge.md` | Màn Challenge: category, challenge cards, detail, voice answer |
| UC-04 | `04-learn.md` | Màn Learn: content library, lesson cards, lesson detail |
| UC-05 | `05-profile-progress-settings.md` | Màn Profile: identity, stats, progress, recent sessions, settings |
| UC-06 | `06-microphone-privacy-save.md` | Quyền microphone, private mode, save progress, lỗi quyền/lưu |
| UC-07 | `07-optional-playful-mode.md` | Playful mode tùy chọn: badge, journey, companion |

## Nguyên tắc đọc tài liệu

- Mỗi file là một use case độc lập, có thể giao cho một designer/dev xử lý riêng.
- Khi có xung đột, ưu tiên `plan.md` cho định hướng sản phẩm và ưu tiên file use case cho chi tiết triển khai.
- Không xóa hoặc thay thế UI hiện có nếu chưa cần. Thiết kế mới phải mở rộng từ app hiện tại: card bo lớn, xanh dịu, shadow mềm, header SpeechUp, trải nghiệm không phán xét.

## Scope tổng thể

App cần chuyển dần từ bottom navigation 5 tab hiện tại sang 4 tab:

1. Practice
2. Challenge
3. Learn
4. Profile

Các màn hiện tại được tái sử dụng:

- `PracticeScreen` trở thành màn chính luyện nói riêng tư.
- `AnalysisScreen` chuyển hóa thành Results.
- `ConversationScreen` chuyển hóa thành Challenge.
- `ProgressScreen` được gộp vào Profile.
- `HomeScreen` có thể giữ trong code nhưng không còn là tab chính.

## Definition of Done chung

- Giao diện giữ được DNA hiện tại của SpeechUp.
- Không dùng đỏ gắt cho trạng thái luyện nói bình thường.
- Không có countdown, flashing warning, pressure timer.
- Text tiếng Việt và tiếng Anh không tràn ở 390x844, 375x812, 430x932.
- Touch target tối thiểu 44x44.
- Có state loading, empty, permission/error phù hợp.
- Motion dịu, có phương án reduced motion.
- Người dùng luôn cảm thấy đây là không gian luyện tập riêng tư, an toàn và được khích lệ.
