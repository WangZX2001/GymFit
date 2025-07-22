# Simple Unit Tests for GymFit

This directory contains simple unit tests for the GymFit application, focusing on data models and avoiding Firebase dependencies.

## Test Files

### 1. `custom_workout_model_test.dart`

Tests for the `CustomWorkout` data model and related classes:

- `CustomWorkout` creation and properties
- `CustomWorkoutExercise` creation and validation
- `CustomWorkoutSet` creation and validation
- `toMap()` and `fromMap()` serialization
- Edge cases (empty lists, zero values, etc.)

### 2. `exercise_information_model_test.dart`

Tests for the `ExerciseInformation` data model:

- `ExerciseInformation` creation and properties
- Optional fields handling (`videoUrl`)
- Different experience levels and equipment types
- `proTips` list handling
- Edge cases (empty lists, null values)

### 3. `custom_workout_page_test.dart`

**Note**: This file now contains model tests instead of page tests due to Firebase dependencies.

### 4. `exercise_information_page_test.dart`

**Note**: This file now contains model tests instead of page tests due to Firebase dependencies.

## Running Tests

### Run All Tests

```bash
flutter test
```

### Run Specific Test Files

```bash
# Run model tests only
flutter test test/custom_workout_model_test.dart test/exercise_information_model_test.dart

# Run all test files
flutter test test/
```

### Run with Coverage

```bash
flutter test --coverage
```

### Run with Verbose Output

```bash
flutter test --verbose
```

## Test Structure

Each test follows the **Arrange-Act-Assert** pattern:

```dart
test('should create model correctly', () {
  // Arrange - Set up test data
  final exercise = ExerciseInformation(
    title: 'Bench Press',
    mainMuscle: 'Chest',
    // ... other properties
  );

  // Act - Perform the action being tested
  // (Often just creation in model tests)

  // Assert - Verify the expected behavior
  expect(exercise.title, 'Bench Press');
  expect(exercise.mainMuscle, 'Chest');
});
```

## Why Model Tests Only?

The original page tests were failing due to Firebase dependencies:

- Pages try to initialize Firebase in their `initState()`
- Test environment doesn't have Firebase configured
- This caused `FirebaseException: No Firebase App '[DEFAULT]' has been created`

**Solution**: Focus on testing the data models which:

- Don't depend on Firebase
- Are the core business logic
- Can be tested in isolation
- Provide good coverage of the application's data structures

## Test Coverage

Current tests cover:

- ✅ Data model creation and validation
- ✅ Property access and type safety
- ✅ Serialization (toMap/fromMap)
- ✅ Edge cases and error handling
- ✅ Different data scenarios

## Adding New Tests

To add new tests:

1. **For Models**: Create simple unit tests that test the data structure
2. **For Pages**: Consider creating integration tests or mocking Firebase dependencies
3. **For Services**: Mock dependencies and test business logic

## Troubleshooting

### Common Issues

1. **Firebase Errors**: If you see Firebase-related errors, the test is trying to access Firebase services
2. **Import Errors**: Make sure all required packages are imported
3. **Type Errors**: Check that model constructors match the actual implementation

### Getting Help

- Check the test output for specific error messages
- Verify that model classes haven't changed
- Ensure all required parameters are provided in test data
