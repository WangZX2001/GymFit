import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ExerciseDescriptionPage extends StatefulWidget {
  final String title;
  final String description;
  final String? videoUrl;
  final String mainMuscle;
  final String secondaryMuscle;
  final List<String> proTips;
  final VoidCallback onAdd;
  final String experienceLevel;
  final String howTo;

  const ExerciseDescriptionPage({
    super.key,
    required this.title,
    required this.description,
    this.videoUrl,
    required this.mainMuscle,
    required this.secondaryMuscle,
    required this.proTips,
    required this.onAdd,
    required this.experienceLevel,
    required this.howTo,
  });

  @override
  State<ExerciseDescriptionPage> createState() => _ExerciseDescriptionPageState();
}

class _ExerciseDescriptionPageState extends State<ExerciseDescriptionPage> {
  YoutubePlayerController? _ytController;
  bool _showTitle = false;

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

  // Helper to pick color based on experience level
  Color _getExperienceColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
        centerTitle: true,
        title: AnimatedOpacity(
          opacity: _showTitle ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.axis == Axis.vertical) {
            final show = scrollInfo.metrics.pixels > 80;
            if (show != _showTitle) {
              setState(() => _showTitle = show);
            }
          }
          return false;
        },
        child: SingleChildScrollView(
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
                // Main Muscle and Experience Level
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.mainMuscle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: _getExperienceColor(widget.experienceLevel),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.experienceLevel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Secondary Muscle Label
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    widget.secondaryMuscle,
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
                // How to do it section
                const Text(
                  'How to perform',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Numbered steps for howTo
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.howTo.split('\n').asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final text = entry.value.trim();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 14, height: 1.5),
                          children: [
                            TextSpan(text: '$idx. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: text),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Safety and Precautions
                Row(
                  children: const [
                    Icon(Icons.lightbulb_outline, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Pro Tips',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Pro Tips list with bolded numbered lines
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.proTips
                      .expand((tip) => tip.split('\n'))
                      .map((line) => line.trim())
                      .where((line) => line.isNotEmpty)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                        final idx = entry.key + 1;
                        final text = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 14, height: 1.5),
                              children: [
                                TextSpan(text: '$idx. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: text),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 32),

                // Add Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Add This Exercise to Workout Plan',
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 