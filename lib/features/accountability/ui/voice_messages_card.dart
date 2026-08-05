import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';

import '../controller/buddies_controller.dart';
import '../data/checkin_models.dart';

const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Voice notes between buddies — tap the mic to record, tap again to send;
/// tap any clip to play it. Records AAC, uploads to the asset host, plays by URL.
class VoiceMessagesCard extends StatefulWidget {
  const VoiceMessagesCard({super.key});

  @override
  State<VoiceMessagesCard> createState() => _VoiceMessagesCardState();
}

class _VoiceMessagesCardState extends State<VoiceMessagesCard> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _recording = false;
  bool _busy = false;
  DateTime? _recStart;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  String? _playingId;
  StreamSubscription<void>? _completeSub;

  Color get _accent => AppColors.primaryColor;

  @override
  void initState() {
    super.initState();
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _completeSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_busy) return;
    if (_recording) {
      await _stopAndSend();
    } else {
      await _startRecord();
    }
  }

  Future<void> _startRecord() async {
    try {
      if (!await _recorder.hasPermission()) {
        AppSnackBar.error('Microphone permission is needed to record.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/buddy_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path);
      _recStart = DateTime.now();
      _elapsed = Duration.zero;
      _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (_recStart != null && mounted) {
          setState(() => _elapsed = DateTime.now().difference(_recStart!));
        }
      });
      setState(() => _recording = true);
    } catch (_) {
      AppSnackBar.error('Could not start recording.');
    }
  }

  Future<void> _stopAndSend() async {
    _ticker?.cancel();
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {}
    final ms =
        _recStart == null ? 0 : DateTime.now().difference(_recStart!).inMilliseconds;
    setState(() {
      _recording = false;
      _busy = true;
    });
    if (path != null && ms > 700) {
      final ok = await BuddiesController.to.sendVoice(path, ms);
      if (!ok) AppSnackBar.error('Could not send voice message.');
    } else {
      AppSnackBar.error('Hold a little longer to record a note.');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _play(VoiceMessage m) async {
    try {
      if (_playingId == m.id) {
        await _player.stop();
        setState(() => _playingId = null);
        return;
      }
      await _player.stop();
      await _player.play(UrlSource(m.audioUrl));
      setState(() => _playingId = m.id);
    } catch (_) {
      AppSnackBar.error('Could not play that clip.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.graphic_eq_rounded, color: _accent, size: 18.r),
              SizedBox(width: 8.w),
              Text('Voice notes',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
              const Spacer(),
              _recordButton(),
            ],
          ),
          SizedBox(height: 12.h),
          Obx(() {
            final msgs = BuddiesController.to.voiceMessages;
            if (msgs.isEmpty) {
              return Text(
                  _recording
                      ? 'Recording… tap the mic to send.'
                      : 'Tap the mic to send your buddy a voice note.',
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 12.5.sp, color: _kMuted));
            }
            return Column(
              children: [for (final m in msgs) _bubble(m)],
            );
          }),
        ],
      ),
    );
  }

  Widget _recordButton() {
    final recording = _recording;
    return GestureDetector(
      onTap: _toggleRecord,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: recording ? const Color(0xffEF4444) : _accent,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(recording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white, size: 18.r),
            SizedBox(width: 6.w),
            Text(
                _busy
                    ? 'Sending…'
                    : recording
                        ? _fmt(_elapsed)
                        : 'Record',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _bubble(VoiceMessage m) {
    final playing = _playingId == m.id;
    final mine = m.mine;
    final bg = mine ? _accent : const Color(0xffF1EEEC);
    final fg = mine ? Colors.white : _kText;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        constraints: BoxConstraints(maxWidth: 220.w),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: GestureDetector(
          onTap: () => _play(m),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: fg, size: 22.r),
              SizedBox(width: 8.w),
              // simple static waveform bars
              Row(
                children: List.generate(
                    9,
                    (i) => Container(
                          width: 3.w,
                          height: (6 + (i % 3) * 6).h,
                          margin: EdgeInsets.symmetric(horizontal: 1.w),
                          decoration: BoxDecoration(
                            color: fg.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        )),
              ),
              SizedBox(width: 8.w),
              Text(m.durationLabel,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 11.sp, fontWeight: FontWeight.w700, color: fg)),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final s = d.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }
}
