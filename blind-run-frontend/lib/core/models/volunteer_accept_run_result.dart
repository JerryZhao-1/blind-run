import 'package:aidrun_demo/core/models/run.dart';

class VolunteerAcceptRunResult {
  const VolunteerAcceptRunResult._({
    this.run,
    this.message,
  });

  const VolunteerAcceptRunResult.confirmed(Run run)
    : this._(run: run, message: null);

  const VolunteerAcceptRunResult.failed(String message)
    : this._(run: null, message: message);

  final Run? run;
  final String? message;

  bool get isConfirmed => run != null;
}
