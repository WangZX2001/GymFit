import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

class WorkoutNameEditor extends StatefulWidget {
  final String? initialWorkoutName;
  final String currentWorkoutName;
  final bool isEditing;
  final bool showInAppBar;
  final VoidCallback onToggleEditing;
  final Function(String) onNameChanged;
  final VoidCallback onSubmitted;

  const WorkoutNameEditor({
    super.key,
    this.initialWorkoutName,
    required this.currentWorkoutName,
    required this.isEditing,
    required this.showInAppBar,
    required this.onToggleEditing,
    required this.onNameChanged,
    required this.onSubmitted,
  });

  @override
  State<WorkoutNameEditor> createState() => _WorkoutNameEditorState();
}

class _WorkoutNameEditorState extends State<WorkoutNameEditor> {
  late TextEditingController _workoutNameController;
  late FocusNode _workoutNameFocusNode;

  @override
  void initState() {
    super.initState();
    _workoutNameController = TextEditingController(
      text: widget.initialWorkoutName ?? '',
    );
    _workoutNameFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _workoutNameController.dispose();
    _workoutNameFocusNode.dispose();
    super.dispose();
  }

  void _handleToggleEditing() {
    if (widget.isEditing) {
      // Save the workout name and exit editing mode
      widget.onNameChanged(_workoutNameController.text.trim());
      widget.onToggleEditing();
    } else {
      // Start editing mode
      _workoutNameController.text = widget.currentWorkoutName;
      widget.onToggleEditing();
      
      // Request focus after setState to ensure TextField is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _workoutNameFocusNode.canRequestFocus) {
          _workoutNameFocusNode.requestFocus();
        }
      });
    }
  }

  void _handleSubmitted() {
    widget.onNameChanged(_workoutNameController.text.trim());
    widget.onToggleEditing();
    widget.onSubmitted();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    if (widget.showInAppBar) {
      return SizedBox(
        key: const ValueKey('workout-name-app-bar'),
        height: 20,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.tag,
              color: Colors.purple,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.currentWorkoutName,
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      );
    }

    // Remove Card and Padding for direct-on-page look
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const FaIcon(
          FontAwesomeIcons.tag,
          color: Colors.purple,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workout Name',
                style: TextStyle(
                  fontSize: 12,
                  color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              widget.isEditing
                  ? TextField(
                      controller: _workoutNameController,
                      focusNode: _workoutNameFocusNode,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.purple),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.purple,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: 'Enter workout name',
                        hintStyle: TextStyle(
                          color: themeService.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                      maxLength: 50,
                      onSubmitted: (_) => _handleSubmitted(),
                      textInputAction: TextInputAction.done,
                    )
                  : GestureDetector(
                      onTap: _handleToggleEditing,
                      child: SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            widget.currentWorkoutName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
        IconButton(
          onPressed: _handleToggleEditing,
          icon: Icon(
            widget.isEditing ? Icons.check : Icons.edit,
            color: Colors.purple,
            size: 20,
          ),
        ),
      ],
    );
  }
} 