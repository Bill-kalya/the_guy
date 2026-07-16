import 'package:flutter/material.dart';

/// Centralized definition of all service categories offered on the platform.
/// Used across the app to ensure consistency between screens, filters, and API calls.
class ServiceCategory {
  final String name;
  final IconData icon;
  final MaterialColor color;
  final String? iconAsset;
  final double basePrice;

  const ServiceCategory({
    required this.name,
    required this.icon,
    required this.color,
    this.iconAsset,
    this.basePrice = 500,
  });
}

class ServiceCategories {
  ServiceCategories._();

  /// Complete list of all service categories
  static const List<ServiceCategory> all = [
    // Home & Maintenance
    ServiceCategory(name: 'Plumbing', icon: Icons.plumbing, color: Colors.blue, basePrice: 1000),
    ServiceCategory(name: 'Electrical', icon: Icons.electrical_services, color: Colors.amber, basePrice: 1200),
    ServiceCategory(name: 'Carpenter', icon: Icons.handyman, color: Colors.orange, basePrice: 1500),
    ServiceCategory(name: 'Mason', icon: Icons.bricks, color: Colors.brown, basePrice: 2000),
    ServiceCategory(name: 'Painting', icon: Icons.format_paint, color: Colors.indigo, basePrice: 1500),

    // Cleaning & Hygiene
    ServiceCategory(name: 'Mama Fua', icon: Icons.cleaning_services, color: Colors.teal, basePrice: 500),
    ServiceCategory(name: 'Commercial Cleaning', icon: Icons.business, color: Colors.blueGrey, basePrice: 3000),
    ServiceCategory(name: 'Carpet & Sofa Cleaning', icon: Icons.sofa, color: Colors.deepPurple, basePrice: 2000),
    ServiceCategory(name: 'Pressure Washing', icon: Icons.water, color: Colors.cyan, basePrice: 2500),

    // Outdoor & Garden
    ServiceCategory(name: 'Lawn & Compound Maintenance', icon: Icons.grass, color: Colors.green, basePrice: 1500),
    ServiceCategory(name: 'Hedge & Fence Trimming', icon: Icons.content_cut, color: Colors.lightGreen, basePrice: 1200),
    ServiceCategory(name: 'Tree Services', icon: Icons.nature, color: Colors.green, basePrice: 3000),
    ServiceCategory(name: 'Irrigation & Borehole Services', icon: Icons.water_drop, color: Colors.lightBlue, basePrice: 5000),
    ServiceCategory(name: 'Gardening', icon: Icons.yard, color: Colors.lime, basePrice: 1000),

    // General Services
    ServiceCategory(name: 'Cleaning', icon: Icons.cleaning_services, color: Colors.teal, basePrice: 800),
    ServiceCategory(name: 'Appliance Repair', icon: Icons.precision_manufacturing, color: Colors.red, basePrice: 1500),
    ServiceCategory(name: 'Moving', icon: Icons.local_shipping, color: Colors.red, basePrice: 3000),
    ServiceCategory(name: 'Handyman', icon: Icons.build, color: Colors.orange, basePrice: 1000),
    ServiceCategory(name: 'Tutoring', icon: Icons.school, color: Colors.purple, basePrice: 800),
    ServiceCategory(name: 'Pet Care', icon: Icons.pets, color: Colors.pink, basePrice: 600),
    ServiceCategory(name: 'Health', icon: Icons.health_and_safety, color: Colors.green, basePrice: 1000),
  ];

  /// Popular/featured categories shown on the home screen hero section
  static const List<ServiceCategory> popular = [
    ServiceCategory(name: 'Plumbing', icon: Icons.plumbing, color: Colors.blue),
    ServiceCategory(name: 'Electrical', icon: Icons.electrical_services, color: Colors.amber),
    ServiceCategory(name: 'Cleaning', icon: Icons.cleaning_services, color: Colors.teal),
    ServiceCategory(name: 'Tutoring', icon: Icons.school, color: Colors.purple),
    ServiceCategory(name: 'Handyman', icon: Icons.build, color: Colors.orange),
    ServiceCategory(name: 'Moving', icon: Icons.local_shipping, color: Colors.red),
    ServiceCategory(name: 'Pet Care', icon: Icons.pets, color: Colors.pink),
    ServiceCategory(name: 'Health', icon: Icons.health_and_safety, color: Colors.green),
  ];

  /// Featured service categories shown in the desktop category grid
  static const List<ServiceCategory> featured = [
    ServiceCategory(name: 'Plumbing', icon: Icons.plumbing, color: Colors.blue),
    ServiceCategory(name: 'Electrical', icon: Icons.electrical_services, color: Colors.amber),
    ServiceCategory(name: 'Cleaning', icon: Icons.cleaning_services, color: Colors.teal),
    ServiceCategory(name: 'Tutoring', icon: Icons.school, color: Colors.purple),
    ServiceCategory(name: 'Handyman', icon: Icons.build, color: Colors.orange),
    ServiceCategory(name: 'Moving', icon: Icons.local_shipping, color: Colors.red),
    ServiceCategory(name: 'Pet Care', icon: Icons.pets, color: Colors.pink),
    ServiceCategory(name: 'Health', icon: Icons.health_and_safety, color: Colors.green),
  ];

  /// Get category by name (case-insensitive)
  static ServiceCategory? getByName(String name) {
    try {
      return all.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get icon for a category name (with fallback)
  static IconData getIcon(String name) {
    final category = getByName(name);
    return category?.icon ?? Icons.handyman;
  }

  /// Get base price for a category name
  static double getBasePrice(String name) {
    final category = getByName(name);
    return category?.basePrice ?? 500;
  }

  /// Get all category names as a list of strings
  static List<String> get names => all.map((c) => c.name).toList();
}