class EyeAnalysis {
  final String id;
  final DateTime date;
  final String status;
  final String imagePath;
  final Map<String, String> medicalInfo;

  EyeAnalysis({
    required this.id,
    required this.date,
    required this.status,
    required this.imagePath,
    required this.medicalInfo,
  });
}