import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Input formatter to restrict decimals to a fixed number of places (default 2)
class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({this.decimalRange = 2})
    : assert(decimalRange > 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text == '.') {
      // Prefix lone decimal with 0
      return TextEditingValue(
        text: '0.',
        selection: const TextSelection.collapsed(offset: 2),
      );
    }

    // Allow empty input
    if (text.isEmpty) {
      return newValue;
    }

    final regExp = RegExp(r'^\d*\.?\d{0,' + decimalRange.toString() + r'}$');
    if (regExp.hasMatch(text)) {
      return newValue;
    }

    // Reject invalid additions by returning old value
    return oldValue;
  }
}

// Model to track individual set data
class ExerciseSet {
  final String id;
  double weight;
  int reps;
  bool isChecked;
  late final TextEditingController weightController;
  late final TextEditingController repsController;
  late final FocusNode weightFocusNode;
  late final FocusNode repsFocusNode;
  bool weightSelected = false;
  bool repsSelected = false;
  bool isWeightPrefilled = false; // Track if weight was prefilled from previous data
  bool isRepsPrefilled = false; // Track if reps was prefilled from previous data
  double? previousWeight; // Previous workout weight for reference
  int? previousReps; // Previous workout reps for reference

  // Helper to format weight: whole number if no decimal part
  static String _formatWeight(double value) {
    if (value % 1 == 0) {
      // Whole number – show without decimal
      return value.toInt().toString();
    }
    return value.toString();
  }

  // Helper to format previous data as "20kg x 5"
  String get previousDataFormatted {
    if (previousWeight != null && previousReps != null) {
      return '${_formatWeight(previousWeight!)}kg x $previousReps';
    }
    return '-';
  }

  static int _counter = 0;

  ExerciseSet({
    this.weight = 0.0,
    this.reps = 0,
    this.isChecked = false,
    this.isWeightPrefilled = false,
    this.isRepsPrefilled = false,
    this.previousWeight,
    this.previousReps,
  }) : id = '${DateTime.now().millisecondsSinceEpoch}_${++_counter}' {
    weightController = TextEditingController(text: _formatWeight(weight));
    repsController = TextEditingController(text: reps.toString());
    weightFocusNode = FocusNode();
    repsFocusNode = FocusNode();
  }

  void addFocusListeners(VoidCallback onFocusChange) {
    weightFocusNode.addListener(onFocusChange);
    repsFocusNode.addListener(onFocusChange);
  }

  void removeFocusListeners(VoidCallback onFocusChange) {
    weightFocusNode.removeListener(onFocusChange);
    repsFocusNode.removeListener(onFocusChange);
  }

  void updateWeight(double newWeight) {
    // Always mark as manually edited when user types, even if same value
    isWeightPrefilled = false;
    if (weight != newWeight) {
      weight = newWeight;
      final formatted = _formatWeight(newWeight);
      if (weightController.text != formatted) {
        weightController.text = formatted;
      }
    }
  }

  void updateReps(int newReps) {
    // Always mark as manually edited when user types, even if same value
    isRepsPrefilled = false;
    if (reps != newReps) {
      reps = newReps;
      if (repsController.text != newReps.toString()) {
        repsController.text = newReps.toString();
      }
    }
  }

  void dispose() {
    weightController.dispose();
    repsController.dispose();
    weightFocusNode.dispose();
    repsFocusNode.dispose();
  }
} 