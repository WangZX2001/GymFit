import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/pages/workout/exercise_information_page.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

class CustomWorkoutAddButton extends StatelessWidget {
  final bool isAnyFieldFocused;
  final bool isInReorderMode;
  final VoidCallback onExercisesAdded;
  final Function(List<String>) onExercisesLoaded;
  final VoidCallback onDoneReorder;

  const CustomWorkoutAddButton({
    super.key,
    required this.isAnyFieldFocused,
    required this.isInReorderMode,
    required this.onExercisesAdded,
    required this.onExercisesLoaded,
    required this.onDoneReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 32.0),
      child: Column(
        children: [
          // Done button with identical animation to AddExerciseButton (hide when keyboard is up)
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutQuart,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              opacity: (isInReorderMode && !isAnyFieldFocused) ? 1.0 : 0.0,
              child:
                  (isInReorderMode && !isAnyFieldFocused)
                      ? LayoutBuilder(
                        builder: (context, constraints) {
                          final buttonFontSize = 14.0;
                          final buttonPadding = const EdgeInsets.symmetric(vertical: 8);

                          return Builder(
                            builder: (context) {
                              final themeService = Provider.of<ThemeService>(context);
                              return SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: onDoneReorder,
                                  icon: FaIcon(
                                    FontAwesomeIcons.check,
                                    color: themeService.isDarkMode ? Colors.black : Colors.white,
                                    size: buttonFontSize * 0.8,
                                  ),
                                  label: Text(
                                    'Done',
                                    style: TextStyle(
                                      fontSize: buttonFontSize,
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
                                    padding: buttonPadding,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
                      : const SizedBox.shrink(),
            ),
          ),
          // Add Exercises button with identical animation to AddExerciseButton (positioned last for bottom-up animation)
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutQuart,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              opacity: (isInReorderMode || isAnyFieldFocused) ? 0.0 : 1.0,
              child:
                  (isInReorderMode || isAnyFieldFocused)
                      ? const SizedBox.shrink()
                      : LayoutBuilder(
                        builder: (context, constraints) {
                          final buttonFontSize = 14.0;
                          final buttonPadding = const EdgeInsets.symmetric(vertical: 8);

                          return Builder(
                            builder: (context) {
                              final themeService = Provider.of<ThemeService>(context);
                              return SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    onExercisesAdded();

                                    final navigator = Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    );
                                    final result = await navigator
                                        .push<List<String>>(
                                          MaterialPageRoute(
                                            builder:
                                                (ctx) =>
                                                    const ExerciseInformationPage(
                                                      isSelectionMode: true,
                                                    ),
                                          ),
                                        );

                                    if (result != null) {
                                      onExercisesLoaded(result);
                                    }
                                  },
                                  icon: FaIcon(
                                    FontAwesomeIcons.plus,
                                    color: themeService.isDarkMode ? Colors.black : Colors.white,
                                    size: buttonFontSize * 0.8,
                                  ),
                                  label: Text(
                                    'Add Exercises',
                                    style: TextStyle(
                                      fontSize: buttonFontSize,
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
                                    padding: buttonPadding,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
