# Recommended Training System Documentation

## Overview

The **Recommended Training System** in GymFit is an intelligent, personalized workout plan generator. It creates weekly training plans tailored to each user's body data, fitness goals, experience level, and medical conditions. The system leverages user data, exercise metadata, and workout history to provide optimal exercise selection, set/reps/weight recommendations, and a seamless user experience.

---

## User Flow

1. **Access**: Users navigate to the "Recommended Training" section from the main Workout page.
2. **Questionnaire**: Users answer a short questionnaire:
   - Days per week to train
   - Preferred training days (or no preference)
   - Preferred training split (Full Body, Upper/Lower, Push/Pull/Legs)
3. **Personalization**: The system fetches user body data (goal, fitness level, age, BMI, medical condition, etc.) from Firestore.
4. **Plan Generation**: A weekly plan is generated, with each day assigned a split and a set of exercises, each with personalized sets, reps, and weights.
5. **Review**: Users review the plan, see their profile summary, and can tap any day to start the workout.
6. **Workout Session**: The selected day's workout launches in the Quick Start interface, with a timer, exercise cards, and set tracking.
7. **Completion**: After finishing, users see a summary (time, sets, calories, breakdown) and the workout is saved to their history.

---

## Exercise Selection Logic by Split and Level

The system uses detailed tables to determine the number and type of exercises for each training day, based on the user's selected split and fitness level. It also tries to avoid repeating the same exercise within the same week for each split.

### Push (Push/Pull/Legs Split)
| Level        | Chest | Shoulders | Triceps | Total Exercises |
|--------------|-------|-----------|---------|----------------|
| Beginner     | 2     | 1         | 1       | 4–5            |
| Intermediate | 2     | 1–2       | 1–2     | 5–6            |
| Advanced     | 2–3   | 2         | 2       | 6–8            |

### Pull (Push/Pull/Legs Split)
| Level        | Back | Biceps | Rear Delts | Total Exercises |
|--------------|------|--------|------------|----------------|
| Beginner     | 2–3  | 1      | 0–1        | 4–5            |
| Intermediate | 3    | 1–2    | 1          | 5–6            |
| Advanced     | 3–4  | 2      | 1          | 6–8            |

### Legs (Push/Pull/Legs Split)
| Level        | Quads | Hamstrings | Glutes | Calves | Total Exercises |
|--------------|-------|------------|--------|--------|----------------|
| Beginner     | 1     | 1          | 1      | 0–1    | 3–5            |
| Intermediate | 2     | 1–2        | 1      | 1      | 5–6            |
| Advanced     | 2     | 2          | 1–2    | 1      | 6–8            |

### Upper (Upper/Lower Split)
| Level        | Chest | Back | Shoulders | Biceps | Triceps | Total Exercises |
|--------------|-------|------|-----------|--------|---------|----------------|
| Beginner     | 1     | 1    | 1         | 1      | 1       | 4–5            |
| Intermediate | 2     | 2    | 1         | 1      | 1       | 6–7            |
| Advanced     | 2     | 2    | 2         | 1–2    | 1–2     | 7–8            |

### Lower (Upper/Lower Split)
| Level        | Quads | Hamstrings | Glutes | Calves | Total Exercises |
|--------------|-------|------------|--------|--------|----------------|
| Beginner     | 1     | 1          | 1      | 0–1    | 3–5            |
| Intermediate | 2     | 2          | 1      | 1      | 5–6            |
| Advanced     | 2     | 2          | 2      | 1      | 6–8            |

### Full Body (Full Body Split)
| Level        | Lower Body | Upper Pull | Upper Push | Accessory | Total Exercises |
|--------------|------------|------------|------------|-----------|----------------|
| Beginner     | 1          | 1          | 1          | 0–1       | 3–4            |
| Intermediate | 1–2        | 1          | 1–2        | 1         | 5–6            |
| Advanced     | 2          | 2          | 2          | 1         | 6–7            |

#### Muscle Group Definitions
- **Lower Body:** Quads, Hamstrings, Glutes, Calves
- **Upper Pull:** Back, Biceps, Rear Delts
- **Upper Push:** Chest, Shoulders, Triceps
- **Accessory:** Abs, Core, Forearms, Neck, Traps, (Calves if not already used)

#### Uniqueness
- The system tries to avoid repeating the same exercise for a given split within the same week. If there are not enough unique exercises, it will fill remaining slots with available ones, prioritizing uniqueness, and allow repeats only if necessary to meet the minimum per muscle group.

---

## Data Models

### User Data (Firestore: `users` collection)
- `goal`: e.g., "Gain Muscle", "Lose Weight"
- `fitness level`: "Beginner", "Intermediate", "Advance"
- `medical condition`: e.g., "None", "High Blood Pressure"
- `age`, `bmi`, `gender`, `height`

### Exercise Information (`lib/packages/exercise_information_repository/exercise_information_repository.dart`)
- `title`, `mainMuscle`, `secondaryMuscle`, `experienceLevel`, `equipment`, `howTo`, `description`, `videoUrl`, `proTips`

### CustomWorkout & CustomWorkoutExercise (`lib/models/custom_workout.dart`)
- `CustomWorkoutExercise`: `{ name, sets: [CustomWorkoutSet] }`
- `CustomWorkoutSet`: `{ weight, reps }`
- `CustomWorkout`: `{ id, name, exercises, createdAt, userId, pinned, description }`

### QuickStartExercise (`lib/models/quick_start_exercise.dart`)
- Used for launching a workout session: `{ title, sets: [ExerciseSet] }`

### ExerciseSet (`lib/models/exercise_set.dart`)
- `{ weight, reps, isChecked, ...UI state }`

---

## Backend Logic

### Main Service: `RecommendedTrainingService` (`lib/services/recommended_training_service.dart`)

- **getUserBodyData()**: Fetches user profile from Firestore.
- **generateRecommendedWeekPlan()**: Core function. Steps:
  1. Fetch user data and all exercise info.
  2. Filter exercises by fitness level, medical condition, age, BMI.
  3. Shuffle for variety.
  4. For each day, select exercises for the split and level using the above tables.
  5. Avoid repeats for the same split within the week.
  6. For each exercise, generate sets with personalized reps/weight:
     - Uses user's 1RM (from workout history) if available, else body weight, else generic defaults.
     - Adjusts for goal (muscle gain, weight loss, endurance, strength) and fitness level.
     - Progressive set schemes (pyramid, reverse pyramid, etc.).
- **generateRecommendedWorkout()**: Legacy compatibility; flattens week plan into a single workout.

#### Personalization Details
- **1RM Calculation**: Uses Brzycki formula (`lib/utils/one_rm_calculator.dart`).
- **Set/Rep/Weight Logic**: Adjusts based on goal, fitness level, exercise type, and user data.
- **Medical Condition Filtering**: Avoids unsafe exercises for conditions like high blood pressure, bone injuries, flu, etc.

---

## UI Integration

### Entry Point: `WorkoutPage` (`lib/pages/workout/workout_page.dart`)
- "Recommended Training" card navigates to `RecommendedTrainingPage`.

### Main UI: `RecommendedTrainingPage` (`lib/pages/workout/recommended_training_page.dart`)
- **Questionnaire**: Days/week, preferred days, split.
- **User Profile Card**: Shows goal, level, age, BMI, condition.
- **Week Plan View**: Each day shows split, exercises, and set/rep/weight breakdown.
- **Start Workout**: Tapping a day launches the session in `QuickStartPageOptimized`.
- **Motivational Chatbot**: AI-style feedback via `Chatbot` component.

### Workout Session: `QuickStartPageOptimized` (`lib/pages/workout/quick_start_page_optimized.dart`)
- Timer, exercise cards, set tracking, reordering, finish button.
- Minimized overlay (`QuickStartOverlay`) for persistent session state.

### Completion: `WorkoutSummaryPage` (`lib/pages/workout/workout_summary_page.dart`)
- Shows stats, calories, breakdown, and "Done" button.

---

## Extensibility & Customization

- **Adding/Editing Tables**: Update the tables and logic in `generateRecommendedWeekPlan()`.
- **New Medical Conditions**: Extend `_isExerciseSafeForCondition()`.
- **Exercise Metadata**: Add to Firestore `exercise_information` collection.
- **Personalization**: Enhance set/rep/weight logic for more goals or user attributes.

---

## Developer Usage

- **Backend**: All logic is in `lib/services/recommended_training_service.dart`.
- **UI**: Main entry is `RecommendedTrainingPage`. To launch programmatically, call `RecommendedTrainingService.generateRecommendedWeekPlan()`.
- **Data**: Ensure user profile and exercise information are populated in Firestore.

---

## Example: Adding a New Training Split

1. In `generateRecommendedWeekPlan()`, add a new `else if (trainingSplit == 'Your New Split')` block.
2. Define the muscle group mapping and table for each day.
3. Optionally, update the questionnaire UI to include the new split.

---

## References
- `lib/services/recommended_training_service.dart`
- `lib/pages/workout/recommended_training_page.dart`
- `lib/models/custom_workout.dart`
- `lib/packages/exercise_information_repository/exercise_information_repository.dart`
- `lib/models/quick_start_exercise.dart`
- `lib/models/exercise_set.dart`
- `lib/pages/workout/quick_start_page_optimized.dart`
- `lib/components/quick_start_overlay.dart`
- `lib/pages/workout/workout_summary_page.dart`

---

## FAQ

**Q: Can users edit recommended workouts?**
A: Not directly; for full customization, use the Custom Workout feature.

**Q: How is safety ensured for users with medical conditions?**
A: Unsafe exercises are filtered out based on user profile (see `_isExerciseSafeForCondition`).

**Q: How are weights and reps determined?**
A: Based on user 1RM (if available), body weight, goal, fitness level, and exercise type.

---

## Screenshots

*(Add screenshots of the questionnaire, week plan, and workout session for visual reference.)* 