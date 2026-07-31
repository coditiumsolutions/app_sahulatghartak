import 'dart:async';

import 'package:flutter/material.dart';

import '../models/service.dart';
import 'service_card.dart';

class FeaturedServicesCarousel extends StatefulWidget {
  final List<Service> services;
  final List<Color> cardColors;
  const FeaturedServicesCarousel({super.key, required this.services, required this.cardColors});

  @override
  State<FeaturedServicesCarousel> createState() => _FeaturedServicesCarouselState();
}

class _FeaturedServicesCarouselState extends State<FeaturedServicesCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (widget.services.isEmpty) return;
      final nextPage = (_currentPage + 1) % widget.services.length;
      _controller.animateToPage(nextPage, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.services.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.services.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final service = widget.services[index];
              final color = widget.cardColors[index % widget.cardColors.length];
              return Container(
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
                            child: service.imagePath != null
                                ? Image.asset(service.imagePath!, fit: BoxFit.cover)
                                : ServiceCard(service: service, backgroundColor: color),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    service.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Rs. ${service.startingPrice.toStringAsFixed(0)}',
                                    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.services.length, (index) {
            final active = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
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
