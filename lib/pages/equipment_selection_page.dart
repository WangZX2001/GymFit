import 'package:flutter/material.dart';

class EquipmentSelectionPage extends StatefulWidget {
  final Set<String> initialSelected;
  
  const EquipmentSelectionPage({
    super.key,
    required this.initialSelected,
  });

  @override
  State<EquipmentSelectionPage> createState() => _EquipmentSelectionPageState();
}

class _EquipmentSelectionPageState extends State<EquipmentSelectionPage> {
  late Set<String> selectedEquipment;

  final List<String> equipmentTypes = [
    'Barbell',
    'Dumbbell',
    'Machine',
    'Cable',
    'Bodyweight',
    'Resistance Band',
    'Kettlebell',
    'Medicine Ball',
    'TRX',
    'Pull-up Bar',
    'Bench',
    'Smith Machine',
  ];

  final Map<String, String> equipmentDescriptions = {
    'Barbell': 'Olympic barbells and standard barbells',
    'Dumbbell': 'Free weights for unilateral training',
    'Machine': 'Weight machines and apparatus',
    'Cable': 'Cable machines and pulley systems',
    'Bodyweight': 'No equipment needed',
    'Resistance Band': 'Elastic resistance bands',
    'Kettlebell': 'Cast iron or steel weights',
    'Medicine Ball': 'Weighted balls for functional training',
    'TRX': 'Suspension training system',
    'Pull-up Bar': 'Fixed or doorway pull-up bars',
    'Bench': 'Flat, incline, or decline benches',
    'Smith Machine': 'Guided barbell system',
  };

  final Map<String, IconData> equipmentIcons = {
    'Barbell': Icons.fitness_center,
    'Dumbbell': Icons.sports_gymnastics,
    'Machine': Icons.precision_manufacturing,
    'Cable': Icons.cable,
    'Bodyweight': Icons.accessibility_new,
    'Resistance Band': Icons.sports,
    'Kettlebell': Icons.sports_handball,
    'Medicine Ball': Icons.sports_basketball,
    'TRX': Icons.sports_martial_arts,
    'Pull-up Bar': Icons.horizontal_rule,
    'Bench': Icons.weekend,
    'Smith Machine': Icons.construction,
  };

  @override
  void initState() {
    super.initState();
    selectedEquipment = Set.from(widget.initialSelected);
  }

  void _toggleSelection(String equipment) {
    setState(() {
      if (selectedEquipment.contains(equipment)) {
        selectedEquipment.remove(equipment);
      } else {
        selectedEquipment.add(equipment);
      }
    });
  }

  void _selectAll() {
    setState(() {
      selectedEquipment = Set.from(equipmentTypes);
    });
  }

  void _clearAll() {
    setState(() {
      selectedEquipment.clear();
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
          'Equipment',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: selectedEquipment.isEmpty ? null : _clearAll,
            child: Text(
              'Clear',
              style: TextStyle(
                color: selectedEquipment.isEmpty ? Colors.grey : Colors.red,
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
                'All Equipment',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Include exercises for all equipment types'),
              value: selectedEquipment.length == equipmentTypes.length,
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
          // Individual equipment types
          Expanded(
            child: ListView.separated(
              itemCount: equipmentTypes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final equipment = equipmentTypes[index];
                final isSelected = selectedEquipment.contains(equipment);
                
                return Container(
                  color: Colors.white,
                  child: ListTile(
                    leading: Icon(
                      equipmentIcons[equipment],
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                    title: Text(
                      equipment,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      equipmentDescriptions[equipment] ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        _toggleSelection(equipment);
                      },
                      activeColor: Colors.blue,
                    ),
                    onTap: () {
                      _toggleSelection(equipment);
                    },
                  ),
                );
              },
            ),
          ),
          // Selected count and Apply button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (selectedEquipment.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      '${selectedEquipment.length} equipment type${selectedEquipment.length == 1 ? '' : 's'} selected',
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
                      Navigator.pop(context, selectedEquipment.toList());
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