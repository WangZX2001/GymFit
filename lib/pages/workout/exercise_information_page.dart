import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymfit/packages/exercise_information_repository/exercise_information_repository.dart';
import 'package:gymfit/pages/workout/exercise_description_page.dart';
import 'package:gymfit/pages/workout/filter/exercise_filter_page.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';





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

class _ExerciseInformationPageState extends State<ExerciseInformationPage>
    with TickerProviderStateMixin {
  final Set<String> _selectedTitles = {};
  late Future<List<ExerciseInformation>> _exerciseFuture;
  Map<String, dynamic> _currentFilters = {};
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchFocused = false;

  // Animation variables for search bar
  late AnimationController _searchBarAnimationController;
  late Animation<Offset> _searchBarSlideAnimation;
  double _lastScrollOffset = 0;
  bool _isSearchBarVisible = true;

  @override
  void initState() {
    super.initState();
    _exerciseFuture =
        ExerciseInformationRepository().getAllExerciseInformation();
    if (widget.isSelectionMode) {
      _selectedTitles.addAll(widget.initialSelectedExercises);
    }

    // Initialize animation controller
    _searchBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _searchBarSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _searchBarAnimationController,
      curve: Curves.easeInOut,
    ));

    // Add scroll listener
    _scrollController.addListener(_onScroll);
    
    // Add search focus listener
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onScroll() {
    final currentScrollOffset = _scrollController.offset;
    final difference = currentScrollOffset - _lastScrollOffset;

    // Always show search bar when at or near the top
    if (currentScrollOffset <= 50) {
      if (!_isSearchBarVisible) {
        _showSearchBar();
      }
      _lastScrollOffset = currentScrollOffset;
      return;
    }

    // Only react to significant scroll movements when not at the top
    if (difference.abs() > 5) {
      if (difference > 0 && _isSearchBarVisible) {
        // Scrolling up - hide search bar
        _hideSearchBar();
      } else if (difference < 0 && !_isSearchBarVisible) {
        // Scrolling down - show search bar
        _showSearchBar();
      }
    }

    _lastScrollOffset = currentScrollOffset;
  }

  void _hideSearchBar() {
    if (_isSearchBarVisible) {
      setState(() {
        _isSearchBarVisible = false;
      });
      _searchBarAnimationController.forward();
    }
  }

  void _showSearchBar() {
    if (!_isSearchBarVisible) {
      setState(() {
        _isSearchBarVisible = true;
      });
      _searchBarAnimationController.reverse();
    }
  }

  void _onSearchFocusChanged() {
    if (widget.isSelectionMode) {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchBarAnimationController.dispose();
    super.dispose();
  }

  void _openFilterPage() async {
    // Unfocus the search bar before navigating to prevent auto-focus on return
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    
    // Wait a frame to ensure unfocus takes effect
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (!mounted) return;
    
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => ExerciseFilterPage(initialFilters: _currentFilters),
      ),
    );

    if (result != null && mounted) {
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
        return exercise.title.toLowerCase().contains(_searchQuery.toLowerCase());
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
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    // Check if icon is a string path to an image
    if (icon is String &&
        (icon.contains('.jpg') ||
            icon.contains('.jpeg') ||
            icon.contains('.png') ||
            icon.contains('.gif'))) {
      
      return SizedBox(
        width: 80,
        height: 80,
        child: Image.asset(
          icon,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to default icon if image fails to load
            return Icon(Icons.fitness_center, size: 60, color: themeService.currentTheme.textTheme.titleLarge?.color);
          },
        ),
      );
    }
    // If it's an IconData, use it directly
    else if (icon is IconData) {
      return SizedBox(
        width: 80,
        height: 80,
        child: Icon(icon, size: 60, color: themeService.currentTheme.textTheme.titleLarge?.color),
      );
    }
    // Default fallback icon
    else {
      return SizedBox(
        width: 80,
        height: 80,
        child: Icon(Icons.fitness_center, size: 60, color: themeService.currentTheme.textTheme.titleLarge?.color),
      );
    }
  }

  Widget _buildFloatingSearchBar() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    return Container(
      color: themeService.currentTheme.scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            decoration: BoxDecoration(
              color: themeService.currentTheme.cardTheme.color,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: themeService.isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: false,
              textInputAction: widget.isSelectionMode ? TextInputAction.search : TextInputAction.done,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: TextStyle(
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[500],
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[500],
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: themeService.currentTheme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          // Instruction text
          if (!widget.isSelectionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 4),
              child: Text(
                'Click on any exercise icon to view specific instructions.',
                style: TextStyle(
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[600], 
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    String title,
    dynamic icon, {
    String? mainMuscle,
    bool isSelected = false,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    return Column(
      children: [
        Hero(
          tag: 'exercise-$title',
          flightShuttleBuilder: (
            BuildContext flightContext,
            Animation<double> animation,
            HeroFlightDirection flightDirection,
            BuildContext fromHeroContext,
            BuildContext toHeroContext,
          ) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeService.currentTheme.cardTheme.color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeService.currentTheme.textTheme.titleLarge?.color,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          child: Material(
            color: Colors.transparent,
            child: ClipRect(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(
                  left: isSelected ? 24 : 16,
                  right: 16,
                  top: 8,
                  bottom: 8,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Selection bar on the left when selected
                    if (isSelected)
                      Positioned(
                        left: -12,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 6,
                          decoration: BoxDecoration(
                            color: themeService.isDarkMode ? Colors.white : Colors.black,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    // Main content
                    Row(
                      children: [
                        // Image area
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: _buildIconOrImage(icon),
                        ),
                        // Text area
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: themeService.isDarkMode ? Colors.white : Colors.black,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (mainMuscle != null)
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        mainMuscle,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Selection indicator
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: themeService.isDarkMode ? Colors.white : Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${_selectedTitles.toList().indexOf(title) + 1}',
                                  style: TextStyle(
                                    color: themeService.isDarkMode ? Colors.black : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Divider line
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 1,
          color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey[300],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
        backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: themeService.currentTheme.appBarTheme.foregroundColor),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            'Exercises',
            style: themeService.currentTheme.appBarTheme.titleTextStyle,
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.filter_list, color: themeService.currentTheme.appBarTheme.foregroundColor),
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
              color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey[300], 
              height: 1.0
            ),
          ),
        ),
        body: GestureDetector(
          onTap: () {
            // Dismiss keyboard and unfocus search field when tapping outside
            _searchFocusNode.unfocus();
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
              return Stack(
                children: [
                  // Main content with dynamic top padding based on search bar visibility
                  AnimatedPadding(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.only(top: _isSearchBarVisible ? (widget.isSelectionMode ? 60 : 80) : 0), // Less space needed in selection mode (no instruction text)
                    child: Container(
                      color: themeService.currentTheme.scaffoldBackgroundColor, // Ensure background matches when search bar is hidden
                      child: Column(
                        children: [
                          if (_hasActiveFilters)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                'Showing ${sortedItems.length} of ${items.length} exercises',
                                style: TextStyle(
                                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Dismiss keyboard and unfocus search field when tapping in grid area
                                _searchFocusNode.unfocus();
                                FocusScope.of(context).unfocus();
                              },
                              behavior: HitTestBehavior.translucent,
                              child: Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                thickness: 6.0,
                                radius: const Radius.circular(10),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: EdgeInsets.only(
                                    top: 8,
                                    bottom: widget.isSelectionMode ? 0 : 16,
                                  ),
                                  itemCount: sortedItems.length,
                                  itemBuilder: (context, index) {
                                    final e = sortedItems[index];
                                    final isSelected =
                                        widget.isSelectionMode &&
                                        _selectedTitles.contains(e.title);
                                    return GestureDetector(
                                      onTap: () {
                                        // Add haptic feedback for all taps
                                        HapticFeedback.lightImpact();
                                        
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
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation, secondaryAnimation) => ExerciseDescriptionPage(
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
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '\${e.title} added to your plan',
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              transitionDuration: const Duration(milliseconds: 350),
                                              reverseTransitionDuration: const Duration(milliseconds: 300),
                                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                return FadeTransition(
                                                  opacity: CurvedAnimation(
                                                    parent: animation,
                                                    curve: Curves.easeInOut,
                                                  ),
                                                  child: child,
                                                );
                                              },
                                            ),
                                          );
                                        }
                                      },
                                      onTapDown: (_) {
                                        // Add subtle scale animation on tap down
                                        HapticFeedback.selectionClick();
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 100),
                                        curve: Curves.easeOut,
                                        transform: Matrix4.identity(),
                                        child: _buildExerciseCard(
                                          e.title,
                                          e.icon,
                                          mainMuscle: e.mainMuscle,
                                          isSelected: isSelected,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          if (widget.isSelectionMode)
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              opacity: _isSearchFocused ? 0.0 : 1.0,
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOutQuart,
                                child: _isSearchFocused
                                    ? const SizedBox.shrink()
                                    : Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 32.0),
                                        child: OutlinedButton.icon(
                                          onPressed: () => Navigator.pop(context, _selectedTitles.toList()),
                                          icon: Icon(
                                            Icons.check,
                                            color: themeService.isDarkMode ? Colors.black : Colors.white,
                                            size: 14 * 0.8,
                                          ),
                                          label: Text(
                                            'Done (${_selectedTitles.length})',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: themeService.isDarkMode ? Colors.black : Colors.white,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: themeService.isDarkMode ? Colors.white : Colors.black,
                                            foregroundColor: themeService.isDarkMode ? Colors.black : Colors.white,
                                            side: BorderSide(
                                              color: themeService.isDarkMode ? Colors.white : Colors.black,
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Animated Search Bar positioned at the top
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRect(
                      child: SlideTransition(
                        position: _searchBarSlideAnimation,
                        child: _buildFloatingSearchBar(),
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
