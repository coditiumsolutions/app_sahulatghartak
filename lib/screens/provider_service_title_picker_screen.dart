import 'package:flutter/material.dart';
import '../widgets/frosted_icon_button.dart';

import '../data/repositories/service_title_repository.dart';
import '../models/service_title.dart';
import '../utils/api_error.dart';
import '../utils/service_catalog_style.dart';
import '../widgets/decorative_glow_circle.dart';

// Same brand palette as CategoryPickerScreen, kept local for the same reason
// (just a palette, not shared behavior).
const _brandDark = Color(0xFF0A4FA8);
const _brandBlue = Color(0xFF016EE3);
const _brandAccent = Color(0xFF4FC3F7);

/// Full-screen multi-select picker for a provider's optional Service Titles,
/// scoped to the categories they already hold — used for provider
/// registration and the "My Service Titles" section on the provider profile.
///
/// Unlike [CategoryPickerScreen], selecting zero titles is a valid choice
/// (titles are fully optional, see `api.txt`'s PUT .../service-titles notes),
/// so the bottom action button never disables.
class ProviderServiceTitlePickerScreen extends StatefulWidget {
  /// Categories the provider currently holds — titles are only pickable
  /// within these (see `api.txt`: a title must belong to one of the
  /// provider's categories, otherwise the backend rejects it).
  final Set<int> categoryUids;

  /// Ids of titles already selected when this screen opens.
  final Set<int> selectedTitleIds;

  const ProviderServiceTitlePickerScreen(
      {super.key,
      required this.categoryUids,
      this.selectedTitleIds = const {}});

  @override
  State<ProviderServiceTitlePickerScreen> createState() =>
      _ProviderServiceTitlePickerScreenState();
}

class _ProviderServiceTitlePickerScreenState
    extends State<ProviderServiceTitlePickerScreen> {
  final _repository = ServiceTitleRepository();
  final _searchController = TextEditingController();

  List<ServiceTitle> _titles = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.selectedTitleIds};
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.categoryUids.isEmpty) {
      setState(() {
        _isLoading = false;
        _titles = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait(
          widget.categoryUids.map((id) => _repository.fetchServiceTitles(id)));
      if (!mounted) return;
      setState(() => _titles = results.expand((titles) => titles).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, List<ServiceTitle>> get _groupedFiltered {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _titles
        : _titles
            .where((t) =>
                t.title.toLowerCase().contains(query) ||
                t.categoryName.toLowerCase().contains(query))
            .toList();

    final groups = <String, List<ServiceTitle>>{};
    for (final title in filtered) {
      groups.putIfAbsent(title.categoryName, () => []).add(title);
    }
    return groups;
  }

  void _toggle(ServiceTitle title) {
    setState(() {
      if (_selectedIds.contains(title.id)) {
        _selectedIds.remove(title.id);
      } else {
        _selectedIds.add(title.id);
      }
    });
  }

  void _done() {
    final selected = _titles.where((t) => _selectedIds.contains(t.id)).toList();
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedFiltered;
    final groupNames = groups.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Column(
        children: [
          _PickerHeader(
            controller: _searchController,
            query: _query,
            onQueryChanged: (v) => setState(() => _query = v),
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: widget.categoryUids.isEmpty
                ? const _NoCategoriesState()
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _ErrorState(message: _error!, onRetry: _load)
                        : groupNames.isEmpty
                            ? const _EmptyState()
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: groupNames.length,
                                itemBuilder: (context, index) {
                                  final categoryName = groupNames[index];
                                  final style =
                                      styleForServiceName(categoryName, index);
                                  return _TitleGroupSection(
                                    categoryName: categoryName,
                                    style: style,
                                    titles: groups[categoryName]!,
                                    selectedIds: _selectedIds,
                                    onToggle: _toggle,
                                  );
                                },
                              ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ElevatedButton(
          onPressed: widget.categoryUids.isEmpty ? null : _done,
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(_selectedIds.isEmpty
              ? 'Done (none selected)'
              : 'Done (${_selectedIds.length} selected)'),
        ),
      ),
    );
  }
}

class _PickerHeader extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;

  const _PickerHeader({
    required this.controller,
    required this.query,
    required this.onQueryChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_brandDark, _brandBlue]),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Color(0x330A4FA8), blurRadius: 16, offset: Offset(0, 6))
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -20,
              child: DecorativeGlowCircle(
                  baseSize: 110, color: _brandAccent.withValues(alpha: 0.14)),
            ),
            const Positioned(
              bottom: -40,
              left: -16,
              child: DecorativeGlowCircle(
                  baseSize: 90, color: Color.fromRGBO(255, 255, 255, 0.06)),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FrostedBackButton(onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const Expanded(
                          child: Text(
                            'Select Services',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: TextField(
                          controller: controller,
                          onChanged: onQueryChanged,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search services...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: _brandBlue),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    icon: Icon(Icons.close_rounded,
                                        color: Colors.grey.shade500, size: 20),
                                    onPressed: onClear,
                                  ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
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

class _TitleGroupSection extends StatelessWidget {
  final String categoryName;
  final ServiceCatalogStyle style;
  final List<ServiceTitle> titles;
  final Set<int> selectedIds;
  final ValueChanged<ServiceTitle> onToggle;

  const _TitleGroupSection({
    required this.categoryName,
    required this.style,
    required this.titles,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 2),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: style.color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(9)),
                  child: Icon(style.icon, size: 17, color: style.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14213D)),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < titles.length; i++) ...[
                  if (i != 0) const Divider(height: 1, indent: 60),
                  _TitleTile(
                    title: titles[i],
                    color: style.color,
                    selected: selectedIds.contains(titles[i].id),
                    onTap: () => onToggle(titles[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleTile extends StatelessWidget {
  final ServiceTitle title;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TitleTile(
      {required this.title,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(Icons.label_rounded, size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title.title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF14213D)),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 22)
            else
              const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _NoCategoriesState extends StatelessWidget {
  const _NoCategoriesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Select a category first',
                style: TextStyle(
                    color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No services found',
                style: TextStyle(
                    color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text('Couldn\'t load services',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
