import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/return_code.dart';

class FFmpegService {
  Future<String?> generateThumbnailVideo(
    String imagePath,
    String outputVideoPath,
  ) async {
    // Create a 0.1s video from image
    final command =
        '-y -loop 1 -t 0.1 -i "$imagePath" -c:v libx264 -pix_fmt yuv420p "$outputVideoPath"';
    final session = await FFmpegKit.execute(command);

    if (ReturnCode.isSuccess(await session.getReturnCode())) {
      return outputVideoPath;
    } else {
      print('FFmpeg error: ${await session.getAllLogsAsString()}');
      return null;
    }
  }

  Future<String?> concatenateVideos(
    String introPath,
    String mainVideoPath,
    String outputPath,
  ) async {
    // Concatenate intro (thumbnail video) and main video
    // Note: ensure resolutions match or use scale filter
    final command =
        '-y -i "$introPath" -i "$mainVideoPath" -filter_complex "[0:v]scale=1920:1080[v0];[1:v]scale=1920:1080[v1];[v0][v1]concat=n=2:v=1:a=0[outv]" -map "[outv]" "$outputPath"';

    final session = await FFmpegKit.execute(command);
    if (ReturnCode.isSuccess(await session.getReturnCode())) {
      return outputPath;
    } else {
      print('FFmpeg concat error: ${await session.getAllLogsAsString()}');
      return null;
    }
  }
}
