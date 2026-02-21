import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../review/video_list_screen.dart';
import '../../review/video_preview_screen.dart';

class VideoPreviewButton extends StatefulWidget {
  final String? videoPath;
  final VoidCallback? onPreviewTap;

  const VideoPreviewButton({super.key, this.videoPath, this.onPreviewTap});

  @override
  State<VideoPreviewButton> createState() => _VideoPreviewButtonState();
}

class _VideoPreviewButtonState extends State<VideoPreviewButton> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant VideoPreviewButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoPath != oldWidget.videoPath) {
      _initializeController();
    }
  }

  Future<void> _initializeController() async {
    final oldController = _controller;
    if (oldController != null) {
      await oldController.dispose();
    }

    if (widget.videoPath != null) {
      final file = File(widget.videoPath!);
      if (await file.exists()) {
        final controller = VideoPlayerController.file(file);
        try {
          await controller.initialize();
          await controller.setVolume(0.0);
          // Seek to the first frame (or a specific timestamp if desired)
          await controller.seekTo(Duration.zero);
          if (mounted) {
            setState(() {
              _controller = controller;
            });
          }
        } catch (e) {
          debugPrint("Error initializing video preview: $e");
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _controller = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.videoPath != null) {
          // 直前に撮影した動画がある場合 → その動画のビューワーへ遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  VideoPreviewScreen(videoFile: File(widget.videoPath!)),
            ),
          );
        } else {
          // 直前に撮影した動画がない場合 → 動画一覧画面へ遷移
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const VideoListScreen()),
          );
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: _controller != null && _controller!.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              )
            : const Center(
                child: Text(
                  "preview",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
      ),
    );
  }
}
