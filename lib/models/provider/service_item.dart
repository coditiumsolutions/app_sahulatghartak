class ServiceSubItem {
  final String name;
  final bool isSelected;

  const ServiceSubItem({required this.name, required this.isSelected});

  ServiceSubItem copyWith({bool? isSelected}) {
    return ServiceSubItem(name: name, isSelected: isSelected ?? this.isSelected);
  }
}

class ServiceCategoryOffering {
  final String categoryName;
  final List<ServiceSubItem> subServices;

  const ServiceCategoryOffering({required this.categoryName, required this.subServices});

  ServiceCategoryOffering copyWith({List<ServiceSubItem>? subServices}) {
    return ServiceCategoryOffering(
      categoryName: categoryName,
      subServices: subServices ?? this.subServices,
    );
  }
}
