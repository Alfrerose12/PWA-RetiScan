class Analysis {
  final String id;
  final String patientId;
  final String status; // PENDING | PROCESSING | COMPLETED | FAILED
  final DateTime createdAt;
  final Map<String, dynamic>? aiResult;
  final String? doctorNotes;
  final String? imageUri;

  Analysis({
    required this.id,
    required this.patientId,
    required this.status,
    required this.createdAt,
    this.aiResult,
    this.doctorNotes,
    this.imageUri,
  });

  bool get isPending => status == 'PENDING';
  bool get isProcessing => status == 'PROCESSING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
  bool get isFinished => isCompleted || isFailed;

  factory Analysis.fromJson(Map<String, dynamic> json) {
    return Analysis(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? json['patientId'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
      aiResult: json['ai_result'] as Map<String, dynamic>? ?? json['aiResult'] as Map<String, dynamic>?,
      doctorNotes: json['doctor_notes'] as String? ?? json['doctorNotes'] as String?,
      imageUri: json['image_url'] as String? ?? json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'ai_result': aiResult,
        'doctor_notes': doctorNotes,
        'image_url': imageUri,
      };
}