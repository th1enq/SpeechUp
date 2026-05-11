# SpeechUp Refactoring — Implementation Plan

> [!IMPORTANT]
> This plan covers **5 phases** of refactoring across the entire SpeechUp Flutter application. Each phase is self-contained and can be reviewed independently.

---

## Phase 1: Authentication Refactor (Login/Registration)

### Current State
- [login_screen.dart](file:///home/bao/Downloads/SpeechUp/lib/screens/login_screen.dart) — 1643 lines
- Multi-step flow: `_step = 0` (email) → `_step = 1` (password) → separate signup steps
- Auth logic in [auth_service.dart](file:///home/bao/Downloads/SpeechUp/lib/services/auth_service.dart) is solid

### Changes Required

| Task | File | Description |
|------|------|-------------|
| Consolidate to single-screen | `login_screen.dart` | Remove `_step` state machine. Show email + password fields simultaneously |
| Validation UI | `login_screen.dart` | Red border on invalid fields via `InputDecoration.enabledBorder` / `errorBorder`. Red error text below fields |
| Error handling | `login_screen.dart` | Map all `FirebaseAuthException` codes to inline red error messages |
| Smooth transition | `login_screen.dart` | On success → `widget.onLoginSuccess()` with fade animation |

### Key Design Decisions
- Keep the toggle between Login/Sign Up as a tab-like switcher at top
- Both modes show email + password on same screen (sign-up adds a "Full Name" field above)
- Google Sign-In button remains at bottom
- Password visibility toggle stays
- All error states use `c.error` color from `AppColorsExtension`

---

## Phase 2: Home Screen Enhancement

### Current State
- [home_screen.dart](file:///home/bao/Downloads/SpeechUp/lib/screens/home_screen.dart) — 1272 lines
- Has `_streakDays` field but displays a basic streak pill
- No practice scheduling UI

### Changes Required

| Task | File | Description |
|------|------|-------------|
| Streak Widget | `home_screen.dart` | Animated flame icon with streak count, daily checkmark calendar row |
| Practice Scheduler | `home_screen.dart` + `notification_service.dart` | Time picker to set daily practice reminder. Store time in SharedPreferences |
| Scheduler Notifications | `notification_service.dart` | Add `scheduleAtUserTime(TimeOfDay time)` — fires 5 min before set time |

### Streak Component Design
- Flame icon (`Icons.local_fire_department_rounded`) with animated glow
- Shows `X ngày` streak count
- 7-day row of circles showing which days had activity
- Uses `c.accentPurple` / `c.streakPillBg` from theme

### Scheduler Design  
- "Lên lịch luyện tập" card with clock icon
- Tap to open `showTimePicker` → save to `SharedPreferences`
- Display selected time or "Chưa đặt lịch"
- Notification fires 5 min before selected time via `flutter_local_notifications`

---

## Phase 3: Practice & Speech Integration

### Current State
- [practice_screen.dart](file:///home/bao/Downloads/SpeechUp/lib/screens/practice_screen.dart) — 1236 lines (recording UI)
- [speech_input_service.dart](file:///home/bao/Downloads/SpeechUp/lib/services/speech_input_service.dart) — Google STT via `speech_to_text`
- [analysis_screen.dart](file:///home/bao/Downloads/SpeechUp/lib/screens/analysis_screen.dart) — basic metrics
- `WaveformWidget` exists in [shared_widgets.dart](file:///home/bao/Downloads/SpeechUp/lib/widgets/shared_widgets.dart) but uses random data

### Changes Required

| Task | File | Description |
|------|------|-------------|
| Real-time waveform | `shared_widgets.dart` | Connect `WaveformWidget` amplitudes to `SpeechInputService.soundLevel` |
| Azure Pronunciation API | New: `azure_pronunciation_service.dart` | POST to Azure Speech SDK REST endpoint for pronunciation assessment |
| Result Card | `analysis_screen.dart` | Display Accuracy, Fluency, Completeness scores from Azure response |
| Save session | `practice_screen.dart` → `firestore_service.dart` | Persist Azure scores to Firestore `practice_sessions` collection |

### Azure Integration Architecture
```
User speaks → SpeechInputService (STT transcript)
            → AudioRecorder (raw WAV/PCM bytes)
            → AzurePronunciationService.assess(audioBytes, referenceText)
            → Returns { accuracy, fluency, completeness, prosody }
            → Display in AnalysisScreen result card
```

### New Service: `azure_pronunciation_service.dart`
- API key from `--dart-define=AZURE_SPEECH_KEY`
- Region from `--dart-define=AZURE_SPEECH_REGION`
- Endpoint: `https://{region}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1`
- Returns structured `PronunciationResult` model

---

## Phase 4: Chat Screen — LLM Roleplay & TTS

### Current State
- [conversation_screen.dart](file:///home/bao/Downloads/SpeechUp/lib/screens/conversation_screen.dart) — 1226 lines
- Uses static `_conversationFlows` with scripted turns
- TTS via [google_tts_service.dart](file:///home/bao/Downloads/SpeechUp/lib/services/google_tts_service.dart) already works
- Voice settings sheet already exists

### Changes Required

| Task | File | Description |
|------|------|-------------|
| Featured Scenario Cards | `conversation_screen.dart` | Replace plain list with visual cards (Shopping, Interview, Doctor, etc.) |
| Custom Scenario Input | `conversation_screen.dart` | TextField for user-defined scenario → passes as system prompt |
| LLM Integration | New: `llm_chat_service.dart` | Gemini API integration for dynamic responses |
| Conversation Summary | `conversation_screen.dart` | End-of-session summary card with "Communication Effectiveness" score |
| TTS Playback | Already exists | Continue using `GoogleTtsService` for AI response playback |

### LLM Service Architecture
- Uses Gemini API (`generativelanguage.googleapis.com`)
- API key from `--dart-define=GEMINI_API_KEY`
- System prompt: roleplay persona + scenario context + stuttering-supportive instructions
- Maintains conversation history for context
- Returns response text → TTS synthesis → audio playback

### Scenario Cards Design
- Grid of 2×2 cards with icons + gradient backgrounds
- Pre-defined: 🛒 Shopping, 💼 Interview, 🏥 Doctor Visit, 📞 Phone Call
- Custom scenario: text field at bottom with "Bắt đầu" button

---

## Phase 5: Progress & Curriculum

### Current State
- [progress_screen.dart](file:///home/bao/Downloads/SpeechUp/lib/screens/progress_screen.dart) — 1492 lines
- Has weekly score bars (custom painted, not `fl_chart`)
- `fl_chart` is already in `pubspec.yaml` but unused
- No curriculum/course structure

### Changes Required

| Task | File | Description |
|------|------|-------------|
| fl_chart Integration | `progress_screen.dart` | Replace custom bar chart with `fl_chart` `LineChart` for fluency over time |
| Enhanced Stats | `progress_screen.dart` | Add pronunciation trend, total practice hours, best streak |
| Curriculum Model | New: `course_curriculum.dart` | Define lessons, modules, completion tracking |
| Curriculum UI | `progress_screen.dart` | Expandable module list with lesson completion percentage |

### Curriculum Structure
```
Module 1: Foundations
  ├── Lesson 1.1: Breathing Exercises (Read Aloud)
  ├── Lesson 1.2: Slow Speech Practice
  └── Lesson 1.3: Word Repetition

Module 2: Fluency Building
  ├── Lesson 2.1: Sentence Shadowing
  ├── Lesson 2.2: Paragraph Reading
  └── Lesson 2.3: Conversation Starters

Module 3: Confidence
  ├── Lesson 3.1: Self-Introduction
  ├── Lesson 3.2: Phone Conversations
  └── Lesson 3.3: Public Speaking Basics
```

### Chart Design
- `LineChart` with gradient fill underneath
- X-axis: days of week / month
- Y-axis: fluency score 0–100
- Interactive touch: show exact score on tap
- Uses `c.accentBlue` for line, `c.accentBlue.withOpacity(0.1)` for fill

---

## File Impact Summary

| File | Phase | Action |
|------|-------|--------|
| `lib/screens/login_screen.dart` | 1 | Major refactor |
| `lib/screens/home_screen.dart` | 2 | Add streak + scheduler |
| `lib/services/notification_service.dart` | 2 | Add custom time scheduling |
| `lib/widgets/shared_widgets.dart` | 3 | Connect waveform to real data |
| `lib/services/azure_pronunciation_service.dart` | 3 | **New file** |
| `lib/models/pronunciation_result.dart` | 3 | **New file** |
| `lib/screens/analysis_screen.dart` | 3 | Update with Azure scores |
| `lib/screens/practice_screen.dart` | 3 | Wire Azure service |
| `lib/services/llm_chat_service.dart` | 4 | **New file** |
| `lib/screens/conversation_screen.dart` | 4 | Major refactor |
| `lib/models/course_curriculum.dart` | 5 | **New file** |
| `lib/screens/progress_screen.dart` | 5 | Add fl_chart + curriculum |

---

## Execution Order

> [!TIP]
> Each phase should be implemented, tested, and reviewed before moving to the next. Phase 1 is the foundation that unblocks all other phases.

1. **Phase 1** → Auth refactor (unblocks user flow)
2. **Phase 2** → Home enhancements (independent, low risk)
3. **Phase 3** → Azure integration (requires API key testing)
4. **Phase 4** → LLM chat (requires Gemini API key)
5. **Phase 5** → Progress & curriculum (builds on data from phases 3-4)

> [!NOTE]
> All new UI elements strictly use `AppColorsExtension` and `GoogleFonts.plusJakartaSans()` to maintain design system consistency.
