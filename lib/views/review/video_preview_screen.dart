/// 動画プレビュー画面
///
/// 撮影した動画をビューワーで再生する画面。
/// シークバー、再生/一時停止、共有ボタン、動画一覧遷移ボタンを含む。
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';
import 'video_list_screen.dart';

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
      maxDuration: const Duration(seconds: 3600), // 長時間動画を許可
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

  /// 動画ファイルを共有する
  Future<void> _shareVideo() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(widget.videoFile.path)],
          text: 'Skier Camera で撮影した動画',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('共有エラー: $e')));
      }
    }
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
            // タップエリア（再生/一時停止）
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
            // 閉じるボタン
            Positioned(
              top: 48,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // 上部右側ツールバー
            Positioned(
              top: 48,
              right: 16,
              child: Row(
                children: [
                  // 共有ボタン
                  IconButton(
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _shareVideo,
                  ),
                  const SizedBox(width: 4),
                  // ビューワー一覧画面への遷移ボタン
                  IconButton(
                    icon: const Icon(
                      Icons.video_library,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const VideoListScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // シークバーとタイムスタンプ
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
                      colors: [Colors.transparent, Colors.black.withAlpha(204)],
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
                                  fontFamily: 'Courier',
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
                                      // ドラッグ中のスムーズスクラブ
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
