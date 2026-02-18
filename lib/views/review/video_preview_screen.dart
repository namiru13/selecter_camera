import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  final File videoFile;

  const VideoPreviewScreen({super.key, required this.videoFile});

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoEditorController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  bool _isDragging = false;
  double _dragValue = 0.0;
  bool _wasPlayingBeforeDrag = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoEditorController.file(
      widget.videoFile,
      minDuration: const Duration(seconds: 1),
      maxDuration: const Duration(seconds: 3600), // Allow long videos
    );

    _controller
        .initialize()
        .then((_) {
          setState(() {
            _isInitialized = true;
            _isPlaying = true;
          });
          _controller.video.play();
          _controller.video.setLooping(true);
        })
        .catchError((error) {
          debugPrint('Video initialization failed: $error');
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.video.value.isPlaying) {
        _controller.video.pause();
        _isPlaying = false;
      } else {
        _controller.video.play();
        _isPlaying = true;
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Dismissible(
        key: const Key('video_preview_dismissible'),
        direction: DismissDirection.down,
        onDismissed: (_) => Navigator.of(context).pop(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Hero(
                tag: widget.videoFile.path,
                child: _isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.video.value.aspectRatio,
                        child: VideoPlayer(_controller.video),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            ),
            // Tap area for play/pause
            if (_isInitialized)
              GestureDetector(
                onTap: _togglePlay,
                behavior: HitTestBehavior.opaque,
                child: SizedBox.expand(
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _isPlaying ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(100),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: const Icon(
                            Icons.play_arrow,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Close button
            Positioned(
              top: 48,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Seek bar and timestamp
            if (_isInitialized)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(204), // 0.8 * 255 = 204
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
                  child: ValueListenableBuilder(
                    valueListenable: _controller.video,
                    builder: (context, VideoPlayerValue value, child) {
                      final duration = value.duration;
                      final position = _isDragging
                          ? Duration(
                              milliseconds:
                                  (_dragValue * duration.inMilliseconds)
                                      .round(),
                            )
                          : value.position;

                      final maxDuration = duration.inMilliseconds.toDouble();
                      final currentValue = maxDuration > 0
                          ? position.inMilliseconds.toDouble()
                          : 0.0;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Courier', // Monospace font
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4.0,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8.0,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 16.0,
                                    ),
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    value: currentValue.clamp(0.0, maxDuration),
                                    min: 0.0,
                                    max: maxDuration,
                                    onChanged: (newValue) {
                                      setState(() {
                                        _isDragging = true;
                                        _dragValue = maxDuration > 0
                                            ? newValue / maxDuration
                                            : 0.0;
                                      });
                                      // Seek while dragging for smooth scrubbing
                                      _controller.video.seekTo(
                                        Duration(
                                          milliseconds: newValue.toInt(),
                                        ),
                                      );
                                    },
                                    onChangeStart: (newValue) {
                                      _wasPlayingBeforeDrag =
                                          _controller.video.value.isPlaying;
                                      if (_wasPlayingBeforeDrag) {
                                        _controller.video.pause();
                                      }
                                      setState(() {
                                        _isDragging = true;
                                      });
                                    },
                                    onChangeEnd: (newValue) {
                                      _controller.video.seekTo(
                                        Duration(
                                          milliseconds: newValue.toInt(),
                                        ),
                                      );
                                      setState(() {
                                        _isDragging = false;
                                      });
                                      if (_wasPlayingBeforeDrag) {
                                        _controller.video.play();
                                      }
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
