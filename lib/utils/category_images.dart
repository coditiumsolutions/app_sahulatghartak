const Map<String, String> _keywordImages = {
  'electric': 'assets/electrician01.jpeg',
  'plumb': 'assets/plumbing01.jpeg',
  'carpenter': 'assets/carpanter01.jpg',
  'carpainter': 'assets/carpanter01.jpg', // common misspelling of "carpenter" in source data
  'paint': 'assets/painter01.jpg',
};

/// Photo for a category, when one of the app's few stock photos matches its
/// name; otherwise `null` so callers fall back to an icon tile. Keeps the
/// home carousel photo-backed for the categories we have real photos for,
/// without requiring every backend category to have one.
String? getCategoryImage(String categoryName) {
  final name = categoryName.toLowerCase();
  for (final entry in _keywordImages.entries) {
    if (name.contains(entry.key)) return entry.value;
  }
  return null;
}
