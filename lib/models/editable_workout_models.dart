import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Input formatter to restrict decimals to a fixed number of places (default 2)
class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({this.decimalRange = 2}) : assert(decimalRange > 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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

// Model to track individual set data for editing
class EditableExerciseSet {
  final String id;
  double weight;
  int reps;
  bool isChecked;
  late final TextEditingController weightController;
  late final TextEditingController repsController;
  late final FocusNode weightFocusNode;
  late final FocusNode repsFocusNode;
  
  // Selection tracking for tap behavior
  bool weightSelected = false;
  bool repsSelected = false;
  
  // Helper to format weight: whole number if no decimal part
  static String _formatWeight(double value) {
    if (value % 1 == 0) {
      // Whole number – show without decimal
      return value.toInt().toString();
    }
    return value.toString();
  }
  
  static int _counter = 0;
  
  EditableExerciseSet({this.weight = 0.0, this.reps = 0, this.isChecked = false}) 
    : id = '${DateTime.now().millisecondsSinceEpoch}_${++_counter}' {
    weightController = TextEditingController(text: _formatWeight(weight));
    repsController = TextEditingController(text: reps.toString());
    weightFocusNode = FocusNode();
    repsFocusNode = FocusNode();
  }
  
  void updateWeight(double newWeight) {
    if (weight != newWeight) {
      weight = newWeight;
      final formatted = _formatWeight(newWeight);
      if (weightController.text != formatted) {
        weightController.text = formatted;
      }
    }
  }
  
  void updateReps(int newReps) {
    if (reps != newReps) {
      reps = newReps;
      if (repsController.text != newReps.toString()) {
        repsController.text = newReps.toString();
      }
    }
  }
  
  // Get formatted previous data (similar to ExerciseSet)
  String get previousDataFormatted {
    if (weight > 0 && reps > 0) {
      final weightStr = weight % 1 == 0 ? weight.toInt().toString() : weight.toString();
      return '$weightStr × $reps';
    }
    return '—';
  }
  
  void dispose() {
    weightController.dispose();
    repsController.dispose();
    weightFocusNode.dispose();
    repsFocusNode.dispose();
  }
}

// Model to track exercise with multiple sets for editing
class EditableExercise {
  final String title;
  List<EditableExerciseSet> sets;
  EditableExercise({required this.title, List<EditableExerciseSet>? sets}) 
    : sets = sets ?? [EditableExerciseSet()];
} 