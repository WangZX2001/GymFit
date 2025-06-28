import 'package:flutter/material.dart';
import 'package:gymfit/packages/exercise_information_repository/exercise_information_repository.dart';
import 'package:gymfit/pages/workout/exercise_description_page.dart';
import 'package:gymfit/pages/workout/exercise_filter_page.dart';

class ExerciseInformationPage extends StatefulWidget {
  final bool isSelectionMode;
  final List<String> initialSelectedExercises;
  const ExerciseInformationPage({
    super.key,
    this.isSelectionMode = false,
    this.initialSelectedExercises = const [],
  });

  @override
  State<ExerciseInformationPage> createState() =>
      _ExerciseInformationPageState();
}

class _ExerciseInformationPageState extends State<ExerciseInformationPage> {
  final Set<String> _selectedTitles = {};
  late Future<List<ExerciseInformation>> _exerciseFuture;
  Map<String, dynamic> _currentFilters = {};
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _exerciseFuture =
        ExerciseInformationRepository().getAllExerciseInformation();
    if (widget.isSelectionMode) {
      _selectedTitles.addAll(widget.initialSelectedExercises);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }



  void _openFilterPage() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => ExerciseFilterPage(initialFilters: _currentFilters),
      ),
    );

    if (result != null) {
      setState(() {
        _currentFilters = result;
      });
    }
  }

  List<ExerciseInformation> _applyFilters(List<ExerciseInformation> exercises) {
    List<ExerciseInformation> filteredExercises = exercises;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredExercises = filteredExercises.where((exercise) {
        return exercise.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               exercise.mainMuscle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               exercise.secondaryMuscle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               exercise.equipment.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply other filters
    if (_currentFilters.isEmpty) return filteredExercises;

    return filteredExercises.where((exercise) {
      final mainMuscles = _currentFilters['mainMuscles'] as List<String>? ?? [];
      final experienceLevels =
          _currentFilters['experienceLevels'] as List<String>? ?? [];
      final equipment = _currentFilters['equipment'] as List<String>? ?? [];

      bool matchesMainMuscle =
          mainMuscles.isEmpty ||
          mainMuscles.any(
            (muscle) => exercise.mainMuscle.toLowerCase().contains(
              muscle.toLowerCase(),
            ),
          );

      bool matchesExperience =
          experienceLevels.isEmpty ||
          experienceLevels.any(
            (level) => exercise.experienceLevel.toLowerCase().contains(
              level.toLowerCase(),
            ),
          );

      bool matchesEquipment =
          equipment.isEmpty ||
          equipment.any(
            (eq) => exercise.equipment.toLowerCase().contains(eq.toLowerCase()),
          );

      return matchesMainMuscle &&
          matchesExperience &&
          matchesEquipment;
    }).toList();
  }

  bool get _hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        (_currentFilters.isNotEmpty &&
        (_currentFilters['mainMuscles']?.isNotEmpty == true ||
            _currentFilters['experienceLevels']?.isNotEmpty == true ||
            _currentFilters['equipment']?.isNotEmpty == true));
  }

  Widget _buildIconOrImage(dynamic icon) {
    // Check if icon is a string path to an image
    if (icon is String &&
        (icon.contains('.jpg') ||
            icon.contains('.jpeg') ||
            icon.contains('.png') ||
            icon.contains('.gif'))) {
      // Special handling for T Bar Row image to fill container width
      bool isTBarRow = icon.contains('TBarRow');
      
      return Image.asset(
        icon,
        height: 100,
        width: isTBarRow ? double.infinity : 100,
        fit: isTBarRow ? BoxFit.cover : BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to default icon if image fails to load
          return Icon(Icons.fitness_center, size: 100, color: Colors.black);
        },
      );
    }
    // If it's an IconData, use it directly
    else if (icon is IconData) {
      return Icon(icon, size: 100, color: Colors.black);
    }
    // Default fallback icon
    else {
      return Icon(Icons.fitness_center, size: 100, color: Colors.black);
    }
  }

  Widget _buildFloatingSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search exercises...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[500],
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[500],
                  ),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
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
          Flexible(child: _buildIconOrImage(icon)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
    return Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade200,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'Exercises',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
            child: Container(color: Colors.grey[300], height: 1.0),
          ),
        ),
        body: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside text fields
            FocusScope.of(context).unfocus();
          },
          behavior: HitTestBehavior.translucent,
          child: FutureBuilder<List<ExerciseInformation>>(
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
              final sortedItems = List<ExerciseInformation>.from(
                filteredItems,
              )..sort(
                (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
              );
              return Column(
              children: [
                // Floating Search Bar
                _buildFloatingSearchBar(),
                // Instruction text
                if (!widget.isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                    child: Text(
                      'Click on any exercise icon to view specific instructions.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_hasActiveFilters)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                  child: GestureDetector(
                    onTap: () {
                      // Dismiss keyboard when tapping in grid area
                      FocusScope.of(context).unfocus();
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 6.0,
                      radius: const Radius.circular(10),
                      child: GridView.count(
                        controller: _scrollController,
                        crossAxisCount: 2,
                        padding: EdgeInsets.all(
                          16,
                        ).copyWith(bottom: widget.isSelectionMode ? 0 : 16),
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 1,
                        children:
                        sortedItems.map((e) {
                          final isSelected =
                              widget.isSelectionMode &&
                              _selectedTitles.contains(e.title);
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
                                    builder:
                                        (ctx) => ExerciseDescriptionPage(
                                          title: e.title,
                                          description: e.description,
                                          videoUrl: e.videoUrl,
                                          mainMuscle: e.mainMuscle,
                                          secondaryMuscle: e.secondaryMuscle,
                                          experienceLevel: e.experienceLevel,
                                          howTo: e.howTo,
                                          proTips: e.proTips,
                                          onAdd: () {
                                            ScaffoldMessenger.of(
                                              ctx,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '\${e.title} added to your plan',
                                                ),
                                              ),
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
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                if (widget.isSelectionMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
                    child: ElevatedButton(
                      onPressed:
                          () =>
                              Navigator.pop(context, _selectedTitles.toList()),
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
