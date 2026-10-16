import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RetivaNotificationItem {
  final String id;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String message;
  final String timeAgo;
  final String badge;
  final Color badgeColor;
  final Color badgeTextColor;
  bool isUnread;

  RetivaNotificationItem({
    required this.id,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.badge,
    required this.badgeColor,
    required this.badgeTextColor,
    this.isUnread = true,
  });
}

class NotificationBellWidget extends StatefulWidget {
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;

  const NotificationBellWidget({
    super.key,
    this.iconColor,
    this.backgroundColor,
    this.size = 34,
  });

  /// Reactive Notifier untuk update real-time di seluruh navbar aplikasi
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  /// Daftar notifikasi persisten di memori (dimulai kosong tanpa dummy)
  static final List<RetivaNotificationItem> notifications = [];

  static int get unreadCount => unreadCountNotifier.value;

  static void _syncCount() {
    unreadCountNotifier.value = notifications.where((n) => n.isUnread).length;
  }

  /// Dipanggil ketika dokter selesai menelaah kasus secara nyata
  static void incrementUnread({String? doctorName}) {
    final doc = (doctorName != null && doctorName.isNotEmpty)
        ? doctorName
        : 'dr. Yunani Setyandriana, Sp.M';

    final notif = RetivaNotificationItem(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      icon: Icons.verified_user_rounded,
      iconBg: const Color(0xFFEFF6FF),
      iconColor: AppColors.primary,
      title: 'Hasil Telaah Dokter Sp.M Siap',
      message:
          '$doc telah menyelesaikan telaah & menandatangani rekomendasi klinis hasil skrining Anda.',
      timeAgo: 'Baru saja',
      badge: 'Klinis Prioritas',
      badgeColor: const Color(0xFFEFF6FF),
      badgeTextColor: AppColors.primary,
      isUnread: true,
    );

    notifications.insert(0, notif);
    _syncCount();
  }

  /// Menambah notifikasi baru secara dinamis
  static void addNotification(RetivaNotificationItem item) {
    notifications.insert(0, item);
    _syncCount();
  }

  /// Menandai semua notifikasi telah dibaca
  static void markAllAsRead() {
    for (var n in notifications) {
      n.isUnread = false;
    }
    _syncCount();
  }

  /// Menandai satu notifikasi telah dibaca
  static void markAsRead(String id) {
    for (var n in notifications) {
      if (n.id == id) {
        n.isUnread = false;
        break;
      }
    }
    _syncCount();
  }

  @override
  State<NotificationBellWidget> createState() => _NotificationBellWidgetState();
}

class _NotificationBellWidgetState extends State<NotificationBellWidget> {
  void _openNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final unread = NotificationBellWidget.unreadCount;
            final notifs = NotificationBellWidget.notifications;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Drag Handle
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Pusat Notifikasi',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unread Baru',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (unread > 0)
                          TextButton(
                            onPressed: () {
                              NotificationBellWidget.markAllAsRead();
                              setSheetState(() {});
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Tandai Dibaca',
                              style: TextStyle(
                                  fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Divider(color: Color(0xFFF1F5F9)),
                  ),

                  // Scrollable Notifications List or Empty State
                  Flexible(
                    child: notifs.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 36),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Belum Ada Notifikasi',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Pemberitahuan hasil skrining dan konfirmasi telaah dokter spesialis mata akan ditampilkan di sini.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            itemCount: notifs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, idx) {
                              final notif = notifs[idx];
                              return _buildNotificationCard(notif, setSheetState);
                            },
                          ),
                  ),

                  // Bottom Close Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF334155),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(RetivaNotificationItem item, StateSetter setSheetState) {
    return InkWell(
      onTap: () {
        if (item.isUnread) {
          NotificationBellWidget.markAsRead(item.id);
          setSheetState(() {});
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.isUnread ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                item.isUnread ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
            width: item.isUnread ? 1.2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.badgeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.badge,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: item.badgeTextColor,
                          ),
                        ),
                      ),
                      Text(
                        item.timeAgo,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.message,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (item.isUnread) ...[
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationBellWidget.unreadCountNotifier,
      builder: (context, count, _) {
        return InkWell(
          onTap: () => _openNotificationSheet(context),
          borderRadius: BorderRadius.circular(9999),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ?? const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: widget.size * 0.55,
                    color: widget.iconColor ?? const Color(0xFF334155),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
