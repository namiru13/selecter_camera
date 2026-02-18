/// 動画一覧画面
///
/// アプリ専用フォルダ内に保存された全動画ファイルを
/// サムネイル付きグリッドで表示する。
/// タップで各動画のビューワー（VideoPreviewScreen）へ遷移する。
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../services/video_save_service.dart';
import 'video_preview_screen.dart';

/// 動画一覧画面ウィジェット
class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final VideoSaveService _videoSaveService = VideoSaveService();
  List<File>? _videos;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  /// 動画一覧を読み込む
  Future<void> _loadVideos() async {
    final videos = await _videoSaveService.getVideoList();
    if (mounted) {
      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('動画一覧'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _videos == null || _videos!.isEmpty
          ? const Center(
              child: Text(
                '動画がありません',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 16 / 9,
              ),
              itemCount: _videos!.length,
              itemBuilder: (context, index) {
                return _VideoThumbnailTile(
                  videoFile: _videos![index],
                  onTap: () => _openVideo(_videos![index]),
                );
              },
            ),
    );
  }

  /// 動画ビューワーを開く
  void _openVideo(File videoFile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPreviewScreen(videoFile: videoFile),
      ),
    );
  }
}

/// 動画サムネイルタイル
///
/// 動画のファーストフレームをサムネイルとして表示し、
/// ファイル名（日時）を下部にオーバーレイ表示する。
class _VideoThumbnailTile extends StatefulWidget {
  final File videoFile;
  final VoidCallback onTap;

  const _VideoThumbnailTile({required this.videoFile, required this.onTap});

  @override
  State<_VideoThumbnailTile> createState() => _VideoThumbnailTileState();
}

class _VideoThumbnailTileState extends State<_VideoThumbnailTile> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeThumbnail();
  }

  /// サムネイル用のVideoPlayerControllerを初期化する
  Future<void> _initializeThumbnail() async {
    final controller = VideoPlayerController.file(widget.videoFile);
    try {
      await controller.initialize();
      await controller.setVolume(0.0);
      await controller.seekTo(Duration.zero);
      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('サムネイル初期化エラー: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// ファイル名から表示用の日時文字列を生成
  String _formatFileName(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    final nameWithoutExt = fileName.replaceAll('.mp4', '');
    // タイムスタンプ（ミリ秒）からDateTimeに変換
    final timestamp = int.tryParse(nameWithoutExt);
    if (timestamp != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/'
          '${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }
    return nameWithoutExt;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // サムネイル
            if (_isInitialized && _controller != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2,
                ),
              ),
            // 再生アイコンオーバーレイ
            const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white70,
                size: 40,
              ),
            ),
            // 日時ラベル
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withAlpha(180)],
                  ),
                ),
                child: Text(
                  _formatFileName(widget.videoFile.path),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
