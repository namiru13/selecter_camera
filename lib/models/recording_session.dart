import 'package:equatable/equatable.dart';

class RecordingSession extends Equatable {
  final String videoId;
  final String? targetSkierId;
  final String? detectedCandidateId;
  final String? bestFramePath;

  const RecordingSession({
    required this.videoId,
    this.targetSkierId,
    this.detectedCandidateId,
    this.bestFramePath,
  });

  RecordingSession copyWith({
    String? videoId,
    String? targetSkierId,
    String? detectedCandidateId,
    String? bestFramePath,
  }) {
    return RecordingSession(
      videoId: videoId ?? this.videoId,
      targetSkierId: targetSkierId ?? this.targetSkierId,
      detectedCandidateId: detectedCandidateId ?? this.detectedCandidateId,
      bestFramePath: bestFramePath ?? this.bestFramePath,
    );
  }

  @override
  List<Object?> get props => [
    videoId,
    targetSkierId,
    detectedCandidateId,
    bestFramePath,
  ];
}
