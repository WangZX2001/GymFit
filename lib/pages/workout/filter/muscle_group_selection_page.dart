import 'package:flutter/material.dart';

class MuscleGroupSelectionPage extends StatefulWidget {
  final String title;
  final List<String> muscleGroups;
  final Set<String> initialSelected;
  final Map<String, List<String>>? subGroups;
  
  const MuscleGroupSelectionPage({
    super.key,
    required this.title,
    required this.muscleGroups,
    required this.initialSelected,
    this.subGroups,
  });

  @override
  State<MuscleGroupSelectionPage> createState() => _MuscleGroupSelectionPageState();
}

class _MuscleGroupSelectionPageState extends State<MuscleGroupSelectionPage> {
  late Set<String> selectedMuscles;
  Set<String> expandedGroups = {};

  @override
  void initState() {
    super.initState();
    selectedMuscles = Set.from(widget.initialSelected);
  }

  List<String> _getAllMuscleOptions() {
    List<String> allOptions = [];
    for (String muscle in widget.muscleGroups) {
      allOptions.add(muscle);
      if (widget.subGroups?.containsKey(muscle) == true) {
        allOptions.addAll(widget.subGroups![muscle]!);
      }
    }
    return allOptions;
  }

  void _toggleSelection(String muscle) {
    setState(() {
      if (selectedMuscles.contains(muscle)) {
        selectedMuscles.remove(muscle);
        
        // If this is a parent muscle, also remove all its sub-muscles
        if (widget.subGroups?.containsKey(muscle) == true) {
          for (String subMuscle in widget.subGroups![muscle]!) {
            selectedMuscles.remove(subMuscle);
          }
        }
      } else {
        selectedMuscles.add(muscle);
        
        // If this is a parent muscle, also add all its sub-muscles
        if (widget.subGroups?.containsKey(muscle) == true) {
          for (String subMuscle in widget.subGroups![muscle]!) {
            selectedMuscles.add(subMuscle);
          }
        }
        
        // If this is a sub-muscle, check if all siblings are selected to select parent
        _checkParentSelection(muscle);
      }
    });
  }

  void _checkParentSelection(String subMuscle) {
    // Find if this sub-muscle belongs to any parent
    widget.subGroups?.forEach((parent, subMuscles) {
      if (subMuscles.contains(subMuscle)) {
        // Check if all sub-muscles of this parent are selected
        bool allSelected = subMuscles.every((sm) => selectedMuscles.contains(sm));
        if (allSelected && !selectedMuscles.contains(parent)) {
          selectedMuscles.add(parent);
        } else if (!allSelected && selectedMuscles.contains(parent)) {
          selectedMuscles.remove(parent);
        }
      }
    });
  }

  void _toggleExpansion(String muscle) {
    setState(() {
      if (expandedGroups.contains(muscle)) {
        expandedGroups.remove(muscle);
      } else {
        expandedGroups.add(muscle);
      }
    });
  }

  void _selectAll() {
    setState(() {
      selectedMuscles = Set.from(_getAllMuscleOptions());
    });
  }

  void _clearAll() {
    setState(() {
      selectedMuscles.clear();
    });
  }

  bool _isParentMuscle(String muscle) {
    return widget.subGroups?.containsKey(muscle) == true;
  }

  Widget _buildMuscleItem(String muscle, {bool isSubMuscle = false}) {
    final isSelected = selectedMuscles.contains(muscle);
    final isParent = _isParentMuscle(muscle);
    final isExpanded = expandedGroups.contains(muscle);
    
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.only(
              left: isSubMuscle ? 48.0 : 16.0,
              right: 16.0,
            ),
            title: Row(
              children: [
                                 Expanded(
                   child: Text(
                     muscle,
                   ),
                 ),
                if (isParent)
                  GestureDetector(
                    onTap: () => _toggleExpansion(muscle),
                    child: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            value: isSelected,
            onChanged: (bool? value) {
              _toggleSelection(muscle);
            },
            activeColor: Colors.blue,
          ),
          if (isParent && isExpanded && widget.subGroups != null)
            ...widget.subGroups![muscle]!.map(
              (subMuscle) => _buildMuscleItem(subMuscle, isSubMuscle: true),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allOptions = _getAllMuscleOptions();
    
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: selectedMuscles.isEmpty ? null : _clearAll,
            child: Text(
              'Clear',
              style: TextStyle(
                color: selectedMuscles.isEmpty ? Colors.grey : Colors.red,
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
                'Select All',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              value: selectedMuscles.length == allOptions.length,
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
          // Individual muscle groups
          Expanded(
            child: ListView.separated(
              itemCount: widget.muscleGroups.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final muscle = widget.muscleGroups[index];
                return _buildMuscleItem(muscle);
              },
            ),
          ),
          // Selected count and Apply button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
            child: Column(
              children: [
                if (selectedMuscles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      '${selectedMuscles.length} selected',
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
                      Navigator.pop(context, selectedMuscles.toList());
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