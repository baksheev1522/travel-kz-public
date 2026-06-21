import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Путь: lib/core/widgets/story_viewer.dart
///
/// Использование в tour_detail_page.dart:
///
/// StoryViewer.show(
///   context: context,
///   images: tour.imageUrls,
///   initialIndex: _selectedCategory, // индекс нажатого кругляша
///   labels: ['Отель', 'Территория', 'Номер', 'Бассейн'],
/// );

class StoryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final List<String>? labels;

  const StoryViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.labels,
  });

  /// Удобный метод для открытия
  static void show({
    required BuildContext context,
    required List<String> images,
    int initialIndex = 0,
    List<String>? labels,
  }) {
    if (images.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => StoryViewer(
          images: images,
          initialIndex: initialIndex.clamp(0, images.length - 1),
          labels: labels,
        ),
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late int _current;
  late AnimationController _progressCtrl;
  bool _paused = false;

  static const _duration = Duration(milliseconds: 4500);

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _progressCtrl = AnimationController(vsync: this, duration: _duration);
    _startStory();
  }

  void _startStory() {
    _progressCtrl.forward(from: 0).then((_) {
      if (mounted && !_paused) _next();
    });
  }

  void _next() {
    if (_current < widget.images.length - 1) {
      setState(() => _current++);
      _startStory();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_current > 0) {
      setState(() => _current--);
      _startStory();
    } else {
      _startStory();
    }
  }

  void _pause() {
    _paused = true;
    _progressCtrl.stop();
  }

  void _resume() {
    _paused = false;
    _progressCtrl.forward().then((_) {
      if (mounted && !_paused) _next();
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final labels = widget.labels;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onTapUp: (d) {
          final x = d.globalPosition.dx;
          final w = MediaQuery.of(context).size.width;
          if (x < w / 3) _prev();
          else _next();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Фото ─────────────────────────────────────────────
            CachedNetworkImage(
              imageUrl: images[_current],
              fit: BoxFit.cover,
              placeholder: (_, __) => const ColoredBox(color: Colors.black),
              errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black26),
            ),

            // ── Затемнение сверху ─────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Затемнение снизу ──────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Прогресс-бары ─────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12, right: 12,
              child: Row(
                children: List.generate(images.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 2.5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: i < _current
                            ? const ColoredBox(color: Colors.white)
                            : i == _current
                                ? AnimatedBuilder(
                                    animation: _progressCtrl,
                                    builder: (_, __) => LinearProgressIndicator(
                                      value: _progressCtrl.value,
                                      backgroundColor: Colors.transparent,
                                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const SizedBox(),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Кнопка закрыть ────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),

            // ── Лейбл категории ───────────────────────────────────
            if (labels != null && _current < labels.length)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      labels[_current],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

            // ── Счётчик ───────────────────────────────────────────
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              right: 20,
              child: Text(
                '${_current + 1}/${images.length}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}