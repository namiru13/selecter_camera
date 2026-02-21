/// 動画一覧画面
///
/// アプリ専用フォルダ内に保存された全動画ファイルを
/// サムネイル付きグリッドで表示する。
/// タップで各動画のビューワー（VideoPreviewScreen）へ遷移する。
/// 長押しで削除確認ダイアログを表示する。
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
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
    setState(() => _isLoading = true);
    final videos = await _videoSaveService.getVideoList();
    if (mounted) {
      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    }
  }

  /// 動画を削除する
  Future<void> _deleteVideo(File videoFile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('動画を削除'),
        content: const Text('この動画を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _videoSaveService.deleteVideo(videoFile.path);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('動画を削除しました')));
        _loadVideos(); // リストを更新
      }
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
      body: RefreshIndicator(
        onRefresh: _loadVideos,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _videos == null || _videos!.isEmpty
            ? ListView(
                // Pull-to-Refreshを機能させるためListViewでラップ
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      '動画がありません',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ),
                ],
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
                    onLongPress: () => _deleteVideo(_videos![index]),
                  );
                },
              ),
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
/// video_thumbnailパッケージで軽量なサムネイル画像を生成して表示する。
/// 長押しで削除アクションをトリガーする。
class _VideoThumbnailTile extends StatefulWidget {
  final File videoFile;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _VideoThumbnailTile({
    required this.videoFile,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_VideoThumbnailTile> createState() => _VideoThumbnailTileState();
}

class _VideoThumbnailTileState extends State<_VideoThumbnailTile> {
  Uint8List? _thumbnailData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  /// 軽量なサムネイル画像を生成する
  Future<void> _generateThumbnail() async {
    try {
      final data = await VideoThumbnail.thumbnailData(
        video: widget.videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 320,
        quality: 50,
      );
      if (mounted) {
        setState(() {
          _thumbnailData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('サムネイル生成エラー: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      onLongPress: widget.onLongPress,
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
            if (!_isLoading && _thumbnailData != null)
              Image.memory(_thumbnailData!, fit: BoxFit.cover)
            else if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2,
                ),
              )
            else
              const Center(
                child: Icon(
                  Icons.videocam_off,
                  color: Colors.white30,
                  size: 32,
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
