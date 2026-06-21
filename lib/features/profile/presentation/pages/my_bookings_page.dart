import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/theme/app_theme.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['Все', 'Туры', 'Отели', 'Чартеры'];
  static const _types = [null, 'tour', 'hotel', 'charter'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _query(String? type) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    var q = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid);
    if (type != null) q = q.where('type', isEqualTo: type);
    return q;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Мои бронирования',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          _tabs.length,
          (i) => _BookingsList(query: _query(_types[i])),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Bookings List
// ═══════════════════════════════════════════════════════════════════
class _BookingsList extends StatelessWidget {
  final Query<Map<String, dynamic>> query;
  const _BookingsList({required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text('Ошибка загрузки',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.grey500)),
          );
        }

        final docs = List.of(snap.data?.docs ?? []);
        docs.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) return const _EmptyState();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: docs.length,
          itemBuilder: (_, i) => _BookingCard(
            data: docs[i].data(),
            bookingId: docs[i].id,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Booking Card
// ═══════════════════════════════════════════════════════════════════
class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingId;

  const _BookingCard({required this.data, required this.bookingId});

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  Future<void> _updateStatus(String status) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'status': status});
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить?'),
        content: const Text('Бронирование будет удалено навсегда.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .delete();
    }
  }

  void _showMenu(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            if (status == 'pending')
              ListTile(
                leading: const Icon(Icons.check_circle_outline,
                    color: Color(0xFF1565C0)),
                title: const Text('Подтвердить',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Ожидает → Подтверждено'),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateStatus('confirmed');
                },
              ),
            if (status == 'confirmed')
              ListTile(
                leading: const Icon(Icons.payment_outlined,
                    color: AppColors.success),
                title: const Text('Отметить оплаченным',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateStatus('paid');
                },
              ),
            if (status == 'pending' || status == 'confirmed' || status == 'paid')
              ListTile(
                leading: const Icon(Icons.flight_land_outlined,
                    color: Color(0xFF2E7D32)),
                title: const Text('Завершить',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Отметить как завершённое'),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateStatus('completed');
                },
              ),
            if (status != 'cancelled' && status != 'completed')
              ListTile(
                leading: const Icon(Icons.cancel_outlined,
                    color: AppColors.error),
                title: const Text('Отменить',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateStatus('cancelled');
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Удалить из списка',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _delete(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? 'tour';
    final status = data['status'] as String? ?? 'pending';
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final usedBonuses = (data['usedBonuses'] as num?)?.toInt() ?? 0;

    return Dismissible(
      key: Key(bookingId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Удалить?'),
          content: const Text('Бронирование будет удалено навсегда.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить'),
            ),
          ],
        ),
      ),
      onDismissed: (_) async {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .delete();
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Удалить',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
              child: Row(
                children: [
                  _TypeBadge(type: type),
                  const Spacer(),
                  _StatusBadge(status: status),
                  IconButton(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.grey500, size: 20),
                    onPressed: () => _showMenu(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: switch (type) {
                'hotel'   => _HotelContent(data: data),
                'charter' => _CharterContent(data: data),
                _         => _TourContent(data: data),
              },
            ),
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_fmt(price)} ₸',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.grey900,
                          )),
                      if (usedBonuses > 0)
                        Text('−${_fmt(usedBonuses.toDouble())} ₸ бонусами',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            )),
                    ],
                  ),
                  const Spacer(),
                  if (status == 'pending' || status == 'confirmed')
                    _ActionButton(
                      label: 'Связаться',
                      icon: Icons.chat_bubble_outline,
                      onTap: () => context.push('/ai-assistant'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Content widgets
// ═══════════════════════════════════════════════════════════════════
class _TourContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TourContent({required this.data});

  String _formatDep(dynamic raw) {
    if (raw == null) return '—';
    try {
      final d = DateTime.parse(raw as String);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final adults = (data['adults'] as num?)?.toInt() ?? 2;
    final children = (data['children'] as num?)?.toInt() ?? 0;
    final touristStr =
        children > 0 ? '$adults взр, $children дет' : '$adults взрослых';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data['hotelName'] as String? ?? '—',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('${data['country'] ?? ''}, ${data['city'] ?? ''}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.flight_takeoff, text: _formatDep(data['departureDate'])),
        const SizedBox(height: 4),
        _InfoRow(icon: Icons.nights_stay_outlined, text: '${data['nights'] ?? '?'} ночей'),
        const SizedBox(height: 4),
        _InfoRow(icon: Icons.people_outline, text: touristStr),
        const SizedBox(height: 4),
        _InfoRow(icon: Icons.restaurant_outlined, text: data['mealType'] as String? ?? '—'),
      ],
    );
  }
}

class _HotelContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HotelContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data['hotelName'] as String? ?? '—',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('${data['country'] ?? ''}, ${data['city'] ?? ''}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.calendar_today_outlined,
            text: '${data['checkIn'] ?? '?'} — ${data['checkOut'] ?? '?'}'),
        const SizedBox(height: 4),
        _InfoRow(icon: Icons.nights_stay_outlined, text: '${data['nights'] ?? '?'} ночей'),
        const SizedBox(height: 4),
        _InfoRow(icon: Icons.bed_outlined, text: data['roomType'] as String? ?? '—'),
        const SizedBox(height: 4),
        _InfoRow(icon: Icons.restaurant_outlined, text: data['mealType'] as String? ?? '—'),
      ],
    );
  }
}

class _CharterContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CharterContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final passengers = (data['passengers'] as num?)?.toInt() ?? 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(data['fromCity'] as String? ?? '—',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.flight, size: 16, color: AppColors.grey500),
            ),
            Text(data['toCity'] as String? ?? '—',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 2),
        Text(data['date'] as String? ?? '—',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.confirmation_number_outlined,
            text: 'Рейс: ${data['flightNumber'] ?? '—'}'),
        const SizedBox(height: 4),
        _InfoRow(icon: Icons.airline_seat_recline_normal_outlined,
            text: data['classType'] as String? ?? '—'),
        const SizedBox(height: 4),
        _InfoRow(icon: Icons.people_outline, text: '$passengers пассажира'),
        const SizedBox(height: 4),
        _InfoRow(icon: Icons.luggage_outlined, text: data['baggage'] as String? ?? '—'),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 15, color: AppColors.grey500),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey700)),
        ],
      );
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (type) {
      'hotel'   => (Icons.hotel_outlined, const Color(0xFF00897B), 'Отель'),
      'charter' => (Icons.flight_outlined, const Color(0xFF7B1FA2), 'Чартер'),
      _         => (Icons.beach_access_outlined, AppColors.primary, 'Тур'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'confirmed' => (const Color(0xFF1565C0), 'Подтверждено'),
      'paid'      => (const Color(0xFF2E7D32), 'Оплачено'),
      'completed' => (AppColors.grey500, 'Завершено'),
      'cancelled' => (AppColors.error, 'Отменено'),
      _           => (const Color(0xFFF57C00), 'Ожидает'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary,
              )),
            ],
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                color: AppColors.grey100, shape: BoxShape.circle,
              ),
              child: const Icon(Icons.luggage_outlined,
                  size: 40, color: AppColors.grey400),
            ),
            const SizedBox(height: 16),
            const Text('Нет бронирований',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.grey700)),
            const SizedBox(height: 6),
            Text('Забронируйте тур, отель или чартер',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.go('/home'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Найти тур',
                    style: TextStyle(color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
}