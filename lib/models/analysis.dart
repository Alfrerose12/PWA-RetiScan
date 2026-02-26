class Analysis {
  final String id;
  final String patientId;
  final String status; // PENDING | PROCESSING | COMPLETED | FAILED
  final DateTime createdAt;
  final dynamic result; // resultado cuando status==COMPLETED

  Analysis({
    required this.id,
    required this.patientId,
    required this.status,
    required this.createdAt,
    this.result,
  });

  bool get isPending => status == 'PENDING';
  bool get isProcessing => status == 'PROCESSING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
  bool get isFinished => isCompleted || isFailed;

  factory Analysis.fromJson(Map<String, dynamic> json) {
    return Analysis(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      result: json['result'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'result': result,
      };
}