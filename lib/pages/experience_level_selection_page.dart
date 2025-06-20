import 'package:flutter/material.dart';

class ExperienceLevelSelectionPage extends StatefulWidget {
  final Set<String> initialSelected;
  
  const ExperienceLevelSelectionPage({
    super.key,
    required this.initialSelected,
  });

  @override
  State<ExperienceLevelSelectionPage> createState() => _ExperienceLevelSelectionPageState();
}

class _ExperienceLevelSelectionPageState extends State<ExperienceLevelSelectionPage> {
  late Set<String> selectedLevels;

  final List<String> experienceLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  final Map<String, String> levelDescriptions = {
    'Beginner': 'New to fitness or this exercise type',
    'Intermediate': 'Some experience with fitness and exercises',
    'Advanced': 'Experienced with complex movements and high intensity',
  };

  final Map<String, IconData> levelIcons = {
    'Beginner': Icons.fitness_center,
    'Intermediate': Icons.trending_up,
    'Advanced': Icons.emoji_events,
  };

  @override
  void initState() {
    super.initState();
    selectedLevels = Set.from(widget.initialSelected);
  }

  void _toggleSelection(String level) {
    setState(() {
      if (selectedLevels.contains(level)) {
        selectedLevels.remove(level);
      } else {
        selectedLevels.add(level);
      }
    });
  }

  void _selectAll() {
    setState(() {
      selectedLevels = Set.from(experienceLevels);
    });
  }

  void _clearAll() {
    setState(() {
      selectedLevels.clear();
    });
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Experience Level',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: selectedLevels.isEmpty ? null : _clearAll,
            child: Text(
              'Clear',
              style: TextStyle(
                color: selectedLevels.isEmpty ? Colors.grey : Colors.red,
                fontSize: 20,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          // Select All option
          Container(
            color: Colors.white,
            child: CheckboxListTile(
              title: const Text(
                'All Levels',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Include exercises for all experience levels'),
              value: selectedLevels.length == experienceLevels.length,
              tristate: true,
              onChanged: (bool? value) {
                if (value == true) {
                  _selectAll();
                } else {
                  _clearAll();
                }
              },
              activeColor: Colors.blue,
            ),
          ),
          const Divider(height: 1),
          // Individual experience levels
          Expanded(
            child: ListView.separated(
              itemCount: experienceLevels.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final level = experienceLevels[index];
                final isSelected = selectedLevels.contains(level);
                
                return Container(
                  color: Colors.white,
                  child: ListTile(
                    leading: Icon(
                      levelIcons[level],
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                    title: Text(
                      level,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      levelDescriptions[level] ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        _toggleSelection(level);
                      },
                      activeColor: Colors.blue,
                    ),
                    onTap: () {
                      _toggleSelection(level);
                    },
                  ),
                );
              },
            ),
          ),
          // Selected count and Apply button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
            child: Column(
              children: [
                if (selectedLevels.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      '${selectedLevels.length} level${selectedLevels.length == 1 ? '' : 's'} selected',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, selectedLevels.toList());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Apply Selection',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 