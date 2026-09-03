import 'dart:async';

import 'package:flutter/material.dart';

import '../models/category.dart';
import '../utils/category_icons.dart';
import '../utils/category_images.dart';
import '../utils/motion.dart';

class FeaturedServicesCarousel extends StatefulWidget {
  final List<Category> categories;
  final List<Color> cardColors;
  final ValueChanged<Category> onTapCategory;

  const FeaturedServicesCarousel({super.key, required this.categories, required this.cardColors, required this.onTapCategory});

  @override
  State<FeaturedServicesCarousel> createState() => _FeaturedServicesCarouselState();
}

class _FeaturedServicesCarouselState extends State<FeaturedServicesCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (widget.categories.isEmpty || _reduceMotion) return;
      final nextPage = (_currentPage + 1) % widget.categories.length;
      _controller.animateToPage(nextPage, duration: kSlowAnimDuration, curve: kEmphasizedCurve);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = prefersReducedMotion(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.categories.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final category = widget.categories[index];
              final color = widget.cardColors[index % widget.cardColors.length];
              final imagePath = getCategoryImage(category.name);
              return GestureDetector(
                onTap: () => widget.onTapCategory(category),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 8))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            double offset = 0;
                            if (_controller.position.haveDimensions) {
                              final page = _controller.page ?? _controller.initialPage.toDouble();
                              offset = (page - index).clamp(-1.0, 1.0) * 24;
                            }
                            return Transform.translate(offset: Offset(offset, 0), child: child);
                          },
                          child: Transform.scale(
                            scale: 1.08,
                            child: imagePath != null
                                ? Image.asset(imagePath, fit: BoxFit.cover)
                                : Container(
                                    color: color.withValues(alpha: 0.12),
                                    alignment: Alignment.center,
                                    child: Icon(getCategoryIcon(category.name), size: 64, color: color),
                                  ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.65)],
                              ),
                            ),
                            child: Text(
                              category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.categories.length, (index) {
            final active = index == _currentPage;
            return AnimatedContainer(
              duration: _reduceMotion ? Duration.zero : kMediumAnimDuration,
              curve: kStandardCurve,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: active ? Theme.of(context).primaryColor : Colors.grey.shade300,
              ),
            );
          }),
        ),
      ],
    );
  }
}
