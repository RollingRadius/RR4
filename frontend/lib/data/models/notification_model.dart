class NotificationModel {
  final String id;
  final String? tripId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String? createdAt;

  const NotificationModel({
    required this.id,
    this.tripId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id:        json['id']         as String,
      tripId:    json['trip_id']    as String?,
      type:      json['type']       as String,
      title:     json['title']      as String,
      body:      json['body']       as String,
      isRead:    json['is_read']    as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id, tripId: tripId, type: type, title: title,
    body: body, isRead: isRead ?? this.isRead, createdAt: createdAt,
  );
}
