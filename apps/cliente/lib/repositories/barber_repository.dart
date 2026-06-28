import '../models/barber.dart';
import '../models/service_category.dart';
import '../models/service_item.dart';
import '../services/mock_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BarberRepository {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<List<Barber>> fetchBarbers() async {
    final client = _client;
    if (client == null) return MockData.barbers;

    try {
      final rows = await client
          .from('barbers')
          .select(
            'id,name,bio,photo_url,rating,starting_price,barber_shops(name),barber_services(services(category_id))',
          )
          .eq('is_active', true)
          .order('name');

      final barbers = rows.map<Barber>((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final links = map['barber_services'] as List<dynamic>? ?? const [];
        final categoryIds = links
            .map((link) => link['services']?['category_id'])
            .where((id) => id != null)
            .map((id) => id.toString())
            .toSet()
            .toList();

        return Barber.fromMap({...map, 'category_ids': categoryIds});
      }).toList();

      return barbers.isEmpty ? MockData.barbers : barbers;
    } catch (_) {
      return MockData.barbers;
    }
  }

  Future<List<ServiceCategory>> fetchCategories() async {
    final client = _client;
    if (client == null) return MockData.categories;

    try {
      final rows = await client
          .from('service_categories')
          .select('id,name,icon')
          .eq('is_active', true)
          .order('sort_order');

      final categories = rows
          .map<ServiceCategory>(
            (row) => ServiceCategory.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList();
      return categories.isEmpty ? MockData.categories : categories;
    } catch (_) {
      return MockData.categories;
    }
  }

  Future<List<ServiceItem>> fetchServices() async {
    final client = _client;
    if (client == null) return MockData.services;

    try {
      final rows = await client
          .from('services')
          .select('id,name,duration_minutes,price,category_id')
          .eq('is_active', true)
          .order('name');

      final services = rows
          .map<ServiceItem>(
            (row) => ServiceItem.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList();
      return services.isEmpty ? MockData.services : services;
    } catch (_) {
      return MockData.services;
    }
  }
}
