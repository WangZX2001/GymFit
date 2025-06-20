import 'package:flutter/material.dart';
import 'package:gymfit/packages/exercise_information_repository/exercise_information_repository.dart';
import 'package:gymfit/pages/exercise_description_page.dart';
import 'package:gymfit/pages/exercise_filter_page.dart';
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
  Map<String, dynamic> _currentFilters = {};

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

  void _openFilterPage() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseFilterPage(initialFilters: _currentFilters),
      ),
    );
    
    if (result != null) {
      setState(() {
        _currentFilters = result;
      });
    }
  }

  List<ExerciseInformation> _applyFilters(List<ExerciseInformation> exercises) {
    if (_currentFilters.isEmpty) return exercises;
    
    return exercises.where((exercise) {
      final mainMuscles = _currentFilters['mainMuscles'] as List<String>? ?? [];
      final secondaryMuscles = _currentFilters['secondaryMuscles'] as List<String>? ?? [];
      final experienceLevels = _currentFilters['experienceLevels'] as List<String>? ?? [];
      final equipment = _currentFilters['equipment'] as List<String>? ?? [];
      
      bool matchesMainMuscle = mainMuscles.isEmpty || 
          mainMuscles.any((muscle) => exercise.mainMuscle.toLowerCase().contains(muscle.toLowerCase()));
      
      bool matchesSecondaryMuscle = secondaryMuscles.isEmpty || 
          secondaryMuscles.any((muscle) => exercise.secondaryMuscle.toLowerCase().contains(muscle.toLowerCase()));
      
      bool matchesExperience = experienceLevels.isEmpty || 
          experienceLevels.any((level) => exercise.experienceLevel.toLowerCase().contains(level.toLowerCase()));
      
      bool matchesEquipment = equipment.isEmpty || 
          equipment.any((eq) => exercise.equipment.toLowerCase().contains(eq.toLowerCase()));
      
      return matchesMainMuscle && matchesSecondaryMuscle && matchesExperience && matchesEquipment;
    }).toList();
  }

  bool get _hasActiveFilters {
    return _currentFilters.isNotEmpty && 
           (_currentFilters['mainMuscles']?.isNotEmpty == true ||
            _currentFilters['secondaryMuscles']?.isNotEmpty == true ||
            _currentFilters['experienceLevels']?.isNotEmpty == true ||
            _currentFilters['equipment']?.isNotEmpty == true);
  }

  Widget _buildIconOrImage(dynamic icon) {
    // Check if icon is a string path to an image
    if (icon is String && (icon.contains('.jpg') || icon.contains('.jpeg') || icon.contains('.png') || icon.contains('.gif'))) {
      return Image.asset(
        icon,
        height: 100,
        width: 100,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to default icon if image fails to load
          return Icon(
            Icons.fitness_center,
            size: 100,
            color: Colors.black,
          );
        },
      );
    }
    // If it's an IconData, use it directly
    else if (icon is IconData) {
      return Icon(
        icon,
        size: 100,
        color: Colors.black,
      );
    }
    // Default fallback icon
    else {
      return Icon(
        Icons.fitness_center,
        size: 100,
        color: Colors.black,
      );
    }
  }

  Widget _buildExerciseCard(
    String title,
    dynamic icon, {
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
          _buildIconOrImage(icon),
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
          actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.black),
                    onPressed: _openFilterPage,
                  ),
                  if (_hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
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
            final filteredItems = _applyFilters(items);
            final sortedItems = List<ExerciseInformation>.from(filteredItems)
              ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
            return Column(
              children: [
                if (_hasActiveFilters)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Showing ${sortedItems.length} of ${items.length} exercises',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: EdgeInsets.all(16).copyWith(
                      bottom: widget.isSelectionMode ? 0 : 16,
                    ),
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
                if (!widget.isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Click on any exercise icon to view specific instructions.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (widget.isSelectionMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selectedTitles.toList()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check),
                          const SizedBox(width: 8),
                          Text(
                            'Done (${_selectedTitles.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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