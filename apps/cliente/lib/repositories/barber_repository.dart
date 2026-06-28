import '../models/barber.dart';
import '../models/service_category.dart';
import '../models/service_item.dart';
import '../services/mock_data.dart';
import '../services/supabase_rest_service.dart';

class BarberRepository {
  const BarberRepository({SupabaseRestService? rest})
      : _rest = rest ?? const SupabaseRestService();

  final SupabaseRestService _rest;

  Future<List<Barber>> fetchBarbers() async {
    if (!_rest.isConfigured) return MockData.barbers;

    try {
      final rows = await _rest.getRows(
        'barbers',
        select:
            'id,name,bio,photo_url,rating,starting_price,barber_shops(name),barber_services(services(category_id))',
        filters: const {'is_active': 'eq.true'},
        order: 'name.asc',
      );

      final barbers = rows.map<Barber>((row) {
        final links = row['barber_services'] as List<dynamic>? ?? const [];
        final categoryIds = links
            .map((link) => link['services']?['category_id'])
            .where((id) => id != null)
            .map((id) => id.toString())
            .toSet()
            .toList();

        return Barber.fromMap({...row, 'category_ids': categoryIds});
      }).toList();

      return barbers.isEmpty ? MockData.barbers : barbers;
    } catch (_) {
      return MockData.barbers;
    }
  }

  Future<List<ServiceCategory>> fetchCategories() async {
    if (!_rest.isConfigured) return MockData.categories;

    try {
      final rows = await _rest.getRows(
        'service_categories',
        select: 'id,name,icon',
        filters: const {'is_active': 'eq.true'},
        order: 'sort_order.asc',
      );

      final categories = rows
          .map<ServiceCategory>((row) => ServiceCategory.fromMap(row))
          .toList();
      return categories.isEmpty ? MockData.categories : categories;
    } catch (_) {
      return MockData.categories;
    }
  }

  Future<List<ServiceItem>> fetchServices() async {
    if (!_rest.isConfigured) return MockData.services;

    try {
      final rows = await _rest.getRows(
        'services',
        select: 'id,name,duration_minutes,price,category_id',
        filters: const {'is_active': 'eq.true'},
        order: 'name.asc',
      );

      final services = rows
          .map<ServiceItem>((row) => ServiceItem.fromMap(row))
          .toList();
      return services.isEmpty ? MockData.services : services;
    } catch (_) {
      return MockData.services;
    }
  }
}
