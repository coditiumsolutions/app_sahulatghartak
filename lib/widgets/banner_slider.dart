import 'package:flutter/material.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({Key? key}) : super(key: key);

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  final List<Map<String, String>> banners = const [
    {'title': 'Premium Home Services', 'subtitle': 'Trusted professionals at your doorstep'},
    {'title': 'Hygiene & Care', 'subtitle': 'Cleaning & sanitization experts'},
    {'title': 'Safe & Reliable', 'subtitle': 'Verified service providers'},
  ];

  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: _controller,
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final b = banners[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Container(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(b['title']!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(b['subtitle']!, style: const TextStyle(color: Colors.white70)),
              ]),
            ),
          );
        },
      ),
    );
  }
}
