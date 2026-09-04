import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/service_catalog_provider.dart';
import '../utils/category_icons.dart';
import '../utils/category_images.dart';
import '../utils/service_catalog_style.dart';
import '../utils/service_colors.dart';
import '../utils/breakpoints.dart';
import '../utils/guest_guard.dart';
import '../utils/motion.dart';
import '../widgets/decorative_glow_circle.dart';
import '../widgets/featured_services_carousel.dart';
import '../widgets/main_category_card.dart';
import 'service_request_form_screen.dart';

import '../widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  /// True when hosted inside [MainNavigationShell], which already provides
  /// the bottom navigation bar.
  final bool embedded;

  const HomeScreen({super.key, this.embedded = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';

  final LayerLink _searchLink = LayerLink();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  OverlayEntry? _suggestionsOverlay;

  static const _brandDark = Color(0xFF0A4FA8);
  static const _brandBlue = Color(0xFF016EE3);
  static const _brandAccent = Color(0xFF4FC3F7);
  static const _ink = Color(0xFF14213D);

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeSuggestionsOverlay();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      _removeSuggestionsOverlay();
    } else {
      _updateSuggestionsOverlay();
    }
  }

  void _onQueryChanged(String value) {
    setState(() => _searchQuery = value);
    _updateSuggestionsOverlay();
  }

  /// Ranks [categories] against the query so exact/prefix/word-start matches
  /// (e.g. "paint" matching "Paint Services") outrank categories that merely
  /// contain the query as a substring elsewhere in the name. Ties within the
  /// same rank break by where the match starts (earlier is better), never by
  /// unrelated name length.
  List<Category> _matchingCategories(List<Category> categories) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final scored = <MapEntry<Category, List<int>>>[];
    for (final category in categories) {
      final name = category.name.toLowerCase();
      final matchIndex = name.indexOf(query);
      if (matchIndex == -1) continue;

      final int rank;
      if (name == query) {
        rank = 0;
      } else if (matchIndex == 0) {
        rank = 1;
      } else if (RegExp('\\b${RegExp.escape(query)}').hasMatch(name)) {
        rank = 2;
      } else {
        rank = 3;
      }
      scored.add(MapEntry(category, [rank, matchIndex]));
    }

    scored.sort((a, b) {
      final rankCompare = a.value[0].compareTo(b.value[0]);
      if (rankCompare != 0) return rankCompare;
      return a.value[1].compareTo(b.value[1]);
    });
    return scored.map((e) => e.key).take(6).toList();
  }

  void _updateSuggestionsOverlay() {
    final shouldShow =
        _searchFocusNode.hasFocus && _searchQuery.trim().isNotEmpty;

    if (!shouldShow) {
      _removeSuggestionsOverlay();
      return;
    }

    if (_suggestionsOverlay == null) {
      // The builder recomputes matches on every rebuild (rather than
      // capturing a snapshot list), so markNeedsBuild() below always shows
      // results for the current query instead of the query at entry-creation
      // time.
      _suggestionsOverlay = OverlayEntry(
        builder: (context) => _SearchSuggestionsOverlay(
          link: _searchLink,
          matches:
              _matchingCategories(context.read<CategoryProvider>().categories),
          onTap: _onSuggestionTap,
        ),
      );
      Overlay.of(context).insert(_suggestionsOverlay!);
    } else {
      _suggestionsOverlay!.markNeedsBuild();
    }
  }

  void _removeSuggestionsOverlay() {
    _suggestionsOverlay?.remove();
    _suggestionsOverlay = null;
  }

  Future<void> _onSuggestionTap(Category category) async {
    _searchFocusNode.unfocus();
    _removeSuggestionsOverlay();
    _searchController.text = category.name;
    setState(() => _searchQuery = category.name);
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
    final color = styleForServiceName(category.serviceName, 0).color;
    Navigator.of(context).pushNamed(
      ServiceRequestFormScreen.routeName,
      arguments: ServiceRequestFormArgs(category: category, color: color),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _onQueryChanged('');
  }

  /// Picks the carousel's categories, preferring ones with a real photo
  /// (via [getCategoryImage]) over icon-only ones so a photographed category
  /// (e.g. Electrician) isn't bumped out by an icon-only one (e.g. Aluminum)
  /// that merely appears earlier in the backend list.
  List<Category> _featuredCategories(List<Category> categories) {
    final withImage = categories.where((c) => getCategoryImage(c.name) != null);
    final withoutImage =
        categories.where((c) => getCategoryImage(c.name) == null);
    return [...withImage, ...withoutImage].take(4).toList();
  }

  Future<void> _onFeaturedCategoryTap(Category category) async {
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
    final color = styleForServiceName(category.serviceName, 0).color;
    Navigator.of(context).pushNamed(
      ServiceRequestFormScreen.routeName,
      arguments: ServiceRequestFormArgs(category: category, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final catalogProvider = context.watch<ServiceCatalogProvider>();
    final catalogServices = catalogProvider.services;

    // Keep the overlay's suggestion list in sync as services load/change.
    if (_suggestionsOverlay != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _updateSuggestionsOverlay());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(176),
        child: _HomeHeader(
          query: _searchQuery,
          controller: _searchController,
          searchLink: _searchLink,
          focusNode: _searchFocusNode,
          onQueryChanged: _onQueryChanged,
          onClear: _clearSearch,
        ),
      ),
      bottomNavigationBar: widget.embedded ? null : const AppBottomNavigation(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionHeader(title: 'Services'),
                const SizedBox(height: 12),
                if (catalogProvider.isLoading)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()))
                else if (catalogProvider.error != null)
                  _InlineErrorCard(
                    title: 'Couldn\'t load services',
                    message: catalogProvider.error!,
                    onRetry: catalogProvider.fetchServices,
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: catalogServices.length,
                    itemBuilder: (context, index) {
                      final service = catalogServices[index];
                      return MainCategoryCard(service: service, index: index);
                    },
                  ),
                const SizedBox(height: 16),
                const _SectionFade(),
                const SizedBox(height: 12),
                const _SectionHeader(title: 'Featured Services'),
                const SizedBox(height: 12),
                FeaturedServicesCarousel(
                  categories: _featuredCategories(categories),
                  cardColors: serviceCardColors,
                  onTapCategory: _onFeaturedCategoryTap,
                ),
                const SizedBox(height: 24),
                const _SectionHeader(title: 'Customer Reviews'),
                const SizedBox(height: 12),
                const _ReviewsList(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient brand header for the home screen — logo badge, greeting, and a
/// floating search field that overlaps the seam with the page body.
class _HomeHeader extends StatelessWidget {
  final String query;
  final TextEditingController controller;
  final LayerLink searchLink;
  final FocusNode focusNode;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;

  const _HomeHeader({
    required this.query,
    required this.controller,
    required this.searchLink,
    required this.focusNode,
    required this.onQueryChanged,
    required this.onClear,
  });

  static const _brandDark = _HomeScreenState._brandDark;
  static const _brandBlue = _HomeScreenState._brandBlue;
  static const _brandAccent = _HomeScreenState._brandAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandDark, _brandBlue],
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Color(0x330A4FA8), blurRadius: 20, offset: Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: DecorativeGlowCircle(
                  baseSize: 150, color: _brandAccent.withValues(alpha: 0.14)),
            ),
            Positioned(
              bottom: -60,
              left: -30,
              child: DecorativeGlowCircle(
                  baseSize: 130, color: Colors.white.withValues(alpha: 0.06)),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: Image.asset(
                            'assets/icon/app_logo_transparent.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sahulat Ghar Tak',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Quality Services Delivered to Your Doorstep',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    CompositedTransformTarget(
                      link: searchLink,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 14,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: onQueryChanged,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Search services...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon:
                                Icon(Icons.search_rounded, color: _brandBlue),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    icon: Icon(Icons.close_rounded,
                                        color: Colors.grey.shade500, size: 20),
                                    onPressed: onClear,
                                  ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
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
  }
}

/// Content-sized error card for sections embedded inline within a scrolling
/// page (unlike [EmptyStatePlaceholder], which needs a bounded-height
/// ancestor such as a `Scaffold.body` to fill).
class _InlineErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _InlineErrorCard(
      {required this.title, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 36, color: Colors.red.shade300),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: _HomeScreenState._ink)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
              color: _HomeScreenState._brandBlue,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _HomeScreenState._ink,
              letterSpacing: -0.2),
        ),
      ],
    );
  }
}

/// Thin gradient fade used between sections instead of a hard divider line.
class _SectionFade extends StatelessWidget {
  const _SectionFade();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _HomeScreenState._brandBlue.withValues(alpha: 0.18),
            Colors.transparent
          ],
        ),
      ),
    );
  }
}

class _Review {
  final String name;
  final String comment;
  final int rating;
  final Color color;
  const _Review(this.name, this.comment, this.rating, this.color);
}

const List<_Review> _reviews = [
  _Review(
      'Ayesha Khan',
      'Excellent service, arrived on time and did a fantastic job!',
      5,
      Color(0xFF45B7D1)),
  _Review(
      'Bilal Ahmed',
      'Very satisfied with the plumbing work, will definitely use again.',
      5,
      Color(0xFF4ECDC4)),
  _Review('Sana Malik', 'Professional and quick. Fixed my AC in under an hour.',
      4, Color(0xFFBB8FCE)),
];

class _ReviewsList extends StatefulWidget {
  const _ReviewsList();

  @override
  State<_ReviewsList> createState() => _ReviewsListState();
}

class _ReviewsListState extends State<_ReviewsList> {
  late final ScrollController _controller;
  double _page = 0;

  static const double _cardWidth = 260;
  static const double _spacing = 12;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() => _page = _controller.offset / (_cardWidth + _spacing));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics:
            const PageScrollPhysics().applyTo(const BouncingScrollPhysics()),
        itemCount: _reviews.length,
        separatorBuilder: (_, __) => const SizedBox(width: _spacing),
        itemBuilder: (context, index) {
          final review = _reviews[index];
          final scale = (1 - (index - _page).abs() * 0.08).clamp(0.94, 1.0);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: _cardWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color:
                          _HomeScreenState._brandDark.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: review.color.withValues(alpha: 0.2),
                        child: Text(
                          review.name[0],
                          style: TextStyle(
                              color: review.color, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          review.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _HomeScreenState._ink,
                              fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < review.rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 16,
                        color: const Color(0xFFFFB020),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      review.comment,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 13,
                          height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Floating dropdown of live search matches, anchored below the header's
/// search field via [CompositedTransformFollower]. Only rendered while the
/// field is focused and non-empty.
class _SearchSuggestionsOverlay extends StatelessWidget {
  final LayerLink link;
  final List<Category> matches;
  final ValueChanged<Category> onTap;

  const _SearchSuggestionsOverlay(
      {required this.link, required this.matches, required this.onTap});

  static const _ink = _HomeScreenState._ink;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Positioned(
      width: (width - 40).clamp(0.0, kOverlayMaxWidth),
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        offset: const Offset(0, 62),
        child: TweenAnimationBuilder<double>(
          key: ValueKey(matches.length),
          tween: Tween(begin: 0, end: 1),
          duration: prefersReducedMotion(context)
              ? Duration.zero
              : kQuickAnimDuration,
          curve: kStandardCurve,
          builder: (context, t, child) {
            return Opacity(
              opacity: t,
              child: Transform.translate(
                  offset: Offset(0, (1 - t) * -8), child: child),
            );
          },
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            shadowColor: Colors.black.withValues(alpha: 0.25),
            child: matches.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 16),
                    child: Text('No services found',
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500)),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: matches.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final category = matches[index];
                        final tint =
                            styleForServiceName(category.serviceName, 0).color;
                        return ListTile(
                          dense: true,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: tint.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(getCategoryIcon(category.name),
                                color: tint, size: 18),
                          ),
                          title: Text(category.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: _ink)),
                          subtitle: Text(category.serviceName,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                          onTap: () => onTap(category),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
