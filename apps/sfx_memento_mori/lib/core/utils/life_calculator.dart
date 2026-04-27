import 'dart:math';

/// Calculates life statistics based on birth date and target age.
class LifeCalculator {
  const LifeCalculator._();

  /// Returns the total number of weeks for a given target age.
  static int calculateTotalWeeks(int targetAge) {
    return targetAge * 52;
  }

  /// Returns the number of weeks that have elapsed since birth.
  static int calculateWeeksElapsed(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    return max(0, difference.inDays ~/ 7);
  }

  /// Returns the number of weeks remaining until target age.
  static int calculateWeeksRemaining(DateTime birthDate, int targetAge) {
    final totalWeeks = calculateTotalWeeks(targetAge);
    final elapsedWeeks = calculateWeeksElapsed(birthDate);
    return max(0, totalWeeks - elapsedWeeks);
  }

  /// Returns the index of the current week (0-based).
  static int calculateCurrentWeekIndex(DateTime birthDate) {
    final elapsedWeeks = calculateWeeksElapsed(birthDate);
    return max(0, elapsedWeeks - 1);
  }

  /// Returns the number of days remaining until target age.
  static int calculateDaysRemaining(DateTime birthDate, int targetAge) {
    final now = DateTime.now();
    final targetDate = birthDate.add(Duration(days: targetAge * 365));
    final diff = targetDate.difference(now);
    return max(0, diff.inDays);
  }

  /// Returns the current age in full years and remaining months.
  static (int years, int months) getElapsedYearsAndMonths(DateTime birthDate) {
    final now = DateTime.now();
    var years = now.year - birthDate.year;
    var months = now.month - birthDate.month;
    if (months < 0) {
      years--;
      months += 12;
    }
    if (now.day < birthDate.day) {
      months--;
      if (months < 0) {
        years--;
        months += 12;
      }
    }
    years = max(0, years);
    months = max(0, months);
    return (years, months);
  }

  /// Returns the current age in years (based on elapsed weeks).
  static int getCurrentAge(int elapsedWeeks) {
    return elapsedWeeks ~/ 52;
  }

  /// Returns a summary of life statistics.
  static LifeStats getLifeStats(DateTime birthDate, int targetAge) {
    final totalWeeks = calculateTotalWeeks(targetAge);
    final elapsedWeeks = calculateWeeksElapsed(birthDate);
    final remainingWeeks = max(0, totalWeeks - elapsedWeeks);
    final currentWeekIndex = calculateCurrentWeekIndex(birthDate);
    final remainingDays = calculateDaysRemaining(birthDate, targetAge);
    final (elapsedYears, elapsedMonths) =
        getElapsedYearsAndMonths(birthDate);
    final currentAge = getCurrentAge(elapsedWeeks);
    return LifeStats(
      birthDate: birthDate,
      targetAge: targetAge,
      totalWeeks: totalWeeks,
      elapsedWeeks: elapsedWeeks,
      remainingWeeks: remainingWeeks,
      remainingDays: remainingDays,
      elapsedYears: elapsedYears,
      elapsedMonths: elapsedMonths,
      currentAge: currentAge,
      currentWeekIndex: currentWeekIndex,
    );
  }
}

class LifeStats {
  final DateTime birthDate;
  final int targetAge;
  final int totalWeeks;
  final int elapsedWeeks;
  final int remainingWeeks;
  final int remainingDays;
  final int elapsedYears;
  final int elapsedMonths;
  final int currentAge;
  final int currentWeekIndex;

  const LifeStats({
    required this.birthDate,
    required this.targetAge,
    required this.totalWeeks,
    required this.elapsedWeeks,
    required this.remainingWeeks,
    this.remainingDays = 0,
    this.elapsedYears = 0,
    this.elapsedMonths = 0,
    this.currentAge = 0,
    this.currentWeekIndex = 0,
  });

  double get completionPercentage {
    if (totalWeeks == 0) return 0;
    return elapsedWeeks / totalWeeks;
  }
}
