import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/models/exercise_set.dart';
import 'package:gymfit/models/editable_workout_models.dart' hide DecimalTextInputFormatter;
import 'package:gymfit/components/shared_adapters.dart';
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

// Generic interface for exercise set data
abstract class ExerciseSetData {
  String get id;
  double get weight;
  int get reps;
  bool? get isChecked; // Nullable to support custom workout configuration without checkboxes
  TextEditingController get weightController;
  TextEditingController get repsController;
  FocusNode get weightFocusNode;
  FocusNode get repsFocusNode;
  bool get weightSelected;
  bool get repsSelected;
  bool get isWeightPrefilled;
  bool get isRepsPrefilled;
  String get previousDataFormatted;
  
  void updateWeight(double weight);
  void updateReps(int reps);
  
  // Setters for properties that need to be modified
  set isWeightPrefilled(bool value);
  set isRepsPrefilled(bool value);
  set weightSelected(bool value);
  set repsSelected(bool value);
}

// Adapter for ExerciseSet
class ExerciseSetAdapter implements ExerciseSetData {
  final ExerciseSet exerciseSet;
  
  ExerciseSetAdapter(this.exerciseSet);
  
  @override String get id => exerciseSet.id;
  @override double get weight => exerciseSet.weight;
  @override int get reps => exerciseSet.reps;
  @override bool? get isChecked => exerciseSet.isChecked;
  @override TextEditingController get weightController => exerciseSet.weightController;
  @override TextEditingController get repsController => exerciseSet.repsController;
  @override FocusNode get weightFocusNode => exerciseSet.weightFocusNode;
  @override FocusNode get repsFocusNode => exerciseSet.repsFocusNode;
  @override bool get weightSelected => exerciseSet.weightSelected;
  @override bool get repsSelected => exerciseSet.repsSelected;
  @override bool get isWeightPrefilled => exerciseSet.isWeightPrefilled;
  @override bool get isRepsPrefilled => exerciseSet.isRepsPrefilled;
  @override String get previousDataFormatted => exerciseSet.previousDataFormatted;
  
  @override void updateWeight(double weight) => exerciseSet.weight = weight;
  @override void updateReps(int reps) => exerciseSet.reps = reps;
  
  @override set isWeightPrefilled(bool value) => exerciseSet.isWeightPrefilled = value;
  @override set isRepsPrefilled(bool value) => exerciseSet.isRepsPrefilled = value;
  @override set weightSelected(bool value) => exerciseSet.weightSelected = value;
  @override set repsSelected(bool value) => exerciseSet.repsSelected = value;
}

// Adapter for EditableExerciseSet
class EditableExerciseSetAdapter implements ExerciseSetData {
  final EditableExerciseSet exerciseSet;
  
  EditableExerciseSetAdapter(this.exerciseSet);
  
  @override String get id => exerciseSet.id;
  @override double get weight => exerciseSet.weight;
  @override int get reps => exerciseSet.reps;
  @override bool? get isChecked => exerciseSet.isChecked;
  @override TextEditingController get weightController => exerciseSet.weightController;
  @override TextEditingController get repsController => exerciseSet.repsController;
  @override FocusNode get weightFocusNode => exerciseSet.weightFocusNode;
  @override FocusNode get repsFocusNode => exerciseSet.repsFocusNode;
  @override bool get weightSelected => exerciseSet.weightSelected;
  @override bool get repsSelected => exerciseSet.repsSelected;
  @override bool get isWeightPrefilled => exerciseSet.isWeightPrefilled;
  @override bool get isRepsPrefilled => exerciseSet.isRepsPrefilled;
  @override String get previousDataFormatted => exerciseSet.previousDataFormatted;
  
  @override void updateWeight(double weight) => exerciseSet.updateWeight(weight);
  @override void updateReps(int reps) => exerciseSet.updateReps(reps);
  
  @override set isWeightPrefilled(bool value) => exerciseSet.isWeightPrefilled = value;
  @override set isRepsPrefilled(bool value) => exerciseSet.isRepsPrefilled = value;
  @override set weightSelected(bool value) => exerciseSet.weightSelected = value;
  @override set repsSelected(bool value) => exerciseSet.repsSelected = value;
}

class ExerciseSetRow extends StatelessWidget {
  final dynamic exerciseSet; // Can be ExerciseSet or EditableExerciseSet
  final int setIndex;
  final bool preventAutoFocus;
  final Function(double) onWeightChanged;
  final Function(int) onRepsChanged;
  final Function(bool)? onCheckedChanged; // Optional for custom workout configuration
  final VoidCallback onDismissed;
  final double? rowHeight; // Optional parameter to control row height

  const ExerciseSetRow({
    super.key,
    required this.exerciseSet,
    required this.setIndex,
    required this.preventAutoFocus,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onCheckedChanged,
    required this.onDismissed,
    this.rowHeight,
  });

  // Helper method to get the adapter
  ExerciseSetData get _setData {
    if (exerciseSet is ExerciseSet) {
      return ExerciseSetAdapter(exerciseSet as ExerciseSet);
    } else if (exerciseSet is EditableExerciseSet) {
      return EditableExerciseSetAdapter(exerciseSet as EditableExerciseSet);
    } else if (exerciseSet is ConfigSetAdapter) {
      return exerciseSet as ConfigSetAdapter;
    } else {
      throw ArgumentError('ExerciseSetRow requires ExerciseSet, EditableExerciseSet, or ConfigSetAdapter');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final setData = _setData;
    
    return Dismissible(
      key: Key('set_${setData.id}'),
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
        color: setData.isChecked == true
            ? (themeService.isDarkMode ? Colors.green.shade900 : Colors.green.shade100) 
            : Colors.transparent,
        padding: EdgeInsets.all(rowHeight != null ? (rowHeight! - 24.0) / 2 + 0.5 : 0.5),
        margin: const EdgeInsets.symmetric(vertical: 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final isSmallScreen = availableWidth < 350;
            final spacing = isSmallScreen ? 6.0 : 8.0;
            final minCheckboxSize = 40.0;
            final inputHeight = rowHeight ?? 24.0; // Use provided height or default to 24

            return Padding(
              padding: EdgeInsets.symmetric(vertical: rowHeight != null ? (rowHeight! - 24.0) / 4 : 0),
              child: Row(
                children: [
                // Set number - fixed small width
                SizedBox(
                  width: isSmallScreen ? 35 : 45,
                  child: Center(
                    child: Text(
                      '${setIndex + 1}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
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
                      setData.previousDataFormatted,
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
                        maxHeight: inputHeight,
                      ),
                      child: TextFormField(
                        controller: setData.weightController,
                        focusNode: setData.weightFocusNode,
                        autofocus: false,
                        canRequestFocus: !preventAutoFocus,
                        readOnly: preventAutoFocus,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                          color: setData.isChecked == true
                              ? (themeService.isDarkMode ? Colors.white : Colors.black)
                              : (setData.isWeightPrefilled
                                  ? (themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade700)
                                  : Colors.black),
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 3 : 4,
                            vertical: rowHeight != null ? (rowHeight! - 24.0) / 2 - 2 : -2,
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
                          setData.isWeightPrefilled = false;

                          // Toggle selection state based on our tracking
                          if (setData.weightSelected) {
                            // Clear selection
                            setData.weightController.selection =
                                TextSelection.collapsed(
                              offset: setData.weightController.text.length,
                            );
                            setData.weightSelected = false;
                          } else {
                            // Select all text
                            setData.weightController.selection =
                                TextSelection(
                              baseOffset: 0,
                              extentOffset:
                                  setData.weightController.text.length,
                            );
                            setData.weightSelected = true;
                          }
                        },
                        onChanged: (val) {
                          final newWeight = double.tryParse(val) ?? 0.0;
                          setData.weightSelected = false; // Reset selection state when typing
                          setData.updateWeight(newWeight);
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
                      maxHeight: inputHeight,
                    ),
                                          child: TextFormField(
                        controller: setData.repsController,
                        focusNode: setData.repsFocusNode,
                        autofocus: false,
                        canRequestFocus: !preventAutoFocus,
                        enableInteractiveSelection: true,
                        readOnly: preventAutoFocus,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                          color: setData.isChecked == true
                              ? (themeService.isDarkMode ? Colors.white : Colors.black)
                              : (setData.isRepsPrefilled
                                  ? (themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade700)
                                  : Colors.black),
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 3 : 4,
                            vertical: rowHeight != null ? (rowHeight! - 24.0) / 2 - 2 : -2,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onTap: () {
                          // Mark as manually edited when user taps
                          setData.isRepsPrefilled = false;

                          // Toggle selection state based on our tracking
                          if (setData.repsSelected) {
                            // Clear selection
                            setData.repsController.selection =
                                TextSelection.collapsed(
                              offset: setData.repsController.text.length,
                            );
                            setData.repsSelected = false;
                          } else {
                            // Select all text
                            setData.repsController.selection =
                                TextSelection(
                              baseOffset: 0,
                              extentOffset:
                                  setData.repsController.text.length,
                            );
                            setData.repsSelected = true;
                          }
                        },
                        onChanged: (val) {
                          final newReps = int.tryParse(val) ?? 0;
                          setData.repsSelected = false; // Reset selection state when typing
                          setData.updateReps(newReps);
                          onRepsChanged(newReps);
                        },
                      ),
                    ),
                  ),
                ),
                if (setData.isChecked != null) ...[
                  SizedBox(width: spacing),
                  // Checkbox - fixed minimum size
                  SizedBox(
                    width: minCheckboxSize,
                    height: minCheckboxSize,
                    child: Center(
                      child: Checkbox(
                        value: setData.isChecked,
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
                          onCheckedChanged?.call(val ?? false);
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
          },
        ),
      ),
    );
  }
}