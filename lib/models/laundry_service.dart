// The six laundry services the app offers.
// Price and unit are used in the ServiceCard widget.

class LaundryService {
  final String id;
  final String name;
  final double pricePerUnit; // in INR
  final String unit;         // 'kg', 'item', 'pair'
  final String iconAsset;    // named icon identifier

  const LaundryService({
    required this.id,
    required this.name,
    required this.pricePerUnit,
    required this.unit,
    required this.iconAsset,
  });
}

// Catalog — single source of truth.
// ServiceCard reads from this list; quantities live in the cart (Provider).
const List<LaundryService> kServiceCatalog = [
  LaundryService(
    id: 'wash_fold',
    name: 'Wash & Fold',
    pricePerUnit: 60,
    unit: 'kg',
    iconAsset: 'local_laundry_service',
  ),
  LaundryService(
    id: 'wash_iron',
    name: 'Wash & Iron',
    pricePerUnit: 80,
    unit: 'kg',
    iconAsset: 'iron',
  ),
  LaundryService(
    id: 'dry_clean',
    name: 'Dry Cleaning',
    pricePerUnit: 150,
    unit: 'item',
    iconAsset: 'dry_cleaning',
  ),
  LaundryService(
    id: 'ironing',
    name: 'Ironing',
    pricePerUnit: 15,
    unit: 'item',
    iconAsset: 'straighten',
  ),
  LaundryService(
    id: 'shoe_clean',
    name: 'Shoe Cleaning',
    pricePerUnit: 299,
    unit: 'pair',
    iconAsset: 'cleaning_services',
  ),
  LaundryService(
    id: 'blanket',
    name: 'Blanket & Bedding',
    pricePerUnit: 249,
    unit: 'item',
    iconAsset: 'hotel',
  ),
];
