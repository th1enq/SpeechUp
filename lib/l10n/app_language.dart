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
      'nav.challenge': 'Challenge',
      'nav.learn': 'Learn',
      'nav.chat': 'Chat',
      'nav.progress': 'Progress',
      'nav.profile': 'Profile',
      'onboarding.skip': 'Skip',
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
      'profile.accountSettings': 'Account Settings',
      'profile.language': 'Language',
      'profile.speechDifficulty': 'Speech Difficulty',
      'profile.notifications': 'Notifications',
      'profile.notificationsOn': 'On • 8:00 PM Daily',
      'profile.notificationsOff': 'Off',
      'profile.logout': 'Log Out',
      'profile.selectLanguage': 'Select language',
      'profile.selectDifficulty': 'Speech difficulty',
      'profile.totalSessions': 'Total Sessions',
      'profile.speakingTime': 'Speaking Time',
      'profile.averageScore': 'Average Score',
      'profile.dayPracticeSuffix': 'day practice streak',
      'profile.firebaseOnlyLogout':
          'Logout is only available on Firebase-supported platforms.',
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
      'nav.challenge': 'Thử thách',
      'nav.learn': 'Học',
      'nav.chat': 'Trò chuyện',
      'nav.progress': 'Tiến độ',
      'nav.profile': 'Hồ sơ',
      'onboarding.skip': 'Bỏ qua',
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
      'profile.accountSettings': 'Cài đặt tài khoản',
      'profile.language': 'Ngôn ngữ',
      'profile.speechDifficulty': 'Độ khó luyện nói',
      'profile.notifications': 'Thông báo',
      'profile.notificationsOn': 'Bật • 8:00 tối mỗi ngày',
      'profile.notificationsOff': 'Tắt',
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
