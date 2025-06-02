class StepModel {
  final String userId;
  final DateTime date;
  final int stepCount;
  bool isSynced;

  StepModel({
    required this.userId,
    required this.date,
    required this.stepCount,
    this.isSynced = false,
  });
}