import 'dart:async';

import 'package:flutter/material.dart';

import '../models/service.dart';
import 'service_card.dart';

class FeaturedServicesCarousel extends StatefulWidget {
  final List<Service> services;
  final List<Color> cardColors;
  const FeaturedServicesCarousel({Key? key, required this.services, required this.cardColors}) : super(key: key);

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
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: service.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(service.imagePath!, fit: BoxFit.cover),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  service.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ServiceCard(service: service, backgroundColor: color),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.services.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentPage ? Theme.of(context).primaryColor : Colors.grey.shade300,
              ),
            );
          }),
        ),
      ],
    );
  }
}
