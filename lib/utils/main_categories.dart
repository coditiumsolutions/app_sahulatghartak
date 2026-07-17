import 'package:flutter/material.dart';

import '../models/main_category.dart';

const List<MainCategory> mainCategories = [
  MainCategory(
    title: 'Home Maintenance',
    icon: Icons.home_repair_service,
    color: Color(0xFF45B7D1),
    subCategories: [
      SubCategoryItem('Electrician services', ['electric']),
      SubCategoryItem('Plumber Services', ['plumb']),
      SubCategoryItem('Appliance repairing', ['appliance']),
      SubCategoryItem('Carpenter services', ['carpenter', 'carpainter']),
      SubCategoryItem('Carpet/sofa/mattress cleaning', ['carpet', 'sofa', 'mattress']),
      SubCategoryItem('Solar cleaning', ['solar']),
      SubCategoryItem('Paint services', ['paint']),
      SubCategoryItem('Pest/termite control', ['pest', 'termite']),
      SubCategoryItem('Water tanker services', ['water tank', 'tanker']),
    ],
  ),
  MainCategory(
    title: 'Specialized Services',
    icon: Icons.design_services,
    color: Color(0xFFBB8FCE),
    subCategories: [
      SubCategoryItem('Tutor services', ['tutor']),
      SubCategoryItem('Beautician Services', ['beautic', 'salon']),
      SubCategoryItem('Maid/driver/cook Services', ['maid', 'driver', 'cook']),
      SubCategoryItem('Packer & mover', ['pack', 'mover']),
      SubCategoryItem('Hajj umrah Services', ['hajj', 'umrah']),
      SubCategoryItem('Pet veterinary services', ['vet', 'pet']),
    ],
  ),
  MainCategory(
    title: 'Property & Legal Services',
    icon: Icons.real_estate_agent,
    color: Color(0xFFF7DC6F),
    subCategories: [
      SubCategoryItem('Property evaluation', ['evaluat']),
      SubCategoryItem('Sale/Purchase Property', ['sale', 'purchase']),
      SubCategoryItem('Property Rent Services', ['rent']),
      SubCategoryItem('Home renovation', ['renovat']),
      SubCategoryItem('Lawyer services for legal cases', ['lawyer', 'legal']),
    ],
  ),
];
