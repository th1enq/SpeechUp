# Plan thiết kế UI mobile SpeechUp

## 1. Định hướng tổng thể

SpeechUp hiện đã có nền giao diện khá gần với tinh thần cần phát triển: màu xanh dịu, nền sáng, card bo lớn, bóng mềm, header có logo SpeechUp, bottom navigation cố định, các màn hình Home, Practice, Conversation, Progress, Profile và Analysis. Vì vậy hướng thiết kế mới không nên thay toàn bộ, mà nên mở rộng từ hệ thống hiện tại để app cảm giác quen thuộc hơn, đồng thời đưa Practice thành trải nghiệm chính đúng với định vị "Speak with Confidence".

Mục tiêu cảm xúc của sản phẩm:

- Bình tĩnh, riêng tư, an toàn và có người đồng hành.
- Không tạo cảm giác bị chấm điểm, bị sửa lỗi, bị thi cử hoặc bị phán xét.
- Ưu tiên ngôn ngữ tích cực: "smart pauses", "repetition for emphasis", "steady pace", "clear moments".
- Tránh đỏ gắt, cảnh báo mạnh, đồng hồ đếm ngược, hiệu ứng nhấp nháy hoặc âm thanh gây áp lực.
- Giao diện tối giản, khoảng thở rộng, chữ dễ đọc, thao tác chính luôn rõ ràng.

## 2. Hiện trạng dự án cần giữ lại

Các đặc điểm hiện tại nên tiếp tục giữ:

- Cấu trúc Flutter hiện có trong `lib/screens`: `main_shell.dart`, `home_screen.dart`, `practice_screen.dart`, `conversation_screen.dart`, `analysis_screen.dart`, `progress_screen.dart`, `profile_screen.dart`.
- Header kiểu SpeechUp ở đầu màn hình: icon tròn bên trái, chữ SpeechUp, icon phụ bên phải.
- Card bo lớn khoảng 22-28px, bóng mềm, nền trắng hoặc pastel.
- Nền sáng xanh rất nhạt `dashboardBackground` và các màu navy/xanh đang tạo cảm giác tin cậy.
- Các exercise card hiện có trong Practice: đọc câu, shadowing, nói chậm.
- Conversation scenario hiện có: cà phê, phỏng vấn, gọi điện, thuyết trình. Đây là nền tốt để chuyển thành Challenge.
- Progress/Profile hiện có nhiều dữ liệu hành trình, streak, session, biểu đồ và lịch sử.
- Font hiện tại `Plus Jakarta Sans` có thể giữ nếu chưa đổi ngay; khi tinh chỉnh nên ưu tiên Inter hoặc Be Vietnam Pro để hợp brief tiếng Việt.

Các điểm cần điều chỉnh dần:

- Bottom navigation hiện là 5 tab: Home, Practice, Chat, Progress, Profile. Brief yêu cầu 4 tab: Practice, Challenge, Learn, Profile.
- Practice hiện đang là danh sách bài tập, chưa phải home chính với speech-to-text real-time.
- Recording screen hiện có chấm đỏ recording, nên thay bằng soft amber/coral để giảm cảm giác cảnh báo.
- Analysis screen hiện dùng ngôn ngữ "phân tích", "từ đệm", "cần cải thiện"; nên chuyển sang Results nhẹ nhàng hơn.
- Một số màu đỏ như `recordingDotRecording`, `progressTrendRed`, `error` chỉ nên dùng cho lỗi nghiêm trọng, không dùng cho feedback luyện nói.

## 3. Design tokens đề xuất

Giữ hệ màu hiện tại làm nền chuyển tiếp, bổ sung token mới cho trải nghiệm SpeechUp Calm:

| Vai trò | Màu | Ghi chú |
|---|---:|---|
| Primary Calm Mint | `#7FD8C3` | CTA chính, trạng thái tích cực, waveform |
| Secondary Pastel Blue | `#A9D6F5` | Tab active, chip, illustration, graph |
| Background Off-White | `#F8F7F3` | Nền app mới, có thể thay dần `dashboardBackground` |
| Surface | `#FFFFFF` | Card, sheet, bottom nav |
| Main Text | `#2F3640` | Heading/body chính |
| Secondary Text | `#6B7280` | Subtitle, helper text |
| Soft Amber | `#F4B96A` | Gợi ý cần chú ý nhẹ |
| Soft Coral | `#F28B82` | Recording/stop state, không dùng đỏ gắt |
| Soft Mint Surface | `#EAF8F4` | Card phụ, selected chip |
| Soft Blue Surface | `#EEF7FE` | Graph/card nền xanh |

Typography:

- Ưu tiên: Be Vietnam Pro cho tiếng Việt, Inter cho giao diện quốc tế.
- Nếu muốn ít thay đổi code: giữ `Plus Jakarta Sans` ở giai đoạn đầu, sau đó thay dần sang `GoogleFonts.beVietnamPro()`.
- Heading: 24-30px, weight 700-800.
- Body: 15-17px, line-height 1.4-1.6.
- Transcript: 22-28px, line-height 1.45, current line đậm nhất.

Layout mobile chuẩn:

- Frame tham chiếu: 390x844.
- Safe area đầy đủ.
- Padding ngang: 16px cho thiết kế mới; có thể giữ 20px ở màn cũ, nhưng khi làm Practice real-time nên dùng 16px để đủ không gian.
- Bottom nav cố định cao 72-80px, bo trên 24px, có shadow nhẹ.
- Không để nội dung chính bị che bởi bottom nav.

## 4. Kiến trúc điều hướng đề xuất

### Giai đoạn 1: Giữ app chạy ổn, thêm trải nghiệm mới

Không xóa ngay các màn hình hiện có. Thay vào đó:

- `Practice`: trở thành home chính với real-time transcript và record button.
- `Challenge`: tái dùng logic và data từ `ConversationScreen`, đổi cách trình bày thành challenge cards.
- `Learn`: thêm màn hình mới cho thư viện nội dung.
- `Profile`: giữ `ProfileScreen`, tích hợp thêm progress summary từ `ProgressScreen`.

`HomeScreen` hiện tại có thể chuyển thành phần "Today summary" bên trong Practice hoặc giữ tạm trong code nhưng không đặt ở bottom nav chính.

`ProgressScreen` hiện tại có thể chuyển thành section trong Profile: streak, total sessions, chart, recent history.

### Bottom navigation mới

4 tab cố định:

1. Practice: icon mic hoặc graphic_eq, tab mặc định.
2. Challenge: icon flag/target/chat bubble.
3. Learn: icon menu_book.
4. Profile: icon person.

Style:

- Surface trắng, bo top 24px, shadow `0 -4 20 rgba(47,54,64,0.08)`.
- Active indicator dùng mint rất nhạt hoặc pastel blue.
- Label ngắn, dễ đọc.
- Không dùng animation phóng to mạnh; chỉ fade/slide nhẹ 180-220ms.

## 5. Practice screen - trải nghiệm chính

Mục tiêu: người dùng mở app là có cảm giác đang ở một không gian luyện nói riêng tư, chỉ cần chạm để bắt đầu.

### Cấu trúc màn hình

Header:

- Bên trái: SpeechUp logo hiện tại, nhưng thay icon person/lightbulb bằng biểu tượng mic/wave nhẹ nếu phù hợp.
- Text: `SpeechUp`.
- Bên phải: icon microphone settings hoặc tune, không dùng notification ở Practice chính.

Transcript panel:

- Chiếm khoảng hai phần ba phía trên màn hình.
- Card hoặc surface lớn bo 28px, nền trắng, bóng rất nhẹ.
- Bên trong có label nhỏ: `Private practice`.
- Transcript real-time:
  - Dòng hiện tại: `#2F3640`, 24-28px, weight 700.
  - Dòng trước đó: `#6B7280` opacity 0.55-0.75, 20-22px.
  - Dòng xa hơn: opacity thấp hơn để tạo flow effect.
- Khi chưa bắt đầu:
  - Text nhẹ: `Your words will appear here`.
  - Subtext: `Only you can see this session.`

Visualizer:

- Đặt dưới transcript panel, căn giữa.
- Có thể dùng waveform bars hiện có từ recording/onboarding, đổi màu sang mint/pastel blue.
- Recording state: pulse tròn hoặc waveform chuyển động nhẹ, không nhấp nháy.
- Idle state: waveform mờ, gần như đứng yên.

Record action:

- Nút tròn lớn 88-104px, nằm lower third, phía trên bottom nav.
- Default:
  - Màu mint `#7FD8C3`.
  - Icon mic.
  - Label dưới nút: `Tap to Start`.
- Recording:
  - Màu soft coral/amber, ví dụ `#F28B82` hoặc `#F4B96A`.
  - Icon stop bo tròn.
  - Label: `Tap to Finish`.
- Helper line:
  - `Speak naturally - I am listening`
  - Màu `#6B7280`, 14-15px.

Không đưa vào Practice:

- Không countdown.
- Không timer gây áp lực ở trạng thái nổi bật.
- Không cảnh báo đỏ.
- Không "score" trong lúc đang nói.
- Không rung/flash khi người dùng ngập ngừng.

### Kịch bản Practice

1. Người dùng mở app ở tab Practice.
2. App hiển thị transcript panel trống, waveform mờ, nút `Tap to Start`.
3. Người dùng chạm nút record.
4. Nút đổi sang soft coral, label `Tap to Finish`, helper text đổi thành `Speak naturally - I am listening`.
5. Transcript chạy theo thời gian thực. Dòng đang nói rõ nhất, dòng cũ mờ nhẹ.
6. Nếu có khoảng dừng, app không cảnh báo. Visualizer chỉ dịu xuống.
7. Người dùng chạm `Tap to Finish`.
8. App chuyển sang Results bằng transition nhẹ fade/slide up.

## 6. Results screen

Nên phát triển từ `analysis_screen.dart`, nhưng đổi ngôn ngữ từ "phân tích/chấm điểm" sang "kết quả hỗ trợ".

Header:

- Nền trong suốt hoặc off-white.
- Back arrow bên trái.
- Title căn giữa: `Results`.
- Không dùng close icon nếu luồng quay lại rõ ràng hơn với back arrow.

Card 1 - Speech-rate gauge:

- Semi-circular gauge trong card trắng bo 24-28px.
- Band màu: pastel blue, mint, soft amber.
- Turtle icon ở đầu chậm, rabbit icon ở đầu nhanh.
- Text chính: `Steady pace` hoặc `A little fast, still clear`.
- Không dùng câu như "quá nhanh" hoặc "sai".

Card 2 - Fluency graph:

- Line chart mềm, đường cong mượt.
- Pause markers là chấm nhỏ màu muted amber/blue.
- Label tích cực: `Natural pauses`, `Clear flow`, `Breathing space`.

Card 3 - Quick stats:

- Dùng 2-4 stat nhỏ.
- Ví dụ:
  - `Smart pauses: 6`
  - `Repetition for emphasis: 2`
  - `Clear moments: 8`
  - `Speaking time: 1m 12s`
- Không gọi trực tiếp là lỗi, từ đệm hoặc thất bại.

AI coach card:

- Card có avatar/illustration mềm.
- Title: `Coach note`.
- Nội dung ví dụ:
  - `You kept going through pauses, which is a strong habit. Next time, try one slower breath before the second sentence.`
- CTA phụ: `Try one gentle pacing exercise`.

Bottom actions:

- `Practice Again`: primary mint.
- `Continue to Challenge`: secondary pastel blue/outlined.
- `Save Progress`: text button hoặc tertiary.

Kịch bản Results:

1. Sau khi kết thúc Practice, Results mở với loading nhẹ `Preparing your reflection...`.
2. Gauge animate từ 0 tới vị trí trong 900-1200ms.
3. Graph vẽ line nhẹ, pause marker fade in.
4. Coach card xuất hiện cuối cùng để cảm giác như một phản hồi riêng tư.
5. Người dùng chọn luyện lại, chuyển Challenge hoặc lưu tiến độ.

## 7. Challenge screen

Nên tái thiết kế từ `ConversationScreen` hiện tại. Các scenario cũ rất phù hợp và chỉ cần mở rộng metadata.

Header:

- Title: `Choose a gentle challenge`.
- Subtitle: `Practice real moments at your own pace.`

Category filters:

- Horizontal chips, scroll ngang.
- Categories:
  - Daily Communication
  - Interview
  - Presentation
  - Ordering Food
  - Self Introduction
- Selected chip dùng mint surface, text charcoal.

Challenge cards:

- Card trắng hoặc pastel nhạt, bo 24px.
- Mỗi card gồm:
  - Icon tròn nhỏ.
  - Title.
  - Description.
  - Difficulty chip: Easy, Medium, Growing.
  - Duration: `2-3 min`, `5 min`.
  - Start button nhỏ: `Start`.
- Tái dùng các scenario hiện có:
  - `Gọi đồ uống tại quán cà phê` -> Ordering Food/Daily Communication.
  - `Phỏng vấn xin việc` -> Interview.
  - `Gọi điện cho khách hàng` -> Daily Communication/Work.
  - `Thuyết trình trước nhóm` -> Presentation.

Challenge details:

- Header có back arrow.
- Scenario context card: mô tả tình huống.
- Prompt hints:
  - 2-3 gợi ý ngắn, không bắt buộc.
  - Ví dụ: `Start with a calm greeting`, `Pause before the key point`.
- Large answer/record action:
  - Nút tròn hoặc pill lớn `Answer with voice`.
  - Không có timer bắt buộc.
- Sau khi ghi âm, chuyển Results hoặc hiển thị coach note ngắn.

## 8. Learn screen

Đây là màn hình mới, nên thiết kế nhẹ như thư viện nội dung, không giống lớp học áp lực.

Header:

- Title: `Learn calmly`.
- Subtitle: `Small lessons for easier speaking.`

Categories:

- Breathing
- Pacing
- Confidence
- Reducing Hesitation

Lesson cards:

- Editorial-style card, bo 24px.
- Có thumbnail mềm: illustration thở, nhịp sóng, người nói, cây/lá phát triển.
- Title.
- Short description.
- CTA: `Read`, `Start 2-min practice`, hoặc `Try now`.

Nội dung lesson gợi ý:

- `One breath before the first word`
- `How to use pauses with confidence`
- `Gentle pacing for interviews`
- `Speaking when you feel stuck`
- `Turning repetition into emphasis`

Kịch bản Learn:

1. Người dùng vào Learn khi muốn chuẩn bị ngoài phiên ghi âm.
2. Chọn category hoặc lesson.
3. Lesson mở bằng layout đọc ngắn, nhiều khoảng trắng.
4. Cuối lesson có CTA đưa về Practice hoặc Challenge.

## 9. Profile screen

Giữ nền tảng từ `ProfileScreen` và một phần `ProgressScreen`, chỉ đổi cách diễn đạt và nhóm thông tin.

Phần đầu:

- Avatar.
- Name.
- Tagline khích lệ:
  - `Building confidence one calm session at a time`
  - Hoặc tiếng Việt: `Mỗi lần luyện tập là một bước nói tự tin hơn`

Stats:

- Streak.
- Total sessions.
- Speaking minutes.
- Gentle progress chart.

Recent session history:

- Danh sách phiên gần đây.
- Mỗi item có ngày, loại luyện tập, một insight tích cực.
- Ví dụ: `You used 4 smart pauses`.

Settings:

- Microphone.
- Language.
- Privacy.
- Notifications.
- Mode selection.
- Optional playful mode.

Privacy copy cần nổi bật:

- `Your practice space is private by default.`
- `You choose what to save.`

## 10. Optional playful mode

Playful mode chỉ là tùy chọn trong Profile, không bật mặc định.

Thành phần có thể thêm:

- Badges nhẹ: `First calm start`, `3-day practice rhythm`, `Interview ready`.
- Journey metaphor: con đường phát triển, cây mọc, sóng đều.
- AI companion mềm, không nói quá nhiều.
- Growth visuals dùng mint/blue/amber nhẹ.

Quy tắc:

- Không overstimulating.
- Không confetti lớn, không âm thanh thắng/thua.
- Không tạo áp lực streak bằng màu đỏ hoặc cảnh báo mất chuỗi.
- Badge phải là khích lệ, không phải bảng xếp hạng.

## 11. Micro-interactions

Buttons:

- Press feedback: opacity 0.94, scale 0.98 trong 120-160ms.
- Không bounce mạnh.

Cards:

- Tap lift nhẹ: shadow tăng rất ít, translateY -1 hoặc -2.
- Không thay đổi kích thước gây layout shift.

Visualizer:

- Idle: chuyển động rất chậm hoặc static.
- Recording: pulse/wave êm 600-1200ms.
- Respect reduced motion.

Charts:

- Gauge animate easeOutCubic.
- Graph draw trong 900-1200ms.
- Marker fade in nhẹ.

Transitions:

- Practice -> Results: fade + slide up nhẹ.
- Bottom tab switch: fade content hoặc IndexedStack giữ state.
- Modal settings: bottom sheet bo top 28px.

## 12. Nội dung/copywriting nên dùng

Tone:

- Bình tĩnh, riêng tư, khích lệ.
- Tránh phán xét.
- Nói như một người đồng hành.

Copy nên dùng:

- `Speak naturally - I am listening`
- `Take your time`
- `Your pace is welcome here`
- `Private practice`
- `Smart pauses`
- `Clear moments`
- `Repetition for emphasis`
- `A steady start`
- `Try one gentle breath before the next sentence`

Copy nên tránh:

- `Sai`
- `Lỗi`
- `Quá chậm`
- `Quá nhanh`
- `Cần sửa ngay`
- `Failed`
- `Bad score`
- `Warning`

## 13. Lộ trình triển khai đề xuất

### Phase 1 - Thiết kế thêm, ít rủi ro

- Bổ sung token màu calm mới vào `AppColors`.
- Đổi đỏ recording sang coral/amber mềm.
- Thêm màn `LearnScreen`.
- Thêm route/tab `Challenge` dựa trên `ConversationScreen`.
- Chuẩn hóa copy kết quả trong `AnalysisScreen` theo hướng Results.

### Phase 2 - Đưa Practice thành home chính

- Cập nhật `MainShell` thành 4 tab: Practice, Challenge, Learn, Profile.
- Chuyển summary từ `HomeScreen` vào Practice hoặc Profile.
- Thiết kế Practice real-time transcript panel.
- Thêm visualizer và record button trạng thái idle/recording.

### Phase 3 - Results nâng cao

- Thay metric bar hiện tại bằng:
  - Speech-rate semi gauge.
  - Fluency graph.
  - Quick stats tích cực.
  - AI coach feedback card.
- Thêm 3 action cuối màn: Practice Again, Continue to Challenge, Save Progress.

### Phase 4 - Hoàn thiện cảm xúc và accessibility

- Kiểm tra contrast text.
- Kiểm tra touch target tối thiểu 44x44.
- Thêm reduced motion.
- Kiểm tra màn 390x844, 375x812 và 430x932.
- Đảm bảo bottom nav không che nội dung.
- Kiểm tra tiếng Việt dài không tràn layout.

## 14. Mapping từ code hiện tại sang thiết kế mới

| Hiện tại | Hướng mới |
|---|---|
| `MainShell` 5 tab | Đổi thành 4 tab Practice, Challenge, Learn, Profile |
| `HomeScreen` | Tách thành Today Summary trong Practice/Profile, không còn là tab chính |
| `PracticeScreen` exercise list | Chuyển thành Practice home real-time; exercise cards có thể đưa xuống phần suggestions |
| `_RecordingScreen` | Hợp nhất hoặc gọi từ Practice/Challenge với UI transcript + visualizer |
| `AnalysisScreen` | Đổi thành Results screen supportive |
| `ConversationScreen` | Đổi tên/thiết kế thành Challenge screen |
| `ProgressScreen` | Gộp summary/chart vào Profile |
| `ProfileScreen` | Giữ, thêm privacy/settings/mode selection |

## 15. Checklist thiết kế cuối

- [ ] Practice là màn mở chính.
- [ ] Bottom nav có đúng 4 tab.
- [ ] Transcript panel chiếm phần lớn màn hình và chữ đủ lớn.
- [ ] Record button rõ, an toàn, không dùng đỏ gắt.
- [ ] Results không tạo cảm giác bị chấm điểm.
- [ ] Challenge có filter ngang và card tình huống mềm.
- [ ] Learn có categories và lesson cards.
- [ ] Profile có privacy, language, microphone, notifications và mode selection.
- [ ] Playful mode là tùy chọn.
- [ ] Không có countdown, cảnh báo nhấp nháy, timer gây áp lực.
- [ ] Màu chủ đạo dùng mint, pastel blue, off-white, white, charcoal và secondary gray.
- [ ] Giao diện vẫn giữ DNA hiện tại: card bo lớn, bóng mềm, header SpeechUp, cảm giác xanh dịu và thân thiện.

## 16. Đánh giá mức độ đầy đủ của plan hiện tại

Plan hiện tại đã đủ về hướng sản phẩm, cảm xúc, palette, cấu trúc tab và mô tả từng màn hình. Tuy nhiên để triển khai thật chắc trong dự án Flutter hiện có, cần bổ sung thêm các phần sau:

- Wireframe chi tiết theo frame 390x844 để biết vị trí, chiều cao tương đối và khoảng cách.
- Component inventory để designer/dev tái dùng nhất quán.
- State design cho Practice: idle, permission, recording, paused/silence, processing, error.
- State design cho Results: loading, normal, saved, save failed.
- Nội dung mẫu cụ thể cho từng màn hình bằng tiếng Anh và tiếng Việt.
- Mapping task kỹ thuật theo file Flutter hiện tại.
- Accessibility, privacy và motion rules rõ hơn.
- Acceptance criteria để kiểm tra sau khi làm UI.

Các phần dưới đây là bản hoàn thiện chi tiết để bù các điểm còn thiếu.

## 17. Wireframe chi tiết theo màn 390x844

Quy ước chung:

- Safe area top khoảng 44px, bottom khoảng 34px.
- Padding ngang: 16px.
- Khoảng cách giữa section: 16-24px.
- Nội dung scroll cần chừa khoảng 96-112px cuối màn để không bị bottom navigation che.
- Bottom navigation cao 76px, surface trắng, bo top 24px.

### Practice - trạng thái idle

Kích thước tham chiếu:

- Header: y 8-56 trong safe area.
- Transcript card: y 72-452, cao khoảng 380px.
- Visualizer: y 472-526, cao khoảng 54px.
- Record button: y 562-666, nút 96x96.
- Helper text: y 676-704.
- Bottom nav: y 768-844.

Layout đề xuất:

```text
SafeArea
  Header
    [Logo icon] SpeechUp                         [Mic settings]

  TranscriptPanel
    Private practice
    Your words will appear here
    Only you can see this session.

  GentleWaveform / CircularPulse

  RecordArea
    [Large circular mic button]
    Tap to Start
    Take your time

  BottomNav
    Practice | Challenge | Learn | Profile
```

Ghi chú:

- Transcript card không nên nhỏ hơn 330px chiều cao trên 390x844.
- Nếu thiết bị thấp hơn 812px, giảm khoảng cách vertical trước, không giảm kích thước chữ transcript quá nhiều.
- Nút record phải nằm độc lập, không bị lẫn với card để tạo cảm giác hành động chính.

### Practice - trạng thái recording

Thay đổi so với idle:

- Header bên phải đổi thành mic settings vẫn có thể bấm, nhưng không mở popup lớn trong lúc đang ghi. Nếu cần mở, dùng bottom sheet nhỏ.
- Transcript panel hiện 3-5 dòng gần nhất.
- Current line nằm gần giữa hoặc cuối panel để người dùng dễ theo dõi.
- Visualizer animate nhẹ theo âm lượng.
- Record button đổi màu soft coral, icon stop.
- Helper text: `Speak naturally - I am listening`.

Ví dụ transcript:

```text
I want to introduce myself...

Today I am practicing for an interview...

My name is Bao and I am learning to speak
with more confidence.
```

### Results

Kích thước tham chiếu:

- Header: y 8-56.
- Scroll content bắt đầu y 72.
- Card gauge: cao 210-240px.
- Card graph: cao 180-210px.
- Quick stats: cao 120-150px.
- Coach card: cao 150-190px.
- Action area: có thể sticky dưới cùng hoặc nằm cuối scroll.

Layout đề xuất:

```text
Header
  [Back]                  Results

ScrollView
  SpeechRateGaugeCard
    Semi gauge
    Steady pace
    118 words/min

  FluencyGraphCard
    Smooth line + pause markers
    Natural pauses helped your rhythm

  QuickStatsCard
    Smart pauses | Clear moments | Speaking time

  CoachFeedbackCard
    [Soft avatar] Coach note
    Supportive guidance

  Actions
    Practice Again
    Continue to Challenge
    Save Progress
```

### Challenge

Kích thước tham chiếu:

- Header: y 8-112.
- Filter chips: y 128-172.
- Challenge card: cao 150-180px mỗi card.
- Bottom content padding: 112px.

Layout đề xuất:

```text
Header
  Challenge
  Practice real moments at your own pace.

HorizontalFilter
  Daily Communication | Interview | Presentation | Ordering Food | Self Introduction

ChallengeList
  Card: Ordering a coffee
  Card: Interview introduction
  Card: Presenting one idea
```

### Challenge details

Layout đề xuất:

```text
Header
  [Back]                  Interview

ScenarioContextCard
  You are answering: "Tell me about yourself."

PromptHints
  Start with your name
  Mention one strength
  Pause before your final sentence

AnswerCard
  [Large record button]
  Answer with voice
  No rush. You can try again.
```

### Learn

Kích thước tham chiếu:

- Header: y 8-112.
- Category chips: y 128-172.
- Featured lesson: cao 160-190px.
- Lesson card: cao 120-150px.

Layout đề xuất:

```text
Header
  Learn calmly
  Small lessons for easier speaking.

CategoryChips
  Breathing | Pacing | Confidence | Reducing Hesitation

FeaturedLessonCard
  One breath before the first word

LessonList
  How to use pauses with confidence
  Gentle pacing for interviews
  Speaking when you feel stuck
```

### Profile

Kích thước tham chiếu:

- Header/profile identity: cao 150-180px.
- Stats row: cao 92-110px.
- Progress chart: cao 180-220px.
- Recent sessions: item 72-88px.
- Settings list: item 56-64px.

Layout đề xuất:

```text
ProfileHeader
  [Avatar]
  Bao
  Building confidence one calm session at a time

StatsRow
  Streak | Sessions | Minutes

ProgressCard
  Gentle progress this week

RecentSessions
  Today - Practice - 4 smart pauses
  Yesterday - Interview - steady pace

Settings
  Microphone
  Language
  Privacy
  Notifications
  Mode selection
```

## 18. Component inventory cần thiết

Các component nên tạo/tái dùng để UI đồng nhất:

| Component | Mục đích | Gợi ý Flutter |
|---|---|---|
| `SpeechUpHeader` | Header có logo, title, action icon | Tách từ header lặp trong Home/Practice/Conversation |
| `CalmCard` | Card trắng/pastel có radius và shadow chuẩn | `Container` + `BoxDecoration` |
| `SoftChip` | Category/difficulty/status chip | `ChoiceChip` custom hoặc `InkWell` |
| `PrimaryCalmButton` | CTA mint | `ElevatedButton` theme custom |
| `SecondaryCalmButton` | CTA phụ blue/outline | `OutlinedButton` custom |
| `CircularRecordButton` | Record/stop action | `GestureDetector`/`InkWell` + `AnimatedContainer` |
| `TranscriptPanel` | Speech-to-text realtime | `AnimatedSwitcher` + `RichText`/`Column` |
| `GentleWaveform` | Visualizer | CustomPainter hoặc Row bars animated |
| `SpeechRateGauge` | Semi gauge Results | CustomPainter |
| `FluencyLineChart` | Graph mềm | CustomPainter hoặc chart lib nếu đã dùng |
| `QuickStatsGrid` | Stats tích cực | `GridView`/`Wrap` không scroll riêng |
| `CoachFeedbackCard` | AI coach note | `CalmCard` + avatar/icon |
| `SettingsRow` | Profile settings | `ListTile` style custom |

Component style chuẩn:

- Card radius: 24px cho card thường, 28px cho panel lớn.
- Button radius: 16px cho pill, circle cho record.
- Shadow card: `blurRadius 18-24`, `offset 0,8`, alpha 0.06-0.10.
- Icon circle: 44-52px.
- Touch target: tối thiểu 44x44.

## 19. UI states cần thiết

### Practice states

Idle:

- Transcript placeholder.
- Waveform mờ.
- Button mint, label `Tap to Start`.
- Helper: `Take your time`.

Mic permission not granted:

- Card nhỏ dưới transcript:
  - Title: `Microphone access is needed`
  - Body: `SpeechUp only listens during your practice session.`
  - CTA: `Allow microphone`
  - Secondary: `Open settings`
- Không dùng cảnh báo đỏ.

Recording:

- Button coral/amber.
- Transcript cập nhật.
- Waveform animate.
- Helper: `Speak naturally - I am listening`.

Soft silence:

- Không hiển thị lỗi.
- Helper có thể đổi nhẹ sau 4-5 giây im lặng:
  - `Take your time. Pauses are welcome.`
- Waveform giảm biên độ.

Processing:

- Sau khi finish:
  - Text: `Preparing your reflection...`
  - Loading indicator mint nhỏ.
  - Không dùng chữ `Analyzing errors`.

Network/save issue:

- Nếu không lưu được:
  - Toast/snackbar nhẹ: `Progress was not saved. You can try again.`
  - Màu amber nhẹ, không đỏ.

### Results states

Loading:

- Skeleton card mờ hoặc loading text.
- Không hiển thị spinner lớn chiếm màn hình quá lâu.

Normal:

- Gauge + graph + stats + coach card.

Saved:

- `Saved to your progress`
- Icon check mint.

Save failed:

- `Could not save right now`
- CTA `Try again`
- Màu amber.

### Challenge states

Empty category:

- `No challenges here yet`
- `Try another category or start a free practice session.`

Challenge in progress:

- Hiển thị context và answer action.
- Không khóa người dùng vào flow; có thể back.

### Learn states

Empty/loading:

- Skeleton lesson cards.
- Nếu lỗi: `Lessons could not load right now. Try again later.`

Completed lesson:

- Chip nhỏ `Read`.
- CTA cuối bài: `Try this in Practice`.

### Profile states

Guest/offline:

- Hiển thị thông tin local nếu có.
- CTA nhẹ: `Sign in to sync progress`.

Privacy mode:

- Cho phép bật `Private mode`.
- Khi bật, app chỉ lưu local hoặc hỏi trước khi lưu, tùy khả năng kỹ thuật.

## 20. Nội dung mẫu chi tiết cho từng màn hình

### Practice copy

English:

- Title/label: `Private practice`
- Placeholder: `Your words will appear here`
- Privacy line: `Only you can see this session.`
- Idle helper: `Take your time`
- Recording helper: `Speak naturally - I am listening`
- Silence helper: `Pauses are welcome here`
- Finish processing: `Preparing your reflection...`

Vietnamese:

- Label: `Không gian luyện tập riêng tư`
- Placeholder: `Lời nói của bạn sẽ hiện ở đây`
- Privacy line: `Chỉ bạn nhìn thấy phiên luyện tập này.`
- Idle helper: `Cứ từ từ, không cần vội`
- Recording helper: `Hãy nói tự nhiên - SpeechUp đang lắng nghe`
- Silence helper: `Khoảng dừng cũng là một phần của nhịp nói`
- Finish processing: `Đang chuẩn bị phản hồi nhẹ nhàng...`

### Results copy

English:

- `Steady pace`
- `A little fast, still clear`
- `Natural pauses helped your rhythm`
- `You kept going through pauses. That is a strong speaking habit.`
- `Try one slower breath before your next answer.`

Vietnamese:

- `Nhịp nói ổn định`
- `Hơi nhanh một chút, nhưng vẫn rõ ý`
- `Những khoảng dừng giúp câu nói tự nhiên hơn`
- `Bạn đã tiếp tục nói qua các khoảng dừng. Đây là một thói quen rất tốt.`
- `Lần tới, hãy thử hít chậm một nhịp trước câu tiếp theo.`

### Challenge copy

English:

- `Choose a gentle challenge`
- `Practice real moments at your own pace.`
- `No rush. You can try again.`
- `Answer with voice`

Vietnamese:

- `Chọn một tình huống luyện tập`
- `Luyện các khoảnh khắc đời thật theo nhịp của bạn.`
- `Không cần vội. Bạn luôn có thể thử lại.`
- `Trả lời bằng giọng nói`

### Learn copy

English:

- `Learn calmly`
- `Small lessons for easier speaking.`
- `One breath before the first word`
- `Use pauses with confidence`

Vietnamese:

- `Học thật nhẹ nhàng`
- `Những bài ngắn giúp việc nói dễ hơn.`
- `Một hơi thở trước từ đầu tiên`
- `Dùng khoảng dừng một cách tự tin`

### Profile copy

English:

- `Building confidence one calm session at a time`
- `Your practice space is private by default.`
- `You choose what to save.`

Vietnamese:

- `Mỗi phiên luyện tập là một bước nói tự tin hơn`
- `Không gian luyện tập của bạn mặc định là riêng tư.`
- `Bạn chọn điều gì được lưu lại.`

## 21. Chi tiết chuyển đổi màn hình hiện có

### `lib/screens/main_shell.dart`

Việc cần làm:

- Đổi `_currentIndex` mặc định từ Home sang Practice nếu Practice là tab đầu.
- `IndexedStack` gồm 4 màn:
  - `PracticeScreen`
  - `ChallengeScreen` hoặc `ConversationScreen` đã đổi UI
  - `LearnScreen`
  - `ProfileScreen`
- Tạm thời giữ file `HomeScreen` trong code để tránh mất logic dashboard, nhưng không đưa vào nav.
- Nếu vẫn cần progress, đưa `ProgressScreen` vào Profile qua section hoặc route phụ.

Rủi ro:

- Các lệnh `onNavigate(1)` trong `HomeScreen` không còn dùng nếu Home bỏ khỏi nav.
- Localization keys `nav.home`, `nav.chat`, `nav.progress` cần thêm/sửa thành `nav.challenge`, `nav.learn`.

### `lib/screens/practice_screen.dart`

Việc cần làm:

- Tách danh sách bài tập hiện tại thành section `Suggested practice` ở dưới hoặc chuyển sang Challenge/Learn.
- Thêm state:
  - `isRecording`
  - `transcriptLines`
  - `currentLine`
  - `hasMicPermission`
  - `isProcessing`
- Thay `_RecordingScreen` hiện tại bằng UI record ngay trong Practice hoặc giữ như route full-screen nhưng đổi layout theo transcript panel.
- Thay notification icon bằng mic settings icon.
- Dùng `AnimationController` cho waveform/pulse.

Giữ lại:

- Exercise card style bo lớn, icon tròn, shadow.
- Gradient/blue hiện có có thể dùng cho secondary accent, nhưng primary CTA nên đổi sang mint.

### `lib/screens/analysis_screen.dart`

Việc cần làm:

- Đổi title từ `Kết quả phân tích` sang `Results` hoặc `Kết quả luyện tập`.
- Đổi close icon thành back arrow nếu flow dùng push.
- Thay `_MetricBar` bằng các card:
  - `_SpeechRateGaugeCard`
  - `_FluencyGraphCard`
  - `_QuickStatsCard`
  - `_CoachFeedbackCard`
- Đổi copy:
  - `Từ đệm` -> `Repetition for emphasis` hoặc `Khoảnh khắc lặp lại`
  - `Hơi nhanh, thử chậm lại nhé` -> `Hơi nhanh một chút, bạn có thể thử thêm một nhịp thở`
  - `Cần cải thiện` -> `Gợi ý nhẹ`

### `lib/screens/conversation_screen.dart`

Việc cần làm:

- Đổi concept thành Challenge.
- Thêm category filter.
- Mỗi `_Scenario` bổ sung:
  - `category`
  - `difficulty`
  - `durationLabel`
  - `promptHints`
- `_ConversationChat` có thể giữ làm challenge detail/chat mode, nhưng entry UI nên là challenge card.

### `lib/screens/profile_screen.dart`

Việc cần làm:

- Thêm tagline.
- Thêm privacy card.
- Thêm settings row cho microphone, language, privacy, notifications, mode selection.
- Gộp một phần progress vào profile: streak, total sessions, chart, recent history.

### `lib/theme/app_colors.dart`

Việc cần làm:

- Bổ sung nhóm token mới, không xóa token cũ ngay:

```dart
// SpeechUp Calm refresh
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

## 22. Data model gợi ý cho UI

Challenge model:

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
}
```

Lesson model:

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
}
```

Result UI model:

```dart
class PracticeResultSummary {
  final int wordsPerMinute;
  final Duration speakingTime;
  final int smartPauses;
  final int clearMoments;
  final int repetitionsForEmphasis;
  final String coachTitle;
  final String coachMessage;
}
```

Lưu ý:

- Model UI không cần gọi các metric là lỗi.
- Nếu backend/Firestore vẫn lưu `fillerWords` hoặc metric kỹ thuật, UI layer nên map sang copy tích cực.

## 23. Accessibility và privacy

Accessibility:

- Text chính tối thiểu 15px, transcript tối thiểu 22px.
- Contrast body text đạt tối thiểu 4.5:1.
- Button và icon button tối thiểu 44x44.
- Record button có semantic label:
  - Idle: `Start recording`
  - Recording: `Finish recording`
- Waveform chỉ là decorative nếu không truyền thông tin quan trọng; dùng `ExcludeSemantics` nếu cần.
- Respect reduced motion:
  - Tắt pulse liên tục.
  - Giảm animation chart xuống fade đơn giản.

Privacy:

- Practice phải luôn có tín hiệu rõ là riêng tư.
- Trước khi lưu progress, user nên biết dữ liệu sẽ được lưu.
- Nếu app có Firebase sync:
  - Profile cần có mục `Privacy`.
  - Save Progress nên có trạng thái rõ.
- Không tự động chia sẻ transcript.
- Không hiển thị transcript nhạy cảm ở Recent Sessions; chỉ hiển thị insight tổng quát.

## 24. Visual QA checklist theo màn

Practice:

- [ ] Mở app thấy ngay nút record chính.
- [ ] Transcript panel đủ lớn, chữ không nhỏ hơn 22px.
- [ ] Có mic settings ở góc phải.
- [ ] Không còn notification icon gây lệch mục tiêu trên Practice.
- [ ] Recording state không dùng đỏ gắt.
- [ ] Không có countdown/timer nổi bật.
- [ ] Helper line dịu, không phán xét.

Results:

- [ ] Header có back arrow và title giữa.
- [ ] Gauge không giống chấm điểm bài thi.
- [ ] Graph dùng marker nhẹ, không cảnh báo đỏ.
- [ ] Quick stats dùng ngôn ngữ tích cực.
- [ ] Coach card nằm sau stats, lời khuyên cụ thể và ngắn.
- [ ] Có đủ 3 action cuối màn.

Challenge:

- [ ] Filter ngang hoạt động và không tràn text.
- [ ] Card có title, mô tả, difficulty, duration, start.
- [ ] Challenge detail có context, prompt hints, record action.
- [ ] Không ép thời gian.

Learn:

- [ ] Có categories đúng brief.
- [ ] Lesson card có thumbnail/visual, title, mô tả, CTA.
- [ ] Nội dung không giống bài kiểm tra.

Profile:

- [ ] Có avatar, name, tagline.
- [ ] Có streak, total sessions, progress chart, recent history.
- [ ] Có settings microphone, language, privacy, notifications, mode.
- [ ] Playful mode là optional.

## 25. Tiêu chí nghiệm thu cuối cùng

Một bản UI được xem là đạt khi:

- Người dùng mới hiểu ngay app dùng để luyện nói riêng tư trong 5 giây đầu.
- Practice là hành động chính, không bị dashboard phụ làm phân tán.
- Không có màu đỏ/cảnh báo mạnh trong trải nghiệm luyện nói bình thường.
- Results cho người dùng cảm giác được hỗ trợ, không bị chấm lỗi.
- Challenge dùng lại được thế mạnh Conversation hiện có nhưng trình bày rõ hơn như bài luyện tình huống.
- Learn bổ sung giá trị trước/sau practice, không thay thế practice.
- Profile trở thành nơi xem hành trình và kiểm soát quyền riêng tư.
- UI vẫn nhận ra là SpeechUp hiện tại: xanh dịu, card lớn, shadow mềm, header quen thuộc.
- Mọi màn hình chính hoạt động tốt trên 390x844, 375x812 và 430x932.
- Không có text tiếng Việt bị tràn, đặc biệt ở chip, button và bottom nav.

## 26. Thứ tự ưu tiên nếu thời gian hạn chế

Nếu chỉ có thời gian làm một phần, ưu tiên theo thứ tự:

1. Cập nhật Practice thành màn chính với transcript panel, visualizer và record button.
2. Đổi màu/copy recording và results để loại bỏ cảm giác cảnh báo/chấm lỗi.
3. Đổi bottom nav thành 4 tab theo brief.
4. Chuyển Conversation thành Challenge bằng cách thêm filter và challenge card.
5. Thêm Learn screen với dữ liệu tĩnh trước.
6. Gộp Progress summary vào Profile.
7. Thêm playful mode sau cùng vì đây là optional.
