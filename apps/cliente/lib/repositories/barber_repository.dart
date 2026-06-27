import '../config/supabase_config.dart';
import '../models/barber.dart';
import '../models/service_category.dart';
import '../models/service_item.dart';
import '../services/mock_data.dart';

class BarberRepository {
  Future<List<Barber>> fetchBarbers() async {
    if (!SupabaseConfig.isConfigured) return MockData.barbers;

    try {
      final client = SupabaseConfig.client;
      final rows = await client
          .from('barbers')
          .select('id, name, bio, photo_url, rating, starting_price, barber_shops(name)')
          .eq('is_active', true)
          .order('rating', ascending: false);

      final serviceLinks = await client
          .from('barber_services')
          .select('barber_id, services(category_id)')
          .eq('is_active', true);

      final categoryIdsByBarber = <String, List<String>>{};
      for (final item in serviceLinks) {
        final barberId = item['barber_id']?.toString();
        final categoryId = item['services']?['category_id']?.toString();
        if (barberId == null || categoryId == null) continue;
        categoryIdsByBarber.putIfAbsent(barberId, () => []).add(categoryId);
      }

      final barbers = rows.map((row) {
        final map = Map<String, dynamic>.from(row);
        map['category_ids'] = categoryIdsByBarber[map['id'].toString()] ?? [];
        return Barber.fromMap(map);
      }).toList();

      return barbers.isEmpty ? MockData.barbers : barbers;
    } catch (_) {
      return MockData.barbers;
    }
  }

  Future<List<ServiceCategory>> fetchCategories() async {
    if (!SupabaseConfig.isConfigured) return MockData.categories;

    try {
      final rows = await SupabaseConfig.client
          .from('service_categories')
          .select('id, name, icon')
          .eq('is_active', true)
          .order('sort_order');

      final categories = rows
          .map((row) => ServiceCategory.fromMap(Map<String, dynamic>.from(row)))
          .toList();
      return categories.isEmpty ? MockData.categories : categories;
    } catch (_) {
      return MockData.categories;
    }
  }

  Future<List<ServiceItem>> fetchServices() async {
    if (!SupabaseConfig.isConfigured) return MockData.services;

    try {
      final rows = await SupabaseConfig.client
          .from('services')
          .select('id, name, duration_minutes, price, category_id')
          .eq('is_active', true)
          .order('name');

      final services = rows
          .map((row) => ServiceItem.fromMap(Map<String, dynamic>.from(row)))
          .toList();
      return services.isEmpty ? MockData.services : services;
    } catch (_) {
      return MockData.services;
    }
  }
}
