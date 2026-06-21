import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/bonus_service.dart';
import '../../../auth/bloc/auth_bloc.dart';
import 'dart:convert';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});


  void _showFullPhoto(BuildContext context, ImageProvider image) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (dialogContext) => GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: ClipOval(
            child: Image(
              image: image,
              width: 280,
              height: 280,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state is AuthAuthenticatedState ? state.user : null;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            title: const Text('Профиль',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => context.push(AppRoutes.editProfile),
                tooltip: 'Редактировать',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      StreamBuilder<DocumentSnapshot>(
  stream: uid != null
      ? FirebaseFirestore.instance
          .collection('users').doc(uid).snapshots()
      : const Stream.empty(),
  builder: (context, snap) {
    final data = snap.data?.data() as Map<String, dynamic>?;
    final base64 = data?['avatarBase64'] as String?;
    ImageProvider? image;
    if (base64 != null && base64.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(base64));
      } catch (_) {}
    }
    return GestureDetector(
      onTap: image == null ? null : () => _showFullPhoto(context, image!),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        backgroundImage: image,
        child: image == null
            ? Text(
                user?.name.isNotEmpty == true
                    ? user!.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  },
),
                      const SizedBox(height: 10),
                      Text(
                        user?.name ?? 'Путешественник',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Bonus card (реальные бонусы из Firestore) ────
                StreamBuilder<DocumentSnapshot>(
                  stream: uid != null
                      ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .snapshots()
                      : const Stream.empty(),
                  builder: (context, snap) {
                    final bonuses = snap.hasData && snap.data!.exists
                        ? ((snap.data!.data()
                                as Map<String, dynamic>)['bonusPoints'] ??
                            0) as int
                        : user?.bonusPoints ?? 0;

                    return Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A6FE8), Color(0xFF00C9A7)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Мои бонусы',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.white70)),
                              const SizedBox(height: 4),
                              Text(
                                '${_fmt(bonuses.toDouble())} ₸',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const Text('Доступно для оплаты тура',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.stars_rounded,
                                color: Colors.white, size: 30),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // ── Stats row ────────────────────────────────────
                StreamBuilder<QuerySnapshot>(
                  stream: uid != null
                      ? FirebaseFirestore.instance
                          .collection('bookings')
                          .where('userId', isEqualTo: uid)
                          .snapshots()
                      : const Stream.empty(),
                  builder: (context, snap) {
                    final bookings = snap.data?.docs ?? [];
                    final active = bookings
                        .where((d) =>
                            (d.data() as Map)['status'] == 'pending' ||
                            (d.data() as Map)['status'] == 'confirmed')
                        .length;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _StatCard(
                            label: 'Поездок',
                            value: '${bookings.length}',
                            icon: Icons.luggage_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: 'Активных',
                            value: '$active',
                            icon: Icons.flight_takeoff_outlined,
                            color: const Color(0xFF00897B),
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: 'Уровень',
                            value: _level(bookings.length),
                            icon: Icons.workspace_premium_outlined,
                            color: const Color(0xFFF57C00),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ── My trips ─────────────────────────────────────
                _Section(
                  title: 'Мои поездки',
                  items: [
                    _Item(
                      icon: Icons.luggage_outlined,
                      color: AppColors.primary,
                      label: 'Мои бронирования',
                      onTap: () => context.push(AppRoutes.myBookings),
                    ),
                    _Item(
                      icon: Icons.favorite_outline,
                      color: AppColors.error,
                      label: 'Избранное',
                      onTap: () => context.go(AppRoutes.wishlist),
                    ),
                    _Item(
                      icon: Icons.notifications_outlined,
                      color: const Color(0xFFFF6B35),
                      label: 'Охотник за турами',
                      onTap: () => context.go(AppRoutes.tourHunter),
                    ),
                  ],
                ),

                // ── Account ──────────────────────────────────────
                _Section(
                  title: 'Аккаунт',
                  items: [
                    _Item(
                      icon: Icons.person_outline,
                      color: AppColors.grey600,
                      label: 'Редактировать профиль',
                      onTap: () => context.push(AppRoutes.editProfile),
                    ),
                    _Item(
                      icon: Icons.chat_bubble_outline,
                      color: AppColors.grey600,
                      label: 'AI ассистент',
                      onTap: () => context.push(AppRoutes.aiAssistant),
                    ),
                    _Item(
                      icon: Icons.help_outline,
                      color: AppColors.grey600,
                      label: 'Помощь и поддержка',
                      onTap: () => _showHelp(context),
                    ),
                    _Item(
                      icon: Icons.info_outline,
                      color: AppColors.grey600,
                      label: 'О приложении',
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),

                // ── Logout ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _Section(
                    title: '',
                    items: [
                      _Item(
                        icon: Icons.logout,
                        color: AppColors.error,
                        label: 'Выйти из аккаунта',
                        labelColor: AppColors.error,
                        showChevron: false,
                        onTap: () => _showLogout(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  String _level(int bookings) {
    if (bookings >= 10) return 'Gold';
    if (bookings >= 5) return 'Silver';
    return 'Basic';
  }

  void _showLogout(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Выйти?'),
      content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () {
            Navigator.pop(dialogContext);
            context.read<AuthBloc>().add(AuthSignOutEvent());
          },
          child: const Text('Выйти'),
        ),
      ],
    ),
  );
}

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.travel_explore,
                size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text('TravelKZ', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 4),
            Text('Версия 1.0.0',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.grey500)),
            const SizedBox(height: 8),
            Text(
              'Сервис планирования путешествий\nи туристических рекомендаций',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Помощь и поддержка',
                style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            _HelpRow(
              icon: Icons.chat_bubble_outline,
              title: 'AI ассистент',
              subtitle: 'Задайте вопрос нашему AI помощнику',
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.aiAssistant);
              },
            ),
            const Divider(height: 20),
            _HelpRow(
              icon: Icons.email_outlined,
              title: 'Email поддержки',
              subtitle: 'support@travelkz.kz',
              onTap: () {},
            ),
            const Divider(height: 20),
            _HelpRow(
              icon: Icons.phone_outlined,
              title: 'Телефон',
              subtitle: '+7 (777) 123-45-67',
              onTap: () {},
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Stat Card
// ═══════════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                )),
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey500)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Section
// ═══════════════════════════════════════════════════════════════════
class _Section extends StatelessWidget {
  final String title;
  final List<_Item> items;

  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(title,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500)),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((e) {
                return Column(
                  children: [
                    e.value,
                    if (e.key < items.length - 1)
                      const Divider(height: 1, indent: 54, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Item
// ═══════════════════════════════════════════════════════════════════
class _Item extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Color? labelColor;
  final bool showChevron;
  final VoidCallback onTap;

  const _Item({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: AppTextStyles.bodyLarge.copyWith(
            color: labelColor ?? AppColors.grey900,
          )),
      trailing: showChevron
          ? const Icon(Icons.chevron_right, color: AppColors.grey400)
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Help Row
// ═══════════════════════════════════════════════════════════════════
class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.grey400),
        ],
      ),
    );
  }
}