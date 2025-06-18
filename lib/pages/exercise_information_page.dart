import 'package:flutter/material.dart';
import 'package:gymfit/packages/exercise_information_repository/exercise_information_repository.dart';
import 'package:gymfit/pages/exercise_description_page.dart';

class ExerciseInformationPage extends StatelessWidget {
  const ExerciseInformationPage({super.key});

  Widget _buildExerciseCard(
    String title,
    dynamic icon, {
    bool isImage = false,
    String? mainMuscle,
  }) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isImage)
            Image.asset(
              icon as String,
              height: 80,
              width: 80,
              fit: BoxFit.contain,
            )
          else
            Icon(icon as IconData, size: 80, color: Colors.black),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          if (mainMuscle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                mainMuscle,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Exercise Information',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[300], height: 1.0),
        ),
      ),
      body: FutureBuilder<List<ExerciseInformation>>(
        future: ExerciseInformationRepository().getAllExerciseInformation(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          final sortedItems = List<ExerciseInformation>.from(items)..sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
          return Column(
            children: [
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1,
                  children:
                      sortedItems
                          .map(
                            (e) => GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (ctx) => ExerciseDescriptionPage(
                                          title: e.title,
                                          description: e.description,
                                          videoUrl: e.videoUrl,
                                          mainMuscle: e.mainMuscle,
                                          precautions: e.precautions,
                                          onAdd: () {
                                            ScaffoldMessenger.of(
                                              ctx,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${e.title} added to your plan',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                  ),
                                );
                              },
                              child: _buildExerciseCard(
                                e.title,
                                e.icon,
                                isImage: e.isImage,
                                mainMuscle: e.mainMuscle,
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Click on any exercise icon to view specific instructions.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
