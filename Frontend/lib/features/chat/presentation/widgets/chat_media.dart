/// Widgets para mostrar media en las burbujas del chat: imagen, video y audio,
/// más las pantallas a pantalla completa. Las URLs se firman desde MinIO.
library;

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import 'package:baratito/widgets/minio_image.dart';
import '../../../../core/minio_service.dart';

// ── Imagen ──────────────────────────────────────────────
class ChatImageBubble extends StatelessWidget {
  final String mediaPath;
  const ChatImageBubble({super.key, required this.mediaPath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _FullScreenImage(mediaPath: mediaPath),
      )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: MinioImage(
          objectKey: mediaPath,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String mediaPath;
  const _FullScreenImage({required this.mediaPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<String>(
        future: MinioService().getImageUrl(mediaPath),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          return InteractiveViewer(
            child: Center(child: Image.network(snap.data!)),
          );
        },
      ),
    );
  }
}

// ── Video ───────────────────────────────────────────────
class ChatVideoBubble extends StatelessWidget {
  final String mediaPath;
  const ChatVideoBubble({super.key, required this.mediaPath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: MinioService().getImageUrl(mediaPath),
      builder: (context, snap) {
        return GestureDetector(
          onTap: snap.hasData
              ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _FullScreenVideo(url: snap.data!),
                  ))
              : null,
          child: Container(
            width: 200,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white, size: 52),
            ),
          ),
        );
      },
    );
  }
}

class _FullScreenVideo extends StatefulWidget {
  final String url;
  const _FullScreenVideo({required this.url});

  @override
  State<_FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<_FullScreenVideo> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _ready = true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _ready
            ? GestureDetector(
                onTap: () => setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                }),
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      if (!_controller.value.isPlaying)
                        const Icon(Icons.play_circle_fill_rounded,
                            color: Colors.white70, size: 64),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: VideoProgressIndicator(_controller,
                            allowScrubbing: true),
                      ),
                    ],
                  ),
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

// ── Audio ───────────────────────────────────────────────
class ChatAudioBubble extends StatefulWidget {
  final String mediaPath;
  final bool isMine;
  const ChatAudioBubble({
    super.key,
    required this.mediaPath,
    required this.isMine,
  });

  @override
  State<ChatAudioBubble> createState() => _ChatAudioBubbleState();
}

class _ChatAudioBubbleState extends State<ChatAudioBubble> {
  final AudioPlayer _player = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    if (!_loaded) {
      final url = await MinioService().getImageUrl(widget.mediaPath);
      await _player.play(UrlSource(url));
      _loaded = true;
    } else {
      await _player.resume();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isMine ? Colors.white : AppColors.primary;
    final track = widget.isMine
        ? Colors.white.withAlpha(90)
        : context.palette.divider;
    final total = _duration.inMilliseconds == 0 ? 1.0 : _duration.inMilliseconds.toDouble();
    final value = _position.inMilliseconds.clamp(0, total.toInt()).toDouble();

    return SizedBox(
      width: 200,
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Icon(
              _playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: fg,
              size: 36,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    activeTrackColor: fg,
                    inactiveTrackColor: track,
                    thumbColor: fg,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: value,
                    max: total,
                    onChanged: (v) =>
                        _player.seek(Duration(milliseconds: v.toInt())),
                  ),
                ),
                Text(
                  _fmt(_position == Duration.zero ? _duration : _position),
                  style: TextStyle(
                      fontSize: 11,
                      color: widget.isMine
                          ? Colors.white.withAlpha(200)
                          : context.palette.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
