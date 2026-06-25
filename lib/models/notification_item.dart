class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final bool isRead;
}
