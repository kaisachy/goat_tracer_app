class MessageModel {
  final int id;
  final int farmerId;
  final int? adminId;
  final String senderRole;
  final String body;
  final String status;
  final DateTime createdAt;
  final String? attachmentPath;
  final String? attachmentType;
  final String? attachmentOriginalName;
  final String? farmerFirstName;
  final String? farmerLastName;
  final String? adminFirstName;
  final String? adminLastName;

  MessageModel({
    required this.id,
    required this.farmerId,
    this.adminId,
    required this.senderRole,
    required this.body,
    required this.status,
    required this.createdAt,
    this.attachmentPath,
    this.attachmentType,
    this.attachmentOriginalName,
    this.farmerFirstName,
    this.farmerLastName,
    this.adminFirstName,
    this.adminLastName,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      farmerId: json['farmer_id'] is int
          ? json['farmer_id'] as int
          : int.parse(json['farmer_id'].toString()),
      adminId: json['admin_id'] == null
          ? null
          : (json['admin_id'] is int
              ? json['admin_id'] as int
              : int.tryParse(json['admin_id'].toString())),
      senderRole: json['sender_role']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unread',
      createdAt: DateTime.parse(json['created_at'].toString()),
      attachmentPath: json['attachment_path']?.toString(),
      attachmentType: json['attachment_type']?.toString(),
      attachmentOriginalName: json['attachment_original_name']?.toString(),
      farmerFirstName: json['farmer_first_name']?.toString(),
      farmerLastName: json['farmer_last_name']?.toString(),
      adminFirstName: json['admin_first_name']?.toString(),
      adminLastName: json['admin_last_name']?.toString(),
    );
  }

  bool get isFromFarmer => senderRole == 'farmer';

  String? attachmentUrl(String baseUrl) {
    final path = attachmentPath;
    if (path == null || path.isEmpty) return null;
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    // Use API download endpoint so backend can control filename via headers.
    return '$normalizedBase/api/messages/attachment?id=$id';
  }

  String get displayName {
    if (isFromFarmer) {
      final first = farmerFirstName ?? '';
      final last = farmerLastName ?? '';
      final full = '$first $last'.trim();
      return full.isEmpty ? 'Farmer' : full;
    } else {
      final first = adminFirstName ?? '';
      final last = adminLastName ?? '';
      final full = '$first $last'.trim();
      return full.isEmpty ? 'Admin' : full;
    }
  }
}


