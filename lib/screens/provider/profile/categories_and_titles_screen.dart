import 'package:flutter/material.dart';
import '../../../widgets/frosted_icon_button.dart';
import 'package:provider/provider.dart';

import '../../../models/category.dart';
import '../../../models/provider/provider_service_title.dart';
import '../../../models/service_title.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/provider_categories_provider.dart';
import '../../../providers/provider_service_titles_provider.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/primary_category_dialog.dart';
import '../../../widgets/provider/provider_tab_header.dart';
import '../../../widgets/provider/section_header_and_info_card.dart';
import '../../category_picker_screen.dart';
import '../../provider_service_title_picker_screen.dart';

/// Standalone screen for managing a provider's categories and (optional)
/// service titles — split out of [ProfileTab] since that screen was already
/// dense; reached via its "Categories" button.
class CategoriesAndTitlesScreen extends StatefulWidget {
  const CategoriesAndTitlesScreen({super.key});

  @override
  State<CategoriesAndTitlesScreen> createState() =>
      _CategoriesAndTitlesScreenState();
}

class _CategoriesAndTitlesScreenState extends State<CategoriesAndTitlesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid == null) return;
    context.read<ProviderCategoriesProvider>().load(providerUid);
    context.read<ProviderServiceTitlesProvider>().load(providerUid);
  }

  Future<void> _editCategories(BuildContext context) async {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid == null) return;

    final categoriesProvider = context.read<ProviderCategoriesProvider>();
    final currentIds =
        categoriesProvider.categories.map((c) => c.categoryUid).toSet();

    final result = await Navigator.of(context).push<List<Category>>(
      MaterialPageRoute(
          builder: (_) =>
              CategoryPickerScreen(selectedCategoryIds: currentIds)),
    );
    if (result == null || result.isEmpty || !context.mounted) return;

    final primaryMatches =
        categoriesProvider.categories.where((c) => c.isPrimary);
    final currentPrimary =
        primaryMatches.isEmpty ? null : primaryMatches.first.categoryUid;

    int primaryCategoryId;
    if (result.length == 1) {
      primaryCategoryId = result.first.id;
    } else {
      final chosen = await showPrimaryCategoryDialog(context,
          categories: result, initialPrimaryId: currentPrimary);
      if (chosen == null || !context.mounted) return;
      primaryCategoryId = chosen;
    }

    await _saveCategories(context, providerUid,
        categoryIds: result.map((c) => c.id).toList(),
        primaryCategoryId: primaryCategoryId);
  }

  /// Lets the provider change which of their *already-selected* categories is
  /// primary at any time, without going through the full add/remove picker —
  /// a standalone entry point to [showPrimaryCategoryDialog] alongside
  /// [_editCategories]'s full "Edit" flow.
  Future<void> _editPrimaryCategory(BuildContext context) async {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid == null) return;

    final categoriesProvider = context.read<ProviderCategoriesProvider>();
    final categories = categoriesProvider.categories;
    if (categories.length < 2) return;

    final asCategories = categories
        .map((c) => Category(
            id: c.categoryUid,
            serviceId: 0,
            serviceName: '',
            name: c.categoryName,
            description: null,
            createdOn: DateTime.now()))
        .toList();
    final primaryMatches = categories.where((c) => c.isPrimary);
    final currentPrimary =
        primaryMatches.isEmpty ? null : primaryMatches.first.categoryUid;

    final chosen = await showPrimaryCategoryDialog(context,
        categories: asCategories, initialPrimaryId: currentPrimary);
    if (chosen == null || chosen == currentPrimary || !context.mounted) return;

    await _saveCategories(context, providerUid,
        categoryIds: categories.map((c) => c.categoryUid).toList(),
        primaryCategoryId: chosen);
  }

  Future<void> _saveCategories(BuildContext context, int providerUid,
      {required List<int> categoryIds, required int primaryCategoryId}) async {
    final categoriesProvider = context.read<ProviderCategoriesProvider>();
    final success = await categoriesProvider.save(providerUid,
        categoryIds: categoryIds, primaryCategoryId: primaryCategoryId);
    if (!context.mounted) return;

    if (success) {
      showAppToast(context, 'Categories updated', type: AppToastType.success);
      await _pruneOrphanedTitles(providerUid, categoryIds.toSet());
    } else {
      showAppToast(
          context, categoriesProvider.error ?? 'Failed to update categories',
          type: AppToastType.error);
    }
  }

  /// The backend keeps titles of a removed category until the next titles save
  /// (api.txt "orphaned titles persist"); drop them now so the list only shows
  /// titles under the provider's current categories.
  Future<void> _pruneOrphanedTitles(
      int providerUid, Set<int> categoryIds) async {
    final titlesProvider = context.read<ProviderServiceTitlesProvider>();
    final kept = titlesProvider.serviceTitles
        .where((t) => categoryIds.contains(t.categoryUid))
        .toList();
    if (kept.length == titlesProvider.serviceTitles.length) return;
    await titlesProvider.save(providerUid,
        serviceTitleIds: kept.map((t) => t.serviceTitleUid).toList());
  }

  Future<void> _editServiceTitles(BuildContext context) async {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid == null) return;

    final categoryUids = context
        .read<ProviderCategoriesProvider>()
        .categories
        .map((c) => c.categoryUid)
        .toSet();
    final titlesProvider = context.read<ProviderServiceTitlesProvider>();
    final currentIds =
        titlesProvider.serviceTitles.map((t) => t.serviceTitleUid).toSet();

    final result = await Navigator.of(context).push<List<ServiceTitle>>(
      MaterialPageRoute(
          builder: (_) => ProviderServiceTitlePickerScreen(
              categoryUids: categoryUids, selectedTitleIds: currentIds)),
    );
    if (result == null || !context.mounted) return;

    final success = await titlesProvider.save(providerUid,
        serviceTitleIds: result.map((t) => t.id).toList());
    if (!context.mounted) return;
    if (success) {
      showAppToast(context, 'Services updated', type: AppToastType.success);
    } else {
      showAppToast(context, titlesProvider.error ?? 'Failed to update services',
          type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: ProviderTabHeader(
        title: 'Categories & Services',
        subtitle: 'Manage what you offer',
        leading: FrostedBackButton(onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: SectionHeader('My Categories')),
                Consumer<ProviderCategoriesProvider>(
                  builder: (context, categoriesProvider, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (categoriesProvider.categories.length > 1) ...[
                          TextButton.icon(
                            onPressed: categoriesProvider.isSaving
                                ? null
                                : () => _editPrimaryCategory(context),
                            icon: const Icon(Icons.star_rounded, size: 16),
                            label: const Text('Edit Primary',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700)),
                            style: TextButton.styleFrom(
                                foregroundColor: providerBrandBlue,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap),
                          ),
                          const SizedBox(width: 14),
                        ],
                        TextButton.icon(
                          onPressed: categoriesProvider.isSaving
                              ? null
                              : () => _editCategories(context),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Edit',
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(
                              foregroundColor: providerBrandBlue,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Consumer<ProviderCategoriesProvider>(
              builder: (context, categoriesProvider, _) {
                if (categoriesProvider.isLoading &&
                    categoriesProvider.categories.isEmpty) {
                  return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()));
                }
                if (categoriesProvider.categories.isEmpty) {
                  return InfoCard(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.category_outlined,
                            color: providerBrandBlue),
                        title: const Text('No categories yet'),
                        subtitle: categoriesProvider.error != null
                            ? Text(categoriesProvider.error!)
                            : null,
                      ),
                    ],
                  );
                }
                return InfoCard(
                  children: [
                    for (var i = 0;
                        i < categoriesProvider.categories.length;
                        i++) ...[
                      if (i != 0) const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.category_rounded,
                            color: providerBrandBlue),
                        title:
                            Text(categoriesProvider.categories[i].categoryName),
                        trailing: categoriesProvider.categories[i].isPrimary
                            ? const Chip(
                                label: Text('Primary',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                                visualDensity: VisualDensity.compact)
                            : null,
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: SectionHeader('My Services')),
                Consumer<ProviderServiceTitlesProvider>(
                  builder: (context, titlesProvider, _) {
                    return TextButton.icon(
                      onPressed: titlesProvider.isSaving
                          ? null
                          : () => _editServiceTitles(context),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700)),
                      style: TextButton.styleFrom(
                          foregroundColor: providerBrandBlue,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Consumer<ProviderServiceTitlesProvider>(
              builder: (context, titlesProvider, _) {
                if (titlesProvider.isLoading &&
                    titlesProvider.serviceTitles.isEmpty) {
                  return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()));
                }
                if (titlesProvider.serviceTitles.isEmpty) {
                  return const InfoCard(
                    children: [
                      ListTile(
                        leading: Icon(Icons.label_outline_rounded,
                            color: providerBrandBlue),
                        title: Text('No services selected yet'),
                        subtitle: Text(
                            'Optional — helps customers find you for specific jobs'),
                      ),
                    ],
                  );
                }
                final groups = <String, List<ProviderServiceTitle>>{};
                for (final t in titlesProvider.serviceTitles) {
                  groups.putIfAbsent(t.categoryName, () => []).add(t);
                }
                return InfoCard(
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: providerBrandBlue),
                        ),
                      ),
                      for (final t in entry.value)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.label_rounded,
                              color: providerBrandBlue),
                          title: Text(t.title),
                        ),
                      if (entry.key != groups.keys.last)
                        const Divider(height: 1),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
