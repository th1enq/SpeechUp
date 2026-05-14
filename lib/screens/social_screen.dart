import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';

import '../l10n/app_language.dart';
import '../main.dart' show isFirebaseSupported;
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../widgets/shared_widgets.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  UserProfile? _currentProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    if (!isFirebaseSupported) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    var profile = await _firestoreService.getUserProfile(user.uid);
    if (profile == null) {
      profile = UserProfile(
        uid: user.uid,
        displayName: _displayNameForAuthUser(user),
        email: user.email ?? '',
        createdAt: DateTime.now(),
      );
      try {
        await _firestoreService.createUserProfile(profile);
      } catch (e) {
        debugPrint('[Social] Failed to create missing user profile: $e');
      }
    }
    if (!mounted) return;
    setState(() {
      _currentProfile = profile;
      _isLoading = false;
    });
  }

  String _displayNameForAuthUser(User user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'SpeechUp user';
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentProfile;
    final vi = appLanguage.locale.languageCode == 'vi';
    final bottomPadding =
        kBottomNavigationBarHeight + MediaQuery.paddingOf(context).bottom + 20;

    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !isFirebaseSupported || current == null
          ? _SocialEmptyState(
              title: vi ? 'Cần đăng nhập' : 'Sign in required',
              message: vi
                  ? 'Đăng nhập để tìm bạn bè và trò chuyện bằng giọng nói.'
                  : 'Sign in to find friends and start voice conversations.',
            )
          : StreamBuilder<List<SocialConnection>>(
              stream: _firestoreService.streamSocialConnections(current.uid),
              builder: (context, connectionSnapshot) {
                if (connectionSnapshot.hasError) {
                  return _SocialEmptyState(
                    title: vi
                        ? 'Chưa có quyền đọc Social'
                        : 'Social access denied',
                    message: vi
                        ? 'Firestore Rules đang chặn collection social_connections. Hãy cập nhật rules để user đã đăng nhập đọc các kết nối có chứa UID của mình.'
                        : 'Firestore Rules are blocking social_connections. Update rules so signed-in users can read connections that include their UID.',
                  );
                }
                final connections = connectionSnapshot.data ?? const [];
                final byOtherUser = <String, SocialConnection>{
                  for (final connection in connections)
                    if (connection.otherUserId(current.uid).isNotEmpty)
                      connection.otherUserId(current.uid): connection,
                };
                final friends = connections
                    .where((connection) => connection.isAccepted)
                    .toList();
                final incoming = connections
                    .where(
                      (connection) => connection.isIncomingFor(current.uid),
                    )
                    .toList();

                return StreamBuilder<List<UserProfile>>(
                  stream: _firestoreService.streamSocialUsers(current.uid),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.hasError) {
                      return _SocialEmptyState(
                        title: vi
                            ? 'Chưa có quyền đọc người dùng'
                            : 'User list access denied',
                        message: vi
                            ? 'Firestore Rules đang chặn collection users. Hãy cho user đã đăng nhập đọc hồ sơ cơ bản để Social hiển thị danh sách SpeechUp users.'
                            : 'Firestore Rules are blocking users. Allow signed-in users to read basic profiles so Social can list SpeechUp users.',
                      );
                    }
                    final users = userSnapshot.data ?? const [];
                    final userById = {for (final user in users) user.uid: user};
                    final discoverable = users
                        .where(
                          (user) => byOtherUser[user.uid]?.isAccepted != true,
                        )
                        .toList();

                    return RefreshIndicator(
                      onRefresh: _loadCurrentProfile,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ScreenHeader(
                              title: vi ? 'Social' : 'Social',
                              subtitle: vi
                                  ? 'Kết nối bạn bè và luyện nói cùng nhau.'
                                  : 'Connect with friends and practice speaking together.',
                            ),
                            const SizedBox(height: 18),
                            _SocialHero(
                              friendCount: friends.length,
                              pendingCount: incoming.length,
                            ),
                            const SizedBox(height: 18),
                            if (incoming.isNotEmpty) ...[
                              _SectionTitle(
                                title: vi
                                    ? 'Lời mời kết nối'
                                    : 'Connection requests',
                              ),
                              const SizedBox(height: 10),
                              for (final request in incoming)
                                _IncomingRequestCard(
                                  connection: request,
                                  user: userById[request.requesterId],
                                  onAccept: () => _acceptRequest(request),
                                  onDecline: () => _declineRequest(request),
                                ),
                              const SizedBox(height: 16),
                            ],
                            _SectionTitle(title: vi ? 'Bạn bè' : 'Friends'),
                            const SizedBox(height: 10),
                            if (friends.isEmpty)
                              _InlineEmptyCard(
                                text: vi
                                    ? 'Chưa có kết nối nào. Gửi lời mời cho người dùng bên dưới.'
                                    : 'No friends yet. Send a request to someone below.',
                              )
                            else
                              for (final friendConnection in friends)
                                _FriendCard(
                                  user:
                                      userById[friendConnection.otherUserId(
                                        current.uid,
                                      )],
                                  connection: friendConnection,
                                  onOpenVoice: () => _openVoiceChat(
                                    friendConnection,
                                    userById[friendConnection.otherUserId(
                                      current.uid,
                                    )],
                                  ),
                                ),
                            const SizedBox(height: 18),
                            _SectionTitle(
                              title: vi
                                  ? 'Người dùng SpeechUp'
                                  : 'SpeechUp users',
                            ),
                            const SizedBox(height: 10),
                            if (discoverable.isEmpty)
                              _InlineEmptyCard(
                                text: vi
                                    ? 'Chưa tìm thấy người dùng khác.'
                                    : 'No other users found yet.',
                              )
                            else
                              for (final user in discoverable)
                                _DiscoverUserCard(
                                  user: user,
                                  connection: byOtherUser[user.uid],
                                  onSendRequest: () =>
                                      _sendRequest(current, user),
                                ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _sendRequest(UserProfile current, UserProfile receiver) async {
    await _firestoreService.sendConnectionRequest(
      requester: current,
      receiver: receiver,
    );
    if (!mounted) return;
    _showSnack(
      appLanguage.locale.languageCode == 'vi'
          ? 'Đã gửi lời mời kết nối.'
          : 'Connection request sent.',
    );
  }

  Future<void> _acceptRequest(SocialConnection connection) async {
    await _firestoreService.acceptConnectionRequest(connection.id);
    if (!mounted) return;
    _showSnack(
      appLanguage.locale.languageCode == 'vi'
          ? 'Đã chấp nhận kết nối.'
          : 'Connection accepted.',
    );
  }

  Future<void> _declineRequest(SocialConnection connection) async {
    await _firestoreService.declineConnectionRequest(connection.id);
  }

  void _openVoiceChat(SocialConnection connection, UserProfile? friend) {
    if (friend == null || _currentProfile == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SocialVoiceChatScreen(
          connection: connection,
          currentUser: _currentProfile!,
          friend: friend,
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class SocialVoiceChatScreen extends StatefulWidget {
  final SocialConnection connection;
  final UserProfile currentUser;
  final UserProfile friend;

  const SocialVoiceChatScreen({
    super.key,
    required this.connection,
    required this.currentUser,
    required this.friend,
  });

  @override
  State<SocialVoiceChatScreen> createState() => _SocialVoiceChatScreenState();
}

class _SocialVoiceChatScreenState extends State<SocialVoiceChatScreen> {
  static const int _maxVoiceBytes = 700 * 1024;

  final FirestoreService _firestoreService = FirestoreService();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _voicePlayer = AudioPlayer();
  bool _isSending = false;
  bool _isRecording = false;
  String? _recordingPath;
  DateTime? _recordingStartedAt;

  @override
  void dispose() {
    unawaited(_stopRecorderIfNeeded(deleteFile: true));
    _recorder.dispose();
    _voicePlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isSending) return;
    if (_isRecording) {
      await _stopAndSendVoice();
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appLanguage.locale.languageCode == 'vi'
                ? 'Chưa có quyền dùng microphone.'
                : 'Microphone permission is required.',
          ),
        ),
      );
      return;
    }

    final dir = Directory.systemTemp;
    final path =
        '${dir.path}/speechup_friend_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _recordingPath = path;
      _recordingStartedAt = DateTime.now();
    });
  }

  Future<void> _stopAndSendVoice() async {
    setState(() => _isSending = true);
    String? path;
    try {
      path = await _recorder.stop();
      final targetPath = path ?? _recordingPath;
      final durationMs = _recordingStartedAt == null
          ? 0
          : DateTime.now().difference(_recordingStartedAt!).inMilliseconds;
      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _recordingStartedAt = null;
      });

      if (targetPath == null || targetPath.isEmpty) return;
      final file = File(targetPath);
      if (!await file.exists()) return;
      final bytes = await file.readAsBytes();
      await file.delete().catchError((_) => file);
      if (bytes.length < 800) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLanguage.t('practice.noSpeechDetected'))),
        );
        return;
      }
      if (bytes.length > _maxVoiceBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appLanguage.locale.languageCode == 'vi'
                  ? 'Voice quá dài. Hãy ghi âm ngắn hơn khoảng 20 giây.'
                  : 'Voice message is too long. Keep it under about 20 seconds.',
            ),
          ),
        );
        return;
      }

      await _firestoreService.sendVoiceMessage(
        connectionId: widget.connection.id,
        senderId: widget.currentUser.uid,
        audioBase64: base64Encode(bytes),
        mimeType: 'audio/mp4',
        durationMs: durationMs,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _stopRecorderIfNeeded({required bool deleteFile}) async {
    try {
      if (await _recorder.isRecording()) {
        final path = await _recorder.stop();
        final targetPath = path ?? _recordingPath;
        if (deleteFile && targetPath != null && targetPath.isNotEmpty) {
          final file = File(targetPath);
          if (await file.exists()) {
            await file.delete().catchError((_) => file);
          }
        }
      }
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  Future<void> _playVoice(SocialVoiceMessage message) async {
    if (message.audioBase64.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appLanguage.locale.languageCode == 'vi'
                ? 'Tin nhắn voice không có audio.'
                : 'This voice message has no audio.',
          ),
        ),
      );
      return;
    }
    try {
      final bytes = base64Decode(message.audioBase64);
      await _voicePlayer.stop();
      await _voicePlayer.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('[Social] Failed to play voice message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();
    final vi = appLanguage.locale.languageCode == 'vi';

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.surfaceBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: c.textHeading),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            _Avatar(name: widget.friend.displayName, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.friend.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: base.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: c.textHeading,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<SocialVoiceMessage>>(
              stream: _firestoreService.streamVoiceMessages(
                widget.connection.id,
              ),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const [];
                if (messages.isEmpty) {
                  return _SocialEmptyState(
                    title: vi ? 'Bắt đầu voice chat' : 'Start voice chat',
                    message: vi
                        ? 'Nhấn micro, nói một câu, rồi gửi cho bạn của bạn.'
                        : 'Tap the mic, speak a sentence, then send it to your friend.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final mine = message.senderId == widget.currentUser.uid;
                    return _VoiceMessageBubble(
                      message: message,
                      mine: mine,
                      onPlay: () => _playVoice(message),
                    );
                  },
                );
              },
            ),
          ),
          if (_isRecording)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.accentBlue.withValues(alpha: 0.2)),
              ),
              child: Text(
                vi
                    ? 'Đang ghi âm voice. Nhấn micro để gửi.'
                    : 'Recording voice. Tap the mic to send.',
                style: base.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.textHeading,
                  height: 1.4,
                ),
              ),
            ),
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: c.surfaceBg,
              boxShadow: [
                BoxShadow(
                  color: c.shadowColor.withValues(alpha: 0.55),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isRecording
                      ? (vi ? 'Nhấn để gửi' : 'Tap to send')
                      : (vi ? 'Ghi âm voice' : 'Record voice'),
                  style: base.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(width: 16),
                MicButton(
                  isRecording: _isRecording,
                  onTap: _toggleRecording,
                  size: 64,
                ),
                if (_isSending) ...[
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialHero extends StatelessWidget {
  final int friendCount;
  final int pendingCount;

  const _SocialHero({required this.friendCount, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();
    final vi = appLanguage.locale.languageCode == 'vi';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: c.heroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: c.accentBlue.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.diversity_3_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vi ? 'Luyện nói cùng bạn bè' : 'Practice with friends',
                  style: base.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  vi
                      ? '$friendCount bạn bè • $pendingCount lời mời'
                      : '$friendCount friends • $pendingCount requests',
                  style: base.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: context.colors.textHeading,
      ),
    );
  }
}

class _DiscoverUserCard extends StatelessWidget {
  final UserProfile user;
  final SocialConnection? connection;
  final VoidCallback onSendRequest;

  const _DiscoverUserCard({
    required this.user,
    required this.connection,
    required this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    final vi = appLanguage.locale.languageCode == 'vi';
    final isPending = connection != null && !connection!.isAccepted;
    return _SocialCard(
      child: Row(
        children: [
          _Avatar(name: user.displayName),
          const SizedBox(width: 12),
          Expanded(child: _UserText(user: user)),
          FilledButton.icon(
            onPressed: isPending ? null : onSendRequest,
            icon: Icon(
              isPending
                  ? Icons.hourglass_top_rounded
                  : Icons.person_add_rounded,
            ),
            label: Text(
              isPending
                  ? (vi ? 'Đã gửi' : 'Pending')
                  : (vi ? 'Kết nối' : 'Connect'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  final SocialConnection connection;
  final UserProfile? user;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingRequestCard({
    required this.connection,
    required this.user,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final vi = appLanguage.locale.languageCode == 'vi';
    return _SocialCard(
      child: Row(
        children: [
          _Avatar(name: user?.displayName ?? connection.requesterId),
          const SizedBox(width: 12),
          Expanded(
            child: _UserText(
              user: user,
              fallbackName: connection.requesterId,
              subtitle: vi ? 'Muốn kết nối với bạn' : 'Wants to connect',
            ),
          ),
          IconButton(
            tooltip: vi ? 'Từ chối' : 'Decline',
            onPressed: onDecline,
            icon: const Icon(Icons.close_rounded, color: AppColors.error),
          ),
          IconButton(
            tooltip: vi ? 'Chấp nhận' : 'Accept',
            onPressed: onAccept,
            icon: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final UserProfile? user;
  final SocialConnection connection;
  final VoidCallback onOpenVoice;

  const _FriendCard({
    required this.user,
    required this.connection,
    required this.onOpenVoice,
  });

  @override
  Widget build(BuildContext context) {
    final vi = appLanguage.locale.languageCode == 'vi';
    return _SocialCard(
      child: Row(
        children: [
          _Avatar(name: user?.displayName ?? connection.id),
          const SizedBox(width: 12),
          Expanded(
            child: _UserText(user: user, fallbackName: connection.id),
          ),
          FilledButton.icon(
            onPressed: user == null ? null : onOpenVoice,
            icon: const Icon(Icons.keyboard_voice_rounded),
            label: Text(vi ? 'Voice' : 'Voice'),
          ),
        ],
      ),
    );
  }
}

class _VoiceMessageBubble extends StatelessWidget {
  final SocialVoiceMessage message;
  final bool mine;
  final VoidCallback onPlay;

  const _VoiceMessageBubble({
    required this.message,
    required this.mine,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();
    final color = mine ? c.accentBlue : c.cardBg;
    final vi = appLanguage.locale.languageCode == 'vi';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: mine ? color : c.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: mine
              ? null
              : Border.all(color: c.borderColor.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onPlay,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.play_arrow_rounded,
                color: mine ? Colors.white : c.accentBlue,
              ),
            ),
            Flexible(
              child: Text(
                _durationLabel(message.durationMs, vi),
                style: base.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: mine ? Colors.white : c.textHeading,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _durationLabel(int durationMs, bool vi) {
    final seconds = (durationMs / 1000).ceil().clamp(1, 999);
    return vi ? 'Tin nhắn voice • ${seconds}s' : 'Voice message • ${seconds}s';
  }
}

class _SocialCard extends StatelessWidget {
  final Widget child;

  const _SocialCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderColor.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InlineEmptyCard extends StatelessWidget {
  final String text;

  const _InlineEmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.metricRowBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: c.textMuted,
        ),
      ),
    );
  }
}

class _SocialEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _SocialEmptyState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_2_rounded, size: 48, color: c.accentBlue),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: base.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: c.textHeading,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: base.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textMuted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;

  const _Avatar({required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.accentBlue.withValues(alpha: 0.14),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
          color: c.accentBlue,
        ),
      ),
    );
  }
}

class _UserText extends StatelessWidget {
  final UserProfile? user;
  final String? fallbackName;
  final String? subtitle;

  const _UserText({this.user, this.fallbackName, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();
    final name = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName
        : fallbackName ?? 'SpeechUp user';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: base.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: c.textHeading,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle ?? user?.email ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: base.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.textMuted,
          ),
        ),
      ],
    );
  }
}
