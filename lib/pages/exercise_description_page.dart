import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ExerciseDescriptionPage extends StatefulWidget {
  final String title;
  final String description;
  final String? videoUrl;
  final String mainMuscle;
  final List<String> precautions;
  final VoidCallback onAdd;

  const ExerciseDescriptionPage({
    super.key,
    required this.title,
    required this.description,
    this.videoUrl,
    required this.mainMuscle,
    required this.precautions,
    required this.onAdd,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ExerciseDescriptionPageState createState() => _ExerciseDescriptionPageState();
}

class _ExerciseDescriptionPageState extends State<ExerciseDescriptionPage> {
  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    final url = widget.videoUrl;
    String? vidId;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && uri.queryParameters['v'] != null) {
        vidId = uri.queryParameters['v'];
      } else if (url.contains('youtu.be/')) {
        vidId = url.split('youtu.be/').last.split('?').first;
      }
    }
    if (vidId != null) {
      _ytController = YoutubePlayerController(
        initialVideoId: vidId,
        flags: const YoutubePlayerFlags(autoPlay: false),
      );
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Main Muscle Label
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  widget.mainMuscle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Description Section
              const Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),

              // Video Demonstration
              const Text(
                'Video Demonstration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Video player or placeholder image
              if (_ytController != null)
                YoutubePlayerBuilder(
                  player: YoutubePlayer(
                    controller: _ytController!,
                    showVideoProgressIndicator: true,
                    bottomActions: [
                      CurrentPosition(),
                      ProgressBar(isExpanded: true),
                      RemainingDuration(),
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white),
                        onPressed: () => _ytController!.seekTo(_ytController!.value.position - const Duration(seconds: 10)),
                      ),
                      IconButton(
                        icon: Icon(_ytController!.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                        onPressed: () {
                          if (_ytController!.value.isPlaying) {
                            _ytController!.pause();
                          } else {
                            _ytController!.play();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white),
                        onPressed: () => _ytController!.seekTo(_ytController!.value.position + const Duration(seconds: 10)),
                      ),
                      FullScreenButton(),
                    ],
                  ),
                  builder: (context, player) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: player,
                    );
                  },
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'lib/images/exerciseInformation.jpg',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),

              // Safety and Precautions
              Row(
                children: const [
                  Icon(Icons.warning, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Safety and Precautions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Precaution List
              ...widget.precautions.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final text = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '$idx. $text',
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Add Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Add This Exercise to Workout Plan',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 