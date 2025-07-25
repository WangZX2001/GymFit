import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/models/custom_workout.dart';
import 'package:gymfit/services/custom_workout_service.dart';
import 'package:gymfit/services/theme_service.dart';

class WorkoutNameDescriptionPage extends StatefulWidget {
  final List<CustomWorkoutExercise> exercises;
  final CustomWorkout? existingWorkout;
  
  const WorkoutNameDescriptionPage({
    super.key,
    required this.exercises,
    this.existingWorkout,
  });

  @override
  State<WorkoutNameDescriptionPage> createState() => _WorkoutNameDescriptionPageState();
}

class _WorkoutNameDescriptionPageState extends State<WorkoutNameDescriptionPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // If editing an existing workout, pre-populate the fields
    if (widget.existingWorkout != null) {
      _nameController.text = widget.existingWorkout!.name;
      _descriptionController.text = widget.existingWorkout!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomWorkout() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.warning_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Please enter a workout name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.existingWorkout != null) {
        // Update existing workout
        await CustomWorkoutService.updateCustomWorkout(
          workoutId: widget.existingWorkout!.id,
          name: _nameController.text.trim(),
          exercises: widget.exercises,
          description: _descriptionController.text.trim().isNotEmpty 
              ? _descriptionController.text.trim() 
              : null,
        );
      } else {
        // Create new workout
        await CustomWorkoutService.saveCustomWorkout(
          name: _nameController.text.trim(),
          exercises: widget.exercises,
          description: _descriptionController.text.trim().isNotEmpty 
              ? _descriptionController.text.trim() 
              : null,
        );
      }

      if (mounted) {
        // Pop back to the custom workout page (2 levels up) with success result
        Navigator.of(context).pop(); // Pop the name/description page
        Navigator.of(context).pop(true); // Pop the configure workout page with result
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
          icon: Icon(
            Icons.arrow_back_ios,
            color: themeService.currentTheme.appBarTheme.foregroundColor
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Save Workout',
          style: TextStyle(
            color: themeService.currentTheme.appBarTheme.foregroundColor,
            fontWeight: FontWeight.bold
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveCustomWorkout,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.done,
                    color: themeService.currentTheme.appBarTheme.foregroundColor,
                    size: 24
                  ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Workout Name Input
            Card(
              color: themeService.currentTheme.cardTheme.color,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Workout Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: themeService.currentTheme.textTheme.titleMedium?.color,
                          ),
                        ),
                        const Text(
                          ' *',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter workout name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: themeService.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                        hintStyle: TextStyle(
                          color: themeService.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                        ),
                      ),
                      style: TextStyle(
                        color: themeService.currentTheme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description Input (Optional)
            Card(
              color: themeService.currentTheme.cardTheme.color,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.description,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: themeService.currentTheme.textTheme.titleMedium?.color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(Optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeService.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add a description for your workout...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: themeService.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                        hintStyle: TextStyle(
                          color: themeService.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                        ),
                      ),
                      style: TextStyle(
                        color: themeService.currentTheme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Workout Summary
            Card(
              color: themeService.currentTheme.cardTheme.color,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.dumbbell,
                          color: Colors.purple,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Workout Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: themeService.currentTheme.textTheme.titleMedium?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Exercise list - scrollable if needed
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: widget.exercises.length > 8 ? 200 : double.infinity,
                      ),
                      child: widget.exercises.length > 8
                          ? Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              thickness: 6,
                              radius: const Radius.circular(3),
                              trackVisibility: false,
                              child: ListView.builder(
                                controller: _scrollController,
                                shrinkWrap: true,
                                itemCount: widget.exercises.length,
                                itemBuilder: (context, index) {
                                  final exercise = widget.exercises[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Text(
                                      '${exercise.sets.length} x ${exercise.name}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: widget.exercises.map((exercise) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Text(
                                    '${exercise.sets.length} x ${exercise.name}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  ),
    );
  }
} 