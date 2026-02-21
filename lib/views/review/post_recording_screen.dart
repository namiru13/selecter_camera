/// 撮影後確認画面
///
/// 録画直後のプレビュー表示と「保存」「やり直し（削除して再撮影）」の
/// 選択UIを提供する。保存を選択した場合は動画をギャラリーに保存する。
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../services/video_save_service.dart';

/// 撮影後確認画面ウィジェット
class PostRecordingScreen extends StatefulWidget {
  /// 一時保存された録画ファイルのパス
  final String tempVideoPath;

  const PostRecordingScreen({super.key, required this.tempVideoPath});

  @override
  State<PostRecordingScreen> createState() => _PostRecordingScreenState();
}

class _PostRecordingScreenState extends State<PostRecordingScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.tempVideoPath));
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 動画をギャラリーに保存する
  Future<void> _saveVideo() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final videoSaveService = VideoSaveService();
    final result = await videoSaveService.saveToGallery(widget.tempVideoPath);

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('動画を保存しました'),
            backgroundColor: Colors.green,
          ),
        );
        _controller.pause();
        // 保存先パスを返してカメラ画面に戻る
        Navigator.of(context).pop(result.savedPath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存エラー: ${result.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  /// 動画を破棄してカメラ画面に戻る
  Future<void> _discardVideo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('動画を削除'),
        content: const Text('この動画を破棄して撮影をやり直しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('破棄'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 一時ファイルを削除
      try {
        final file = File(widget.tempVideoPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      if (mounted) {
        _controller.pause();
        Navigator.of(context).pop(null); // null = 保存しなかった
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 動画プレビュー
          Center(
            child: _isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const CircularProgressIndicator(color: Colors.white),
          ),

          // 上部ラベル
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '撮影確認',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // 下部操作ボタン
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // やり直しボタン
                _buildActionButton(
                  icon: Icons.delete_outline,
                  label: 'やり直し',
                  color: Colors.red,
                  onPressed: _discardVideo,
                ),
                // 保存ボタン
                _buildActionButton(
                  icon: _isSaving ? Icons.hourglass_empty : Icons.check,
                  label: _isSaving ? '保存中...' : '保存',
                  color: Colors.green,
                  onPressed: _isSaving ? null : _saveVideo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
