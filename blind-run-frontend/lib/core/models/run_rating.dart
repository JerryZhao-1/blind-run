enum RunRating {
  good,
  average,
  bad,
}

extension RunRatingX on RunRating {
  static RunRating? fromBackendRating(int rating) {
    if (rating >= 5) {
      return RunRating.good;
    }
    if (rating <= 2) {
      return RunRating.bad;
    }
    return RunRating.average;
  }

  String get label => switch (this) {
        RunRating.good => '非常满意',
        RunRating.average => '基本满意',
        RunRating.bad => '需要改进',
      };

  int get backendRating => switch (this) {
        RunRating.good => 5,
        RunRating.average => 3,
        RunRating.bad => 1,
      };
}
