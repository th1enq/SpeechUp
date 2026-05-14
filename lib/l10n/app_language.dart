import 'package:flutter/material.dart';

class AppLanguage extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  static const Map<String, Locale> languageDisplayToLocale = {
    'English (US)': Locale('en'),
    'Tiếng Việt': Locale('vi'),
  };

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app.title': 'SpeechUp',
      'common.today': 'Today',
      'common.yesterday': 'Yesterday',
      'common.monday': 'Monday',
      'common.viewAll': 'View All',
      'common.start': 'Start',
      'common.stop': 'Stop',
      'common.cancel': 'Cancel',
      'common.close': 'Close',
      'nav.home': 'Home',
      'nav.practice': 'Practice',
      'nav.chat': 'Chat',
      'nav.social': 'Social',
      'nav.progress': 'Progress',
      'nav.profile': 'Profile',
      'chat.title': 'AI Conversation',
      'chat.subtitle': 'Choose a scenario to start practicing.',
      'onboarding.skip': 'Skip',
      'onboarding.welcomeHeadline':
          'Practice speaking every day in just a few minutes.',
      'onboarding.startLearning': 'Start learning',
      'onboarding.alreadyHaveAccount': 'Already have an account?',
      'onboarding.logIn': 'Log in',
      'login.hello': 'Hello!',
      'login.signUpHeadline': 'Sign up and start improving your speaking.',
      'login.signInHeadline': 'Sign in to continue practicing.',
      'login.emailLabel': 'Email',
      'login.signInWithPhone': 'Sign in with phone number',
      'login.emailHint': 'user@gmail.com',
      'login.continue': 'Continue',
      'login.or': 'or',
      'login.google': 'Continue with Google',
      'login.termsJoin':
          'By joining, I declare that I have read and accept the ',
      'login.termsLink': 'Terms',
      'login.termsAnd': ' and ',
      'login.privacyLink': 'Privacy Policy',
      'login.termsEnd': '.',
      'login.haveAccount': 'Already have an account?',
      'login.logIn': 'Log in',
      'login.noAccount': 'Don\'t have an account?',
      'login.signUp': 'Sign up',
      'login.phoneSoon': 'Phone sign-in is not available yet.',
      'login.password': 'Password',
      'login.fullName': 'Full name',
      'login.signIn': 'Sign in',
      'login.createAccount': 'Create account',
      'login.forgotPassword': 'Forgot password?',
      'login.valEmail': 'Please enter your email.',
      'login.valEmailInvalid': 'Invalid email.',
      'login.valPassword': 'Please enter your password.',
      'login.valPasswordShort': 'Password must be at least 6 characters.',
      'login.valName': 'Please enter your name.',
      'login.resetTitle': 'Reset password',
      'login.resetHint': 'Enter your email to receive a reset link.',
      'login.resetSubmit': 'Send email',
      'login.resetSent': 'Password reset email sent!',
      'signup.createPasswordTitle': 'Create password',
      'signup.passwordHint': 'Enter your password',
      'signup.passwordHelperBefore': 'Your password must contain ',
      'signup.passwordHelperBold': '8 characters, 1 uppercase and 1 number.',
      'signup.usernameTitle': 'Create your User Name',
      'signup.usernameLabel': 'User Name',
      'signup.usernameHint': 'username001',
      'signup.usernameHelper':
          'Use letters, numbers, underscores and dashes (3–20 characters).',
      'signup.languageTitle': 'Choose the language you want to use.',
      'signup.langEnglish': 'English',
      'signup.langVietnamese': 'Vietnamese',
      'signup.purposeTitle': 'What is your main goal with SpeechUp?',
      'signup.purpose.clarity': 'Clearer, easier-to-understand speech',
      'signup.purpose.fluency': 'More fluent, natural pacing',
      'signup.purpose.confidence': 'Confidence speaking in front of others',
      'signup.purpose.professional': 'Professional & work communication',
      'signup.purpose.habit': 'Build a daily speaking habit',
      'signup.valPasswordStrong':
          'Use at least 8 characters with 1 uppercase letter and 1 number.',
      'signup.valUsername': '3–20 characters: letters, numbers, _ and - only.',
      'signup.valPickLanguage': 'Please choose a language.',
      'signup.valPickPurpose': 'Please choose a goal.',
      'signup.valPickPurposes': 'Choose at least one goal.',
      'signup.emailAlreadyRegistered':
          'This email is already registered. Sign in or use another email.',
      'signup.emailAvailable': 'This email can be used to register.',
      'login.checkingEmail': 'Checking email…',
      'signup.purposeMultiHint': 'You can select more than one.',
      'login.emailNotRegistered':
          'No account found for this email. Sign up or check the address.',
      'login.useGoogleInstead':
          'This email uses Google sign-in. Continue with Google.',
      'onboarding.improveYour': 'Improve Your',
      'onboarding.speaking': 'Speaking',
      'onboarding.subtitle1':
          'SpeechUp helps you practice speaking and analyze your voice with AI.',
      'onboarding.trackProgress': 'Track Your Progress',
      'onboarding.subtitle2': 'See how your speech improves over time.',
      'onboarding.termsPrefix': 'By continuing, you agree to our',
      'onboarding.terms': 'Terms of Service',
      'onboarding.and': 'and',
      'onboarding.privacy': 'Privacy Policy',
      'onboarding.next': 'Next',
      'onboarding.getStarted': 'Get Started',
      'onboarding.liveAnalysis': 'LIVE ANALYSIS',
      'onboarding.clarityAchieved': '98% Clarity Achieved',
      'home.greeting': 'Hello, {name}',
      'home.subtitle': 'Let\'s practice speaking today',
      'home.startPractice': 'Start Speaking Practice',
      'home.startPracticeHint': 'Tap to start recording your speech.',
      'home.dailyScore': 'Daily Speech Score',
      'home.fluency': 'Fluency',
      'home.pronunciation': 'Pronunciation',
      'home.speechSpeed': 'Speech Speed',
      'home.recentPractice': 'Recent Practice',
      'home.sessions': '{count} sessions',
      'home.score': 'SCORE',
      'practice.title': 'Practice',
      'practice.subtitle':
          'Choose an exercise to strengthen your speech foundation.',
      'practice.readTitle': 'Read a sentence',
      'practice.readBody': 'Today is a beautiful day.',
      'practice.shadowingTitle': 'Shadowing exercise',
      'practice.shadowingBody':
          'Listen to audio and repeat it perfectly to match the rhythm.',
      'practice.slowTitle': 'Slow speech training',
      'practice.slowBody':
          'Practice speaking at a controlled, deliberate pace for clarity.',
      'practice.easy': 'EASY',
      'practice.medium': 'MEDIUM',
      'practice.hard': 'HARD',
      'practice.weeklyStreak': 'Weekly Streak: 5 Days',
      'practice.weeklyStreakHint':
          'Keep practicing to reach your clarity goal by Friday!',
      'practice.recordingSession': 'RECORDING SESSION',
      'practice.listening': 'Listening to you...',
      'practice.metricSpeed': 'SPEECH SPEED',
      'practice.metricPauses': 'PAUSES',
      'practice.metricClarity': 'CLARITY',
      'practice.normal': 'Normal',
      'practice.none': 'None',
      'practice.high': 'High',
      'practice.stopRecording': 'Stop Recording',
      'practice.tapToStart': 'Tap the microphone to start listening.',
      'practice.liveTranscript': 'Live transcript',
      'practice.analyzing': 'Analyzing your speech...',
      'practice.permissionDenied':
          'Microphone permission or speech recognition is unavailable.',
      'practice.recognizerUnavailable':
          'This device does not have a speech recognition service. On Android emulators, use a Google Play or Google APIs image and enable the Google app / Speech Services.',
      'practice.unsupportedPlatform':
          'Real microphone input currently works on Android and iOS only.',
      'practice.noSpeechDetected':
          'No speech was detected. Try again and speak a little closer to the microphone.',
      'progress.title': 'My Journey',
      'progress.monthlyMinutes':
          'You\'ve spoken for {minutes} minutes this month. Keep it up!',
      'progress.weekly': 'Weekly',
      'progress.monthly': 'Monthly',
      'progress.milestones': 'Milestones',
      'progress.milestoneStreak': '7-day practice streak',
      'progress.milestoneFluency': 'Improved fluency',
      'progress.milestoneHour': '1 hour practice',
      'progress.aiRecommendation': 'AI Recommendation',
      'progress.aiRecommendationBody':
          'Your pronunciation of \'S\' sounds has improved by 20% this week. Focus on vocal resonance next!',
      'progress.speechSpeedTrend': 'Speech Speed Trend',
      'progress.averageSpeed': 'Average Speed',
      'progress.speedTarget':
          'Your target is 130–150 words per minute for clear professional delivery.',
      'progress.steadyGrowth': 'Steady Growth',
      'progress.fluencyScore': 'FLUENCY SCORE',
      'progress.pronunciation': 'PRONUNCIATION',
      'progress.wpm': 'wpm',
      'profile.screenTitle': 'Profile',
      'profile.friends': 'Friends',
      'profile.tabProgress': 'Progress',
      'profile.tabPractice': 'Exercises',
      'profile.tabInsights': 'Corrections',
      'profile.languageLine': 'App language',
      'profile.speakingProgressLabel': 'Speaking progress',
      'profile.sessionsPracticed': 'Sessions practiced',
      'profile.milestones': 'Milestones',
      'profile.studyDays': 'Study days',
      'profile.activeDays': '{n} active days',
      'profile.highlights': 'Highlights',
      'profile.highlightSessions': '{n} sessions',
      'profile.highlightStreak': '{n} day streak',
      'profile.highlightScore': '{n} avg score',
      'profile.exercisesTabBody':
          'Open Practice to start exercises and build your streak.',
      'profile.insightsTabBody':
          'Insights about pronunciation and fluency update as you record.',
      'profile.learnerSubtitle': 'SpeechUp learner',
      'profile.settingsSheetTitle': 'Settings',
      'profile.accountSettings': 'Account Settings',
      'profile.language': 'Language',
      'profile.speechDifficulty': 'Speech Difficulty',
      'profile.notifications': 'Notifications',
      'profile.notificationsOn': 'On • 8:00 PM Daily',
      'profile.notificationsOff': 'Off',
      'profile.theme': 'Theme',
      'profile.themeOn': 'Dark Mode',
      'profile.themeOff': 'Light Mode',
      'profile.logout': 'Log Out',
      'profile.selectLanguage': 'Select language',
      'profile.selectDifficulty': 'Speech difficulty',
      'profile.totalSessions': 'Total Sessions',
      'profile.speakingTime': 'Speaking Time',
      'profile.averageScore': 'Average Score',
      'profile.dayPracticeSuffix': 'day practice streak',
      'profile.firebaseOnlyLogout':
          'Logout is only available on Firebase-supported platforms.',
      'home.appName': 'SpeechUp',
      'home.dailyGoal': 'Daily Goal',
      'home.minsSpokenToday': '{current}/{goal} mins spoken today',
      'home.keepItUp': 'Keep it up',
      'home.featureAiTalk': 'AI Talk',
      'home.featureTopicPractice': 'Topic Practice',
      'home.featureIeltsPrep': 'IELTS Prep',
      'home.featureVocabulary': 'Vocabulary',
      'home.featureGuidedSpeaking': 'Guided Speaking',
      'home.featureDailyScenarios': 'Daily Scenarios',
      'home.learningPath': 'Learning Path',
      'home.todaysLessonTag': 'TODAY\'S LESSON',
      'home.todaysLessonTitle': 'Building Confidence',
      'home.lessonMeta': '{mins} mins',
      'home.startSession': 'Start Session',
      'home.tomorrowTitle': 'Tomorrow: Quick Review',
      'home.lockedUntilTomorrow': 'Locked until tomorrow',
      'home.recommendedTopics': 'Recommended Topics',
      'home.topicTravel': 'Travel',
      'home.topicWork': 'Work',
      'home.topicTravelHint': 'Practice airport and hotel conversations',
      'home.topicWorkHint': 'Practice meetings and workplace communication',
    },
    'vi': {
      'app.title': 'SpeechUp',
      'common.today': 'Hôm nay',
      'common.yesterday': 'Hôm qua',
      'common.monday': 'Thứ hai',
      'common.viewAll': 'Xem tất cả',
      'common.start': 'Bắt đầu',
      'common.stop': 'Dừng',
      'common.cancel': 'Hủy',
      'common.close': 'Đóng',
      'nav.home': 'Trang chủ',
      'nav.practice': 'Luyện tập',
      'nav.chat': 'Chat',
      'nav.social': 'Bạn bè',
      'nav.progress': 'Tiến độ',
      'nav.profile': 'Hồ sơ',
      'chat.title': 'Hội thoại với AI',
      'chat.subtitle': 'Chọn tình huống để bắt đầu luyện tập.',
      'onboarding.alreadyHaveAccount': 'Đã có tài khoản?',
      'onboarding.logIn': 'Đăng nhập',
      'login.hello': 'Xin chào!',
      'login.signUpHeadline': 'Đăng ký và bắt đầu luyện nói hiệu quả hơn.',
      'login.signInHeadline': 'Đăng nhập để tiếp tục luyện tập.',
      'login.emailLabel': 'Email',
      'login.signInWithPhone': 'Đăng nhập bằng số điện thoại',
      'login.emailHint': 'ban@gmail.com',
      'login.continue': 'Tiếp tục',
      'login.or': 'hoặc',
      'login.google': 'Tiếp tục với Google',
      'login.termsJoin': 'Khi tham gia, tôi xác nhận đã đọc và đồng ý ',
      'login.termsLink': 'Điều khoản',
      'login.termsAnd': ' và ',
      'login.privacyLink': 'Chính sách quyền riêng tư',
      'login.termsEnd': '.',
      'login.haveAccount': 'Đã có tài khoản?',
      'login.logIn': 'Đăng nhập',
      'login.noAccount': 'Chưa có tài khoản?',
      'login.signUp': 'Đăng ký',
      'login.phoneSoon': 'Đăng nhập bằng điện thoại chưa được hỗ trợ.',
      'login.password': 'Mật khẩu',
      'login.fullName': 'Họ và tên',
      'login.signIn': 'Đăng nhập',
      'login.createAccount': 'Tạo tài khoản',
      'login.forgotPassword': 'Quên mật khẩu?',
      'login.valEmail': 'Vui lòng nhập email.',
      'login.valEmailInvalid': 'Email không hợp lệ.',
      'login.valPassword': 'Vui lòng nhập mật khẩu.',
      'login.valPasswordShort': 'Mật khẩu ít nhất 6 ký tự.',
      'login.valName': 'Vui lòng nhập họ tên.',
      'login.resetTitle': 'Đặt lại mật khẩu',
      'login.resetHint': 'Nhập email để nhận liên kết đặt lại mật khẩu.',
      'login.resetSubmit': 'Gửi email',
      'login.resetSent': 'Đã gửi email đặt lại mật khẩu!',
      'signup.createPasswordTitle': 'Tạo mật khẩu',
      'signup.passwordHint': 'Nhập mật khẩu',
      'signup.passwordHelperBefore': 'Mật khẩu cần có ',
      'signup.passwordHelperBold': 'ít nhất 8 ký tự, 1 chữ hoa và 1 chữ số.',
      'signup.usernameTitle': 'Tạo tên người dùng',
      'signup.usernameLabel': 'Tên người dùng',
      'signup.usernameHint': 'ten_nguoi_dung',
      'signup.usernameHelper':
          'Dùng chữ, số, gạch dưới và gạch ngang (3–20 ký tự).',
      'signup.languageTitle': 'Chọn ngôn ngữ bạn muốn dùng.',
      'signup.langEnglish': 'Tiếng Anh',
      'signup.langVietnamese': 'Tiếng Việt',
      'signup.purposeTitle': 'Mục tiêu chính của bạn với SpeechUp?',
      'signup.purpose.clarity': 'Nói rõ ràng, dễ hiểu hơn',
      'signup.purpose.fluency': 'Nói trôi chảy, nhịp điệu tự nhiên hơn',
      'signup.purpose.confidence': 'Tự tin nói trước người khác',
      'signup.purpose.professional': 'Giao tiếp công việc chuyên nghiệp',
      'signup.purpose.habit': 'Duy trì thói quen luyện nói mỗi ngày',
      'signup.valPasswordStrong':
          'Cần ít nhất 8 ký tự, gồm 1 chữ hoa và 1 chữ số.',
      'signup.valUsername': '3–20 ký tự: chỉ chữ, số, _ và -.',
      'signup.valPickLanguage': 'Vui lòng chọn ngôn ngữ.',
      'signup.valPickPurpose': 'Vui lòng chọn mục tiêu.',
      'signup.valPickPurposes': 'Chọn ít nhất một mục tiêu.',
      'signup.emailAlreadyRegistered':
          'Email này đã được đăng ký. Hãy đăng nhập hoặc dùng email khác.',
      'signup.emailAvailable': 'Email này có thể dùng để đăng ký.',
      'login.checkingEmail': 'Đang kiểm tra email…',
      'signup.purposeMultiHint': 'Bạn có thể chọn nhiều mục tiêu.',
      'login.emailNotRegistered':
          'Không có tài khoản với email này. Hãy đăng ký hoặc kiểm tra lại.',
      'login.useGoogleInstead':
          'Email này đăng nhập bằng Google. Hãy dùng nút Tiếp tục với Google.',
      'onboarding.improveYour': 'Cải thiện',
      'onboarding.speaking': 'Kỹ năng nói',
      'onboarding.subtitle1':
          'SpeechUp giúp bạn luyện nói và phân tích giọng nói bằng AI.',
      'onboarding.trackProgress': 'Theo dõi tiến bộ',
      'onboarding.subtitle2':
          'Xem kỹ năng nói của bạn cải thiện theo thời gian.',
      'onboarding.termsPrefix': 'Khi tiếp tục, bạn đồng ý với',
      'onboarding.terms': 'Điều khoản dịch vụ',
      'onboarding.and': 'và',
      'onboarding.privacy': 'Chính sách quyền riêng tư',
      'onboarding.next': 'Tiếp theo',
      'onboarding.getStarted': 'Bắt đầu',
      'onboarding.liveAnalysis': 'PHÂN TÍCH TRỰC TIẾP',
      'onboarding.clarityAchieved': 'Độ rõ đạt 98%',
      'home.greeting': 'Xin chào, {name}',
      'home.subtitle': 'Cùng luyện nói hôm nay nhé',
      'home.startPractice': 'Bắt đầu luyện nói',
      'home.startPracticeHint': 'Nhấn để bắt đầu ghi âm bài nói của bạn.',
      'home.dailyScore': 'Điểm nói hôm nay',
      'home.fluency': 'Độ trôi chảy',
      'home.pronunciation': 'Phát âm',
      'home.speechSpeed': 'Tốc độ nói',
      'home.recentPractice': 'Luyện tập gần đây',
      'home.sessions': '{count} buổi',
      'home.score': 'ĐIỂM',
      'practice.title': 'Luyện tập',
      'practice.subtitle':
          'Chọn bài tập để cải thiện nền tảng kỹ năng nói của bạn.',
      'practice.readTitle': 'Đọc một câu',
      'practice.readBody': 'Hôm nay là một ngày đẹp trời.',
      'practice.shadowingTitle': 'Bài tập shadowing',
      'practice.shadowingBody':
          'Nghe audio và lặp lại thật chính xác để bắt nhịp điệu.',
      'practice.slowTitle': 'Luyện nói chậm',
      'practice.slowBody':
          'Luyện nói với tốc độ có kiểm soát để tăng độ rõ ràng.',
      'practice.easy': 'DỄ',
      'practice.medium': 'TRUNG BÌNH',
      'practice.hard': 'KHÓ',
      'practice.weeklyStreak': 'Chuỗi tuần: 5 ngày',
      'practice.weeklyStreakHint':
          'Tiếp tục luyện tập để đạt mục tiêu rõ ràng trước thứ Sáu!',
      'practice.recordingSession': 'PHIÊN GHI ÂM',
      'practice.listening': 'Đang lắng nghe bạn...',
      'practice.metricSpeed': 'TỐC ĐỘ NÓI',
      'practice.metricPauses': 'NGẮT NHỊP',
      'practice.metricClarity': 'ĐỘ RÕ',
      'practice.normal': 'Bình thường',
      'practice.none': 'Không',
      'practice.high': 'Cao',
      'practice.stopRecording': 'Dừng ghi âm',
      'practice.tapToStart': 'Nhấn microphone để bắt đầu lắng nghe.',
      'practice.liveTranscript': 'Bản ghi trực tiếp',
      'practice.analyzing': 'Đang phân tích bài nói của bạn...',
      'practice.permissionDenied':
          'Không thể dùng microphone hoặc nhận dạng giọng nói trên thiết bị này.',
      'home.appName': 'SpeechUp',
      'home.dailyGoal': 'Mục tiêu ngày',
      'home.minsSpokenToday': '{current}/{goal} phút đã nói hôm nay',
      'home.keepItUp': 'Cố gắng nhé',
      'home.featureAiTalk': 'Trò chuyện AI',
      'home.featureTopicPractice': 'Luyện theo chủ đề',
      'home.featureIeltsPrep': 'Luyện IELTS',
      'home.featureVocabulary': 'Từ vựng',
      'home.featureGuidedSpeaking': 'Luyện nói có hướng dẫn',
      'home.featureDailyScenarios': 'Tình huống hằng ngày',
      'home.learningPath': 'Lộ trình học',
      'home.todaysLessonTag': 'BÀI HÔM NAY',
      'home.todaysLessonTitle': 'Tăng tự tin',
      'home.lessonMeta': '{mins} phút',
      'home.startSession': 'Bắt đầu',
      'home.tomorrowTitle': 'Ngày mai: Ôn nhanh',
      'home.lockedUntilTomorrow': 'Khóa đến ngày mai',
      'home.recommendedTopics': 'Chủ đề gợi ý',
      'home.topicTravel': 'Du lịch',
      'home.topicWork': 'Công việc',
      'home.topicTravelHint': 'Luyện hội thoại sân bay, khách sạn',
      'home.topicWorkHint': 'Luyện giao tiếp họp nhóm và công sở',
      'practice.recognizerUnavailable':
          'Thiết bị này không có dịch vụ nhận dạng giọng nói. Nếu dùng Android Emulator, hãy dùng image Google Play hoặc Google APIs và bật ứng dụng Google / Speech Services.',
      'practice.unsupportedPlatform':
          'Microphone thật hiện chỉ hoạt động trên Android và iOS.',
      'practice.noSpeechDetected':
          'Chưa ghi nhận được lời nói. Hãy thử lại và nói gần microphone hơn.',
      'progress.title': 'Hành trình của tôi',
      'progress.monthlyMinutes':
          'Bạn đã luyện nói {minutes} phút trong tháng này. Cố gắng nhé!',
      'progress.weekly': 'Tuần',
      'progress.monthly': 'Tháng',
      'progress.milestones': 'Cột mốc',
      'progress.milestoneStreak': 'Chuỗi luyện 7 ngày',
      'progress.milestoneFluency': 'Cải thiện độ trôi chảy',
      'progress.milestoneHour': '1 giờ luyện tập',
      'progress.aiRecommendation': 'Gợi ý từ AI',
      'progress.aiRecommendationBody':
          'Phát âm âm \'S\' của bạn đã cải thiện 20% tuần này. Hãy tập trung thêm vào cộng hưởng giọng nói nhé!',
      'progress.speechSpeedTrend': 'Xu hướng tốc độ nói',
      'progress.averageSpeed': 'Tốc độ trung bình',
      'progress.speedTarget':
          'Mục tiêu là 130–150 từ/phút để truyền đạt chuyên nghiệp và rõ ràng.',
      'progress.steadyGrowth': 'Tiến bộ ổn định',
      'progress.fluencyScore': 'ĐIỂM TRÔI CHẢY',
      'progress.pronunciation': 'PHÁT ÂM',
      'progress.wpm': 'từ/phút',
      'profile.screenTitle': 'Hồ sơ',
      'profile.friends': 'Bạn bè',
      'profile.tabProgress': 'Tiến độ',
      'profile.tabPractice': 'Bài tập',
      'profile.tabInsights': 'Chữa lỗi',
      'profile.languageLine': 'Ngôn ngữ ứng dụng',
      'profile.speakingProgressLabel': 'Tiến độ luyện nói',
      'profile.sessionsPracticed': 'Buổi đã luyện',
      'profile.milestones': 'Mốc',
      'profile.studyDays': 'Ngày luyện',
      'profile.activeDays': '{n} ngày hoạt động',
      'profile.highlights': 'Thành tích',
      'profile.highlightSessions': '{n} buổi',
      'profile.highlightStreak': '{n} ngày liên tiếp',
      'profile.highlightScore': '{n} điểm TB',
      'profile.exercisesTabBody': 'Mở Luyện tập để làm bài và giữ chuỗi ngày.',
      'profile.insightsTabBody':
          'Phản hồi phát âm và độ trôi chảy cập nhật khi bạn ghi âm.',
      'profile.learnerSubtitle': 'Người học SpeechUp',
      'profile.settingsSheetTitle': 'Cài đặt',
      'profile.accountSettings': 'Cài đặt tài khoản',
      'profile.language': 'Ngôn ngữ',
      'profile.speechDifficulty': 'Độ khó luyện nói',
      'profile.notifications': 'Thông báo',
      'profile.notificationsOn': 'Bật • 8:00 tối mỗi ngày',
      'profile.notificationsOff': 'Tắt',
      'profile.theme': 'Giao diện',
      'profile.themeOn': 'Nền tối',
      'profile.themeOff': 'Nền sáng',
      'profile.logout': 'Đăng xuất',
      'profile.selectLanguage': 'Chọn ngôn ngữ',
      'profile.selectDifficulty': 'Độ khó luyện nói',
      'profile.totalSessions': 'Tổng buổi luyện',
      'profile.speakingTime': 'Thời gian nói',
      'profile.averageScore': 'Điểm trung bình',
      'profile.dayPracticeSuffix': 'ngày luyện liên tiếp',
      'profile.firebaseOnlyLogout':
          'Đăng xuất chỉ khả dụng trên nền tảng hỗ trợ Firebase.',
    },
  };

  List<String> get supportedLanguageDisplayNames =>
      languageDisplayToLocale.keys.toList();

  String get currentLanguageDisplayName =>
      localeToDisplayName(_locale) ?? 'English (US)';

  String get speechLocaleId => _locale.languageCode == 'vi' ? 'vi_VN' : 'en_US';

  String get speechLanguageCode =>
      _locale.languageCode == 'vi' ? 'vi-VN' : 'en-US';

  String get practiceLanguageName =>
      _locale.languageCode == 'vi' ? 'tiếng Việt' : 'English';

  List<String> get weekdayShortLabels => _locale.languageCode == 'vi'
      ? const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
      : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  List<String> get weekdayNarrowLabels => _locale.languageCode == 'vi'
      ? const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
      : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void setByDisplayName(String displayName) {
    setLocale(languageDisplayToLocale[displayName] ?? const Locale('en'));
  }

  String? localeToDisplayName(Locale locale) {
    for (final entry in languageDisplayToLocale.entries) {
      final value = entry.value;
      if (value.languageCode == locale.languageCode &&
          (value.countryCode ?? '') == (locale.countryCode ?? '')) {
        return entry.key;
      }
    }
    if (locale.languageCode == 'vi') return 'Tiếng Việt';
    return 'English (US)';
  }

  String t(String key, {Map<String, String>? params}) {
    final lang = _locale.languageCode;
    String value =
        _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
    if (params != null && params.isNotEmpty) {
      params.forEach((paramKey, paramValue) {
        value = value.replaceAll('{$paramKey}', paramValue);
      });
    }
    return value;
  }

  String dayPracticeStreak(int days) {
    return '$days ${t('profile.dayPracticeSuffix')}';
  }
}

final appLanguage = AppLanguage();
