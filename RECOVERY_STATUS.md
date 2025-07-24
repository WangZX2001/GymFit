# GymFit Recovery Status Calculation: Detailed Report

## Overview

**Recovery status** in GymFit represents how well each muscle group has recovered since its last workout. It is shown as a percentage (0–100%), where a higher percentage means the muscle is more ready for training, and a lower percentage means it still needs rest.

This system is designed to adapt to each user's unique training habits, body weight, and workout intensity, providing a personalized recovery curve for every muscle group.

---

## Key Factors in Recovery Calculation

1. **Workout Intensity**
   - The app estimates how hard you trained a muscle group by comparing the weight you lifted to your estimated 1RM (one-rep max).
   - Lifting closer to your 1RM causes a greater initial reduction in recovery.

2. **Recovery Reduction Curve**
   - The app analyzes your past workouts to determine how quickly your muscles typically recover.
   - It uses this data to create a personalized recovery curve, so your recovery rate adapts to your training habits.

3. **Time Since Last Trained**
   - Recovery percentage increases gradually over time, following your personal recovery curve.
   - The rate of recovery is muscle-specific (e.g., forearms recover faster than glutes).

4. **Compound vs. Isolation Exercises**
   - Compound exercises (like squats or bench press) cause a larger drop in recovery than isolation exercises (like curls).

5. **Fatigue Score**
   - High training volume or intensity slows down recovery.
   - The fatigue score is calculated by comparing your total training volume for a muscle group in the past week to your baseline for that muscle.
   - If your fatigue score is above 1.5, recovery is slowed by 20%.

---

## Calculation Steps (Technical)

### 1. Workout Data Aggregation
- The app fetches your workout history for the past week.
- Exercises are grouped by muscle group.
- For each muscle group, the app calculates:
  - **Total training load:** `sets × weight × reps` (for completed sets)
  - **Average weight and reps** per exercise

### 2. Fatigue Score Calculation
- For each muscle group, the app sums up your total training volume for the last 7 days.
- This is compared to a **baseline volume** (default or user-customized, and adjusted for your body weight).
- **Fatigue Score = (Weekly Volume for Muscle Group) / (Baseline Volume)**
- If fatigue score > 1.5, your recovery rate is slowed by 20%.

### 3. Initial Recovery Drop
- After a workout, the recovery percentage for each muscle group is recalculated.
- The drop is larger for:
  - Higher training loads
  - Higher intensity (closer to 1RM)
  - Compound exercises
- The minimum recovery can drop as low as 5% for very intense compound lifts (e.g., deadlifts), or stay higher for isolation/low-intensity exercises.

### 4. Time-Based Recovery (Personalized Recovery Curve)
- Recovery increases over time, following an exponential function:

  ```
  recovery(t) = initial_recovery + (100 - initial_recovery) × (1 - e^(-k × t))
  ```

  Where:
  - `initial_recovery` is the recovery right after your last workout (lower for harder/more intense workouts).
  - `k` is the rate constant, which is **personalized**:
    - It is based on the muscle's base rate, the type of exercise, and the effective training load.
    - It is **slowed down** if your fatigue score is high (i.e., if you have been training that muscle more than your baseline).

  **Personalization Details:**
  - Each muscle group has a base recovery rate (see `muscleRecoveryRates` in `RecoveryCalculator`).
  - The rate constant `k` is calculated as:
    ```
    k = (muscle_rate × exercise_multiplier) / log(effectiveLoad + 1)
    if fatigueScore > 1.5:
        k *= 0.8
    ```
  - This means if you train a muscle group more than your baseline, your recovery slows down (the curve flattens). If you train less, your recovery is faster (the curve steepens).

### 5. Compound Sessions
- If multiple workouts are performed within a short time (e.g., within 2 hours), they are grouped as a single session for recovery calculation.

### 6. Customization
- Users can set custom baselines for each muscle group.
- By default, baselines are adjusted for body weight (heavier users have higher baselines for large muscle groups).

---

## Multiple Exercises for the Same Muscle Group in a Single Workout

When you perform multiple exercises that target the same muscle group within a single workout session, GymFit combines their effects using a weighted approach:

- **All exercises for the muscle group are aggregated** for that session.
- For each exercise:
  - The app calculates the base load (`sets × weight × reps`) and an intensity multiplier (based on exercise type).
  - The effective load for each exercise is `base load × intensity multiplier`.
- The **total base load** for the muscle group is the sum of all base loads from relevant exercises.
- The app computes a **weighted average fatigue score curve** for the muscle group, where each exercise's contribution is weighted by its share of the total base load.
- The most intense exercise (highest intensity multiplier) is used to determine the minimum possible recovery after the session.
- The initial recovery drop and subsequent recovery curve for the muscle group are then calculated based on these aggregated values, ensuring that the combined effect of all exercises is reflected in the recovery percentage.
- This approach ensures that doing several different exercises for the same muscle group in one session results in a larger recovery drop than doing just one, and that the impact is proportional to the volume and intensity of each exercise.

---

## Updated Minimum Recovery Logic

### Minimum Recovery Thresholds
- **Initial Drop (First Workout in Session):**
  - The minimum recovery threshold (see table) is enforced only on the initial drop after a workout session. This prevents recovery from dropping too low in a single session.
- **Subsequent Workouts (Repeated Hits Before Full Recovery):**
  - For additional workouts performed before the muscle group has fully recovered, the minimum threshold is not enforced. Instead, recovery can drop as low as 5% ("hard floor").
  - This allows the app to reflect real fatigue and warn users about under-recovered muscles, supporting future injury-prevention features.

### Updated Equations

**Initial Recovery Drop (First Workout in Session):**
```
initial_recovery = max(100 - ((trainingLoad / workoutLoad) × intensityMultiplier), minRecovery)
```
- `minRecovery` is the minimum allowed for the exercise type (see table).

**Reduced Recovery (Subsequent Workouts in Same Session):**
```
reduced_recovery = max(currentRecovery - (currentRecovery × fatigueScoreCurve), 5)
```
- The minimum allowed is now 5% for repeated hits, regardless of exercise type.

**Summary:**
- The minimum recovery threshold is only enforced on the initial drop after a workout session.
- For repeated workouts before full recovery, recovery can drop further, but never below 5%.

---

## Next Best Day to Train: Optimal Training Window

To help users plan their workouts, GymFit now displays the "Next optimal training window" for each muscle group. This feature estimates when your recovery percentage will cross a target threshold (default: 80%), indicating the best time to train that muscle group again for optimal results.

### How It Works
- For each muscle group, the app calculates how many hours from now it will take for your recovery percentage to reach or exceed 80%.
- If your recovery is already above 80%, the app shows: **"Ready for optimal training now"**.
- Otherwise, it shows: **"Next optimal training window: In X hours"** (or in days and hours if more than 24h).

### Formula
The time to reach the threshold is estimated by solving the exponential recovery equation for time:

```
recovery(t) = current + (100 - current) × (1 - e^(-k × t))

Solve for t when recovery(t) = threshold:

threshold = current + (100 - current) × (1 - e^(-k × t))
(threshold - current) / (100 - current) = 1 - e^(-k × t)
e^(-k × t) = 1 - (threshold - current) / (100 - current)
t = -ln(1 - (threshold - current) / (100 - current)) / k
```
- `current` = current recovery percentage
- `threshold` = target recovery percentage (default: 80)
- `k` = personalized recovery rate constant (see earlier sections)
- The app subtracts the hours since the muscle was last trained, so the countdown reflects time from now.

### UI Behavior
- This information is shown directly below the recovery progress bar for each muscle group on the Recovery Status page.
- If the muscle group is already ready, a green check and "Ready for optimal training now" is shown.
- Otherwise, a blue clock icon and the estimated time remaining is displayed.

This feature helps users avoid overtraining and plan their sessions for maximum effectiveness.

---

## Example Recovery Rates

- **Fast (24–48h):** Forearms, calves, core, neck
- **Moderate (48–72h):** Biceps, triceps, shoulders
- **Slow (72–96h):** Chest, back, legs, glutes

---

## Default Values and Thresholds

### Muscle-Specific Recovery Rates
| Muscle Group  | Recovery Rate | Typical Recovery Time |
|--------------|--------------|----------------------|
| Forearms     | 0.35         | 24–36h (fast)        |
| Calves       | 0.32         | 24–36h (fast)        |
| Core         | 0.30         | 24–48h (fast)        |
| Neck         | 0.28         | 24–48h (fast)        |
| Biceps       | 0.25         | 48–72h (moderate)    |
| Triceps      | 0.23         | 48–72h (moderate)    |
| Shoulders    | 0.22         | 48–72h (moderate)    |
| Chest        | 0.18         | 48–96h (slow)        |
| Back         | 0.16         | 72–96h (slow)        |
| Quadriceps   | 0.15         | 72–96h (slow)        |
| Hamstrings   | 0.14         | 72–96h (slow)        |
| Glutes       | 0.13         | 72–96h (slow)        |
| Other        | 0.20         | Default              |

### Default Muscle Baselines (Weekly Volume)
| Muscle Group  | Baseline Volume |
|--------------|-----------------|
| Chest        | 12,000          |
| Back         | 15,000          |
| Quadriceps   | 20,000          |
| Hamstrings   | 12,000          |
| Shoulders    | 8,000           |
| Biceps       | 6,000           |
| Triceps      | 6,000           |
| Calves       | 3,000           |
| Core         | 4,000           |
| Glutes       | 8,000           |
| Forearms     | 8,000           |
| Neck         | 8,000           |
| Other        | 8,000           |

### Muscle Group Workout Loads (Per Session)
| Muscle Group  | Workout Load |
|--------------|--------------|
| Chest        | 3,000        |
| Back         | 4,000        |
| Quadriceps   | 5,000        |
| Hamstrings   | 2,800        |
| Shoulders    | 1,200        |
| Biceps       | 540          |
| Triceps      | 720          |
| Calves       | 2,700        |
| Core         | 1,200        |
| Glutes       | 4,000        |
| Forearms     | 4,000        |
| Neck         | 2,000        |
| Other        | 2,500        |

### Minimum Recovery Thresholds by Exercise Type
| Exercise Type (contains) | Minimum Recovery (%) |
|-------------------------|----------------------|
| deadlift, squat, clean, snatch | 5    |
| bench, press, row, pulldown    | 10   |
| curl, extension, fly, raise    | 20   |
| crunch, plank, stretch         | 50   |
| (default)                     | 15   |

---

## Code References

- **Core logic:** `lib/services/recovery_service.dart` (see `calculateRecoveryData`)
- **Calculation engine:** `lib/models/recovery.dart` (see `RecoveryCalculator`)
- **User explanation:** `lib/pages/me/recovery_help_page.dart`

---

## User-Facing Explanation (from the App)

> - **Workout intensity:** The app estimates how hard you trained a muscle group by comparing the weight you lifted to your 1RM (one-rep max). Lifting closer to your 1RM causes a greater initial reduction in recovery.
> - **Recovery reduction curve:** The app analyzes your past workouts to determine how quickly your muscles typically recover. It uses this data to create a personalized recovery curve, so your recovery rate adapts to your training habits.
> - **Time since last trained:** Recovery percentage increases gradually over time, following your personal recovery curve.
> - **Compound vs. isolation:** Compound exercises (like squats or bench press) cause a larger drop in recovery than isolation exercises (like curls).
> - **Fatigue score:** High training volume or intensity slows down recovery.

---

## Tips for Optimizing Recovery

- Focus on muscle groups with low recovery percentages before training them again.
- Allow extra rest for muscle groups with high fatigue scores.
- Compound lifts require more recovery time.
- Monitor your weekly training volume and adjust baselines as needed.
- Listen to your body—recovery is individual and can vary.

---

## Summary: How Personalization Works

- The **recovery curve adapts** to your training habits by using your actual weekly training volume (fatigue score) and your body weight (for baseline adjustment).
- If you train a muscle group more than your baseline, your recovery slows down (the curve flattens).
- If you train less, your recovery is faster (the curve steepens).
- The curve is also shaped by the type and intensity of exercises you perform.

**In short:**
The app uses your recent workout history (volume, intensity, frequency) to adjust the speed of your recovery curve for each muscle group, making it unique to your habits and body. 