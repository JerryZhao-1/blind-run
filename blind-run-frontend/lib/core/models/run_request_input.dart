import 'package:aidrun_demo/core/models/place_suggestion.dart';

class RunRequestInput {
  const RunRequestInput({
    required this.place,
    required this.timeLabel,
    this.notes = '',
    this.transcript = '',
    this.usedFallback = false,
  });

  final PlaceSuggestion place;
  final String timeLabel;
  final String notes;
  final String transcript;
  final bool usedFallback;

  String get location => place.name;
}
