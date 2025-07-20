import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/exercise_set.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

// Formatter to limit decimal places (2 by default)
class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({this.decimalRange = 2}) : assert(decimalRange > 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final txt = newValue.text;
    if (txt == '.') {
      return TextEditingValue(text: '0.', selection: const TextSelection.collapsed(offset: 2));
    }
    if (txt.isEmpty) return newValue;
    final reg = RegExp(r'^\d*\.?\d{0,' + decimalRange.toString() + r'}$');
    if (reg.hasMatch(txt)) return newValue;
    return oldValue;
  }
}

class ExerciseSetRow extends StatelessWidget {
  final ExerciseSet exerciseSet;
  final int setIndex;
  final bool preventAutoFocus;
  final Function(double) onWeightChanged;
  final Function(int) onRepsChanged;
  final Function(bool) onCheckedChanged;
  final VoidCallback onDismissed;

  const ExerciseSetRow({
    super.key,
    required this.exerciseSet,
    required this.setIndex,
    required this.preventAutoFocus,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onCheckedChanged,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Dismissible(
      key: Key('set_${exerciseSet.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const FaIcon(
          FontAwesomeIcons.trash,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) => onDismissed(),
      child: Container(
        width: double.infinity,
        color: exerciseSet.isChecked 
            ? (themeService.isDarkMode ? Colors.green.shade900 : Colors.green.shade100) 
            : Colors.transparent,
        padding: const EdgeInsets.all(1),
        margin: const EdgeInsets.symmetric(vertical: 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final isSmallScreen = availableWidth < 350;
            final spacing = isSmallScreen ? 6.0 : 8.0;
            final minCheckboxSize = 48.0;

            return Row(
              children: [
                // Set number - fixed small width
                SizedBox(
                  width: isSmallScreen ? 35 : 45,
                  child: Center(
                    child: Text(
                      '${setIndex + 1}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: themeService.currentTheme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                // Previous data - flexible
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      exerciseSet.previousDataFormatted,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                // Weight input - flexible
                Expanded(
                  flex: 2,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isSmallScreen ? 45 : 60,
                        minWidth: 40,
                        maxHeight: 28,
                      ),
                      child: TextFormField(
                        controller: exerciseSet.weightController,
                        focusNode: exerciseSet.weightFocusNode,
                        autofocus: false,
                        canRequestFocus: !preventAutoFocus,
                        readOnly: preventAutoFocus,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                          color: exerciseSet.isChecked
                              ? (themeService.isDarkMode ? Colors.white : Colors.black)
                              : (exerciseSet.isWeightPrefilled
                                  ? (themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500)
                                  : (themeService.isDarkMode ? Colors.white : Colors.black)),
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: exerciseSet.isChecked
                                  ? Colors.green
                                  : (themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: exerciseSet.isChecked
                                  ? Colors.green
                                  : (themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: themeService.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: themeService.isDarkMode ? Colors.grey.shade800 : Colors.white,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 3 : 4,
                            vertical: 0,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          DecimalTextInputFormatter(decimalRange: 2),
                        ],
                        onTap: () {
                          // Mark as manually edited when user taps
                          exerciseSet.isWeightPrefilled = false;

                          // Toggle selection state based on our tracking
                          if (exerciseSet.weightSelected) {
                            // Clear selection
                            exerciseSet.weightController.selection =
                                TextSelection.collapsed(
                              offset: exerciseSet.weightController.text.length,
                            );
                            exerciseSet.weightSelected = false;
                          } else {
                            // Select all text
                            exerciseSet.weightController.selection =
                                TextSelection(
                              baseOffset: 0,
                              extentOffset:
                                  exerciseSet.weightController.text.length,
                            );
                            exerciseSet.weightSelected = true;
                          }
                        },
                        onChanged: (val) {
                          final newWeight = double.tryParse(val) ?? 0.0;
                          exerciseSet.weightSelected = false; // Reset selection state when typing
                          onWeightChanged(newWeight);
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                // Reps input - flexible
                Expanded(
                  flex: 2,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isSmallScreen ? 45 : 60,
                        minWidth: 40,
                        maxHeight: 28,
                      ),
                      child: TextFormField(
                        controller: exerciseSet.repsController,
                        focusNode: exerciseSet.repsFocusNode,
                        autofocus: false,
                        canRequestFocus: !preventAutoFocus,
                        enableInteractiveSelection: true,
                        readOnly: preventAutoFocus,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                          color: exerciseSet.isChecked
                              ? (themeService.isDarkMode ? Colors.white : Colors.black)
                              : (exerciseSet.isRepsPrefilled
                                  ? (themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500)
                                  : (themeService.isDarkMode ? Colors.white : Colors.black)),
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: exerciseSet.isChecked
                                  ? Colors.green
                                  : (themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: exerciseSet.isChecked
                                  ? Colors.green
                                  : (themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: themeService.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: themeService.isDarkMode ? Colors.grey.shade800 : Colors.white,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 3 : 4,
                            vertical: 0,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onTap: () {
                          // Mark as manually edited when user taps
                          exerciseSet.isRepsPrefilled = false;

                          // Toggle selection state based on our tracking
                          if (exerciseSet.repsSelected) {
                            // Clear selection
                            exerciseSet.repsController.selection =
                                TextSelection.collapsed(
                              offset: exerciseSet.repsController.text.length,
                            );
                            exerciseSet.repsSelected = false;
                          } else {
                            // Select all text
                            exerciseSet.repsController.selection =
                                TextSelection(
                              baseOffset: 0,
                              extentOffset:
                                  exerciseSet.repsController.text.length,
                            );
                            exerciseSet.repsSelected = true;
                          }
                        },
                        onChanged: (val) {
                          final newReps = int.tryParse(val) ?? 0;
                          exerciseSet.repsSelected = false; // Reset selection state when typing
                          onRepsChanged(newReps);
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                // Checkbox - fixed minimum size
                SizedBox(
                  width: minCheckboxSize,
                  height: minCheckboxSize,
                  child: Center(
                    child: Checkbox(
                      value: exerciseSet.isChecked,
                      fillColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.green;
                          }
                          return Colors.grey.shade300;
                        },
                      ),
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        onCheckedChanged(val ?? false);
                      },
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