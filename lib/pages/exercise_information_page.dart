import 'package:flutter/material.dart';
import 'package:gymfit/packages/exercise_information_repository/exercise_information_repository.dart';
import 'package:gymfit/pages/exercise_description_page.dart';
import 'package:gymfit/components/quick_start_overlay.dart';

class ExerciseInformationPage extends StatefulWidget {
  final bool isSelectionMode;
  final List<String> initialSelectedExercises;
  const ExerciseInformationPage({super.key, this.isSelectionMode = false, this.initialSelectedExercises = const []});

  @override
  State<ExerciseInformationPage> createState() => _ExerciseInformationPageState();
}

class _ExerciseInformationPageState extends State<ExerciseInformationPage> {
  final Set<String> _selectedTitles = {};
  late Future<List<ExerciseInformation>> _exerciseFuture;

  @override
  void initState() {
    super.initState();
    _exerciseFuture = ExerciseInformationRepository().getAllExerciseInformation();
    if (widget.isSelectionMode) {
      _selectedTitles.addAll(widget.initialSelectedExercises);
    }
    
    // Hide the quick start minibar when entering this page (with memory)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      QuickStartOverlay.hideMinibarWithMemory();
    });
  }

  void _handlePop() {
    // Restore the minibar when navigating back
    // Use a post-frame callback to ensure we're in the right context after navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get the root navigator context
      final rootContext = Navigator.of(context, rootNavigator: true).context;
      QuickStartOverlay.restoreMinibarIfNeeded(rootContext);
    });
  }

  Widget _buildExerciseCard(
    String title,
    dynamic icon, {
    bool isImage = false,
    String? mainMuscle,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.all(4),
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 4 : 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isImage)
            Image.asset(
              icon as String,
              height: 100,
              width: 100,
              fit: BoxFit.contain,
            )
          else
            Icon(
              icon as IconData,
              size: 100,
              color: Colors.black,
            ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (mainMuscle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                mainMuscle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handlePop();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade200,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              _handlePop();
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'Exercises',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: widget.isSelectionMode
              ? [
                  TextButton(
                    onPressed: () => Navigator.pop(context, _selectedTitles.toList()),
                    child: const Text('Done', style: TextStyle(color: Colors.black)),
                  ),
                ]
              : null,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: Colors.grey[300],
              height: 1.0,
            ),
          ),
        ),
        body: FutureBuilder<List<ExerciseInformation>>(
          future: _exerciseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: \${snapshot.error}'));
            }
            final items = snapshot.data ?? [];
            final sortedItems = List<ExerciseInformation>.from(items)
              ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
            return Column(
              children: [
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(16),
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1,
                    children: sortedItems.map((e) {
                      final isSelected = widget.isSelectionMode && _selectedTitles.contains(e.title);
                      return GestureDetector(
                        onTap: () {
                          if (widget.isSelectionMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedTitles.remove(e.title);
                              } else {
                                _selectedTitles.add(e.title);
                              }
                            });
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => ExerciseDescriptionPage(
                                  title: e.title,
                                  description: e.description,
                                  videoUrl: e.videoUrl,
                                  mainMuscle: e.mainMuscle,
                                  secondaryMuscle: e.secondaryMuscle,
                                  experienceLevel: e.experienceLevel,
                                  howTo: e.howTo,
                                  proTips: e.proTips,
                                  onAdd: () {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text('\${e.title} added to your plan')),
                                    );
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        child: Stack(
                          children: [
                            _buildExerciseCard(
                              e.title,
                              e.icon,
                              isImage: e.isImage,
                              mainMuscle: e.mainMuscle,
                              isSelected: isSelected,
                            ),
                            if (isSelected)
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(Icons.check_circle, color: Colors.blue),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.isSelectionMode
                        ? 'Tap exercises to select them, then press Done.'
                        : 'Click on any exercise icon to view specific instructions.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
} 