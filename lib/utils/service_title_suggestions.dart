const Map<String, List<String>> _keywordServiceTitles = {
  'electric': ['Wiring Repair', 'Switchboard Installation', 'Fan Installation', 'Circuit Breaker Repair', 'Light Fixture Installation'],
  'plumb': ['Pipe Leakage Repair', 'Tap/Faucet Installation', 'Drain Unclogging', 'Water Tank Fitting', 'Bathroom Fitting Repair'],
  'carpenter': ['Furniture Repair', 'Door/Window Fitting', 'Cabinet Installation', 'Wood Polishing', 'Custom Furniture Making'],
  'carpainter': ['Furniture Repair', 'Door/Window Fitting', 'Cabinet Installation', 'Wood Polishing', 'Custom Furniture Making'],
  'paint': ['Wall Painting', 'Ceiling Painting', 'Exterior House Painting', 'Wood/Door Painting', 'Waterproof Coating'],
  'sofa': ['Sofa Cleaning', 'Mattress Cleaning', 'Carpet Shampooing', 'Curtain Cleaning', 'Deep Fabric Cleaning'],
  'carpet': ['Sofa Cleaning', 'Mattress Cleaning', 'Carpet Shampooing', 'Curtain Cleaning', 'Deep Fabric Cleaning'],
  'kitchen': ['Kitchen Deep Cleaning', 'Chimney/Hood Cleaning', 'Cabinet Repair', 'Countertop Repair', 'Appliance Fitting'],
  'pest': ['General Pest Control', 'Cockroach Treatment', 'Rodent Control', 'Mosquito Fumigation', 'Bed Bug Treatment'],
  'termite': ['Termite Inspection', 'Termite Treatment', 'Anti-Termite Soil Treatment', 'Wood Termite Proofing', 'Follow-up Treatment'],
  'water tank': ['Water Tank Cleaning', 'Water Tank Installation', 'Water Tank Repair', 'Overhead Tank Fitting', 'Leakage Sealing'],
  'tanker': ['Water Tanker Delivery', 'Emergency Water Supply', 'Bulk Water Delivery', 'Tanker Booking', 'Recurring Water Supply'],
  'solar': ['Solar Panel Cleaning', 'Solar Panel Installation', 'Solar Inverter Repair', 'Solar System Maintenance', 'Solar Panel Inspection'],
  'beautic': ['Bridal Makeup', 'Facial & Skincare', 'Hair Styling', 'Manicure/Pedicure', 'Home Salon Service'],
  'salon': ['Bridal Makeup', 'Facial & Skincare', 'Hair Styling', 'Manicure/Pedicure', 'Home Salon Service'],
  'hajj': ['Hajj Package Booking', 'Umrah Package Booking', 'Visa Processing', 'Group Travel Arrangement', 'Ziyarat Tour Booking'],
  'umrah': ['Hajj Package Booking', 'Umrah Package Booking', 'Visa Processing', 'Group Travel Arrangement', 'Ziyarat Tour Booking'],
  'maid': ['Daily Housemaid', 'Full-time Maid', 'Part-time Cleaning Help', 'Cook Hiring', 'Driver Hiring'],
  'driver': ['Daily Housemaid', 'Full-time Maid', 'Part-time Cleaning Help', 'Cook Hiring', 'Driver Hiring'],
  'cook': ['Daily Housemaid', 'Full-time Maid', 'Part-time Cleaning Help', 'Cook Hiring', 'Driver Hiring'],
  'tutor': ['Home Tuition (School Level)', 'Home Tuition (O/A Levels)', 'Quran Tutoring', 'Subject-specific Tutoring', 'Exam Preparation Classes'],
  'pack': ['Local House Shifting', 'Office Relocation', 'Packing Service Only', 'Furniture Loading/Unloading', 'Long Distance Moving'],
  'mover': ['Local House Shifting', 'Office Relocation', 'Packing Service Only', 'Furniture Loading/Unloading', 'Long Distance Moving'],
  'vet': ['Pet Vaccination', 'Pet Health Checkup', 'Pet Grooming', 'Emergency Pet Care', 'Pet Deworming'],
  'pet': ['Pet Vaccination', 'Pet Health Checkup', 'Pet Grooming', 'Emergency Pet Care', 'Pet Deworming'],
  'ac ': ['AC Installation', 'AC Gas Refilling', 'AC Repair', 'AC General Service', 'AC Uninstallation'],
  'air condition': ['AC Installation', 'AC Gas Refilling', 'AC Repair', 'AC General Service', 'AC Uninstallation'],
  'appliance': ['Washing Machine Repair', 'Refrigerator Repair', 'Microwave Repair', 'Water Dispenser Repair', 'General Appliance Servicing'],
  'evaluat': ['Property Valuation Report', 'Bank Loan Evaluation', 'Land Valuation', 'Building Valuation', 'Valuation Certificate'],
  'sale': ['Property Listing for Sale', 'Buyer Matching', 'Sale Documentation Support', 'Property Photography', 'Negotiation Assistance'],
  'purchase': ['Property Search Assistance', 'Purchase Documentation Support', 'Site Visit Arrangement', 'Legal Verification', 'Negotiation Assistance'],
  'rent': ['Property Listing for Rent', 'Tenant Matching', 'Rental Agreement Drafting', 'Property Inspection', 'Rent Collection Assistance'],
  'renovat': ['Home Renovation (Full)', 'Kitchen Renovation', 'Bathroom Renovation', 'Flooring Renovation', 'False Ceiling Work'],
  'lawyer': ['Property Legal Consultation', 'Contract Drafting', 'Title Verification', 'Court Case Representation', 'Legal Notice Drafting'],
  'legal': ['Property Legal Consultation', 'Contract Drafting', 'Title Verification', 'Court Case Representation', 'Legal Notice Drafting'],
};

const List<String> defaultServiceTitles = [
  'General Inquiry',
  'Inspection Visit',
  'Repair Service',
  'Installation Service',
  'Maintenance Service',
];

List<String> getServiceTitleSuggestions(String categoryName) {
  final name = categoryName.toLowerCase();
  for (final entry in _keywordServiceTitles.entries) {
    if (name.contains(entry.key)) return entry.value;
  }
  return defaultServiceTitles;
}
