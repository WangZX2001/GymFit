class OneRMCalculator {
  /// Calculate 1RM using the Brzycki formula
  static double brzycki(double weight, int reps) {
    if (reps == 1) return weight;
    if (reps > 10) reps = 10; // Cap for accuracy
    return weight * (36 / (37 - reps));
  }
} 