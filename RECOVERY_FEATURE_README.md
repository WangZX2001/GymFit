# Recovery Feature Implementation

## Overview
The recovery feature implements an advanced muscle recovery model that tracks and displays recovery status for different muscle groups based on workout history. This feature helps users understand when their muscles are ready for training and when they need rest.

## Features Implemented

### 1. Exponential Recovery Decay Function
- **Formula**: `recovery(t) = 100 × (1 - e^(-k × t))`
- **Where**: 
  - `t` = time since last muscle group was trained (in hours)
  - `k` = recovery rate constant (varies based on fatigue, volume, etc.)
  - `recovery(t)` caps at 100%

This exponential model provides more realistic recovery curves compared to linear models, with fast initial recovery that tapers off over time.

### 2. Dynamic k Value Based on Training Load & Fatigue
- **Formula**: `k = base_k / log(load + 1)`
- **Where**:
  - `base_k = 0.2` (configurable constant)
  - `load` = training load (sets × weight × reps)
  - Higher training load = slower recovery (smaller k value)

The dynamic k value ensures that heavier training sessions result in longer recovery times.

### 3. Fatigue Accumulation / Overtraining Damping
- **Fatigue Factor**: Applied when cumulative weekly volume exceeds baseline
- **Formula**: `fatigue_factor = 0.8` if `total_weekly_volume > baseline_volume × 1.5`
- **Effect**: Slows recovery when muscles are overworked

This prevents overtraining by reducing recovery rates when fatigue accumulates.

## Implementation Details

### Models
- **`MuscleGroup`**: Represents a muscle group with recovery data
- **`RecoveryData`**: Container for all muscle group recovery data
- **`RecoveryCalculator`**: Static class with recovery calculation logic

### Services
- **`RecoveryService`**: Manages recovery data persistence and calculation
  - Calculates recovery based on workout history
  - Stores data in Firestore
  - Provides real-time updates via listeners

### UI Components
- **`RecoveryPage`**: Main recovery status page
  - Displays recovery percentages for all muscle groups
  - Shows progress bars with color-coded status
  - Provides recovery tips and insights
  - Includes refresh functionality

## Muscle Group Mapping
The system automatically maps exercises to muscle groups based on exercise names:

- **Chest**: bench, chest, fly
- **Biceps**: curl, bicep
- **Triceps**: tricep, pushdown, skull
- **Shoulders**: shoulder, press, raise
- **Back**: row, pulldown, lat
- **Quadriceps**: squat, leg, press
- **Hamstrings**: deadlift, hamstring
- **Calves**: calf, gastro
- **Core**: abs, core, crunch
- **Other**: Unrecognized exercises

## Recovery Status Categories
- **Ready (80-100%)**: Green - Muscle is fully recovered
- **Moderate (60-79%)**: Orange - Some recovery still needed
- **Needs Rest (40-59%)**: Red-Orange - Significant recovery needed
- **Rest Required (0-39%)**: Red - Muscle needs complete rest

## Data Flow
1. User completes a workout
2. `RecoveryService` processes workout data
3. Training loads are calculated per muscle group
4. Recovery percentages are computed using exponential decay
5. Fatigue scores are calculated based on weekly volume
6. Data is stored in Firestore
7. UI updates to reflect current recovery status

## Usage
1. Navigate to the "Me" page
2. Tap the "Recovery" button
3. View recovery status for all muscle groups
4. Use the refresh button to recalculate data
5. Follow recovery tips for optimal training

## Technical Notes
- Recovery data is recalculated automatically every hour
- Manual refresh forces immediate recalculation
- Data persists across app sessions
- Real-time updates via listener pattern
- Handles edge cases (no workouts, missing data, etc.)

## Future Enhancements
The current implementation focuses on the core recovery model. Future versions could include:
- Sleep quality integration
- User-reported soreness tracking
- HRV/RHR readiness signals
- Smart rest day suggestions
- Periodization logic
- Custom recovery thresholds 