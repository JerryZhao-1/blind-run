enum RunRating {
  good,
  average,
  bad,
}

extension RunRatingX on RunRating {
  String get label => switch (this) {
        RunRating.good => '非常满意',
        RunRating.average => '基本满意',
        RunRating.bad => '需要改进',
      };
}
