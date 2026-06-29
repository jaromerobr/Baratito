/// Identity verification (KYC) domain model.
library;

/// Status of a verification request. Tolerant to the exact enum strings.
enum VerifyStatus {
  pending,
  approved,
  rejected,
  unknown;

  static VerifyStatus fromString(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'pending':
      case 'in_review':
      case 'reviewing':
        return VerifyStatus.pending;
      case 'approved':
      case 'verified':
        return VerifyStatus.approved;
      case 'rejected':
      case 'denied':
        return VerifyStatus.rejected;
      default:
        return VerifyStatus.unknown;
    }
  }
}

class IdentityVerification {
  final String id;
  final String userId;
  final String? cedulaFrontPath;
  final String? cedulaBackPath;
  final String? selfiePath;
  final String? cedulaNumber;
  final String? ocrExtractedName;
  final double? faceMatchScore;
  final VerifyStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const IdentityVerification({
    required this.id,
    required this.userId,
    this.cedulaFrontPath,
    this.cedulaBackPath,
    this.selfiePath,
    this.cedulaNumber,
    this.ocrExtractedName,
    this.faceMatchScore,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
  });

  factory IdentityVerification.fromJson(Map<String, dynamic> json) {
    return IdentityVerification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cedulaFrontPath: json['cedula_front_path'] as String?,
      cedulaBackPath: json['cedula_back_path'] as String?,
      selfiePath: json['selfie_path'] as String?,
      cedulaNumber: json['cedula_number'] as String?,
      ocrExtractedName: json['ocr_extracted_name'] as String?,
      faceMatchScore: (json['face_match_score'] as num?)?.toDouble(),
      status: VerifyStatus.fromString(json['status'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
    );
  }
}
