import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/services/custom_workout_configuration_state_manager.dart';

// Formatter to limit decimal places (2 by default)
class _DecimalTextInputFormatter extends TextInputFormatter {
  _DecimalTextInputFormatter({this.decimalRange = 2}) : assert(decimalRange > 0);

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

class CustomWorkoutSetRow extends StatefulWidget {
  final ConfigSet set;
  final int setIndex;
  final bool preventAutoFocus;
  final VoidCallback onWeightChanged;
  final VoidCallback onRepsChanged;
  final VoidCallback onRemoveSet;

  const CustomWorkoutSetRow({
    super.key,
    required this.set,
    required this.setIndex,
    required this.preventAutoFocus,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onRemoveSet,
  });

  @override
  State<CustomWorkoutSetRow> createState() => _CustomWorkoutSetRowState();
}

class _CustomWorkoutSetRowState extends State<CustomWorkoutSetRow> {
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('set_${widget.set.id}'),
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
      onDismissed: (direction) {
        widget.onRemoveSet();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(2),
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final isSmallScreen = availableWidth < 350;
            final spacing = isSmallScreen ? 6.0 : 8.0;
            
            return Row(
              children: [
                // Set number - fixed small width
                SizedBox(
                  width: isSmallScreen ? 35 : 45,
                  child: Center(
                    child: Text(
                      '${widget.setIndex + 1}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
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
                      widget.set.previousDataFormatted,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
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
                        controller: widget.set.weightController,
                        focusNode: widget.set.weightFocusNode,
                        autofocus: false,
                        canRequestFocus: !widget.preventAutoFocus,
                        readOnly: widget.preventAutoFocus,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                          color: widget.set.isWeightPrefilled 
                              ? Colors.grey.shade500 
                              : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 3 : 4,
                            vertical: 0,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [_DecimalTextInputFormatter(decimalRange: 2)],
                        onTap: () {
                          // Mark as manually edited when user taps
                          setState(() {
                            widget.set.isWeightPrefilled = false;
                          });
                          
                          // Toggle selection state based on our tracking
                          if (widget.set.weightSelected) {
                            // Clear selection
                            widget.set.weightController.selection = TextSelection.collapsed(
                              offset: widget.set.weightController.text.length,
                            );
                            widget.set.weightSelected = false;
                          } else {
                            // Select all text
                            widget.set.weightController.selection = TextSelection(
                              baseOffset: 0, 
                              extentOffset: widget.set.weightController.text.length,
                            );
                            widget.set.weightSelected = true;
                          }
                        },
                        onChanged: (value) {
                          final newWeight = double.tryParse(value) ?? 0.0;
                          setState(() {
                            widget.set.updateWeight(newWeight);
                            widget.set.weightSelected = false; // Reset selection state when typing
                          });
                          widget.onWeightChanged();
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
                        controller: widget.set.repsController,
                        focusNode: widget.set.repsFocusNode,
                        autofocus: false,
                        canRequestFocus: !widget.preventAutoFocus,
                        enableInteractiveSelection: true,
                        readOnly: widget.preventAutoFocus,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                          color: widget.set.isRepsPrefilled 
                              ? Colors.grey.shade500 
                              : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          filled: false,
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
                          setState(() {
                            widget.set.isRepsPrefilled = false;
                          });
                          
                          // Toggle selection state based on our tracking
                          if (widget.set.repsSelected) {
                            // Clear selection
                            widget.set.repsController.selection = TextSelection.collapsed(
                              offset: widget.set.repsController.text.length,
                            );
                            widget.set.repsSelected = false;
                          } else {
                            // Select all text
                            widget.set.repsController.selection = TextSelection(
                              baseOffset: 0, 
                              extentOffset: widget.set.repsController.text.length,
                            );
                            widget.set.repsSelected = true;
                          }
                        },
                        onChanged: (value) {
                          final newReps = int.tryParse(value) ?? 0;
                          setState(() {
                            widget.set.updateReps(newReps);
                            widget.set.repsSelected = false; // Reset selection state when typing
                          });
                          widget.onRepsChanged();
                        },
                      ),
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