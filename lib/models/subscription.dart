class LocalSubscription {
  final String channelId;
  final String name;
  final String avatarUrl;
  final String subscriberCount;
  final DateTime subscribedAt;

  const LocalSubscription({
    required this.channelId,
    required this.name,
    required this.avatarUrl,
    this.subscriberCount = '',
    required this.subscribedAt,
  });

  Map<String, dynamic> toJson() => {
    'channelId': channelId,
    'name': name,
    'avatarUrl': avatarUrl,
    'subscriberCount': subscriberCount,
    'subscribedAt': subscribedAt.toIso8601String(),
  };

  factory LocalSubscription.fromJson(Map<String, dynamic> json) => LocalSubscription(
    channelId: json['channelId'] as String,
    name: json['name'] as String? ?? 'Channel',
    avatarUrl: json['avatarUrl'] as String? ?? '',
    subscriberCount: json['subscriberCount'] as String? ?? '',
    subscribedAt: json['subscribedAt'] != null
        ? DateTime.tryParse(json['subscribedAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}
