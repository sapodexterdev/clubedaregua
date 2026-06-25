import '../config/supabase_config.dart';
import '../models/barber.dart';
import '../models/service_category.dart';
import '../models/service_item.dart';
import '../services/mock_data.dart';

class BarberRepository {
  Future<List<Barber>> fetchBarbers() async {
    if (!SupabaseConfig.isConfigured) return MockData.barbers;
    try {
      final data = await SupabaseConfig.client
          .from('barbers')
          .select('*, barber_shops(name)')
          .eq('is_active', true);
      return data.map<Barber>((row) => Barber.fromMap(row)).toList();
    } catch (_) {
      return MockData.barbers;
    }
  }

  Future<List<ServiceCategory>> fetchCategories() async {
    if (!SupabaseConfig.isConfigured) return MockData.categories;
    try {
      final data = await SupabaseConfig.client
          .from('service_categories')
          .select()
          .eq('is_active', true);
      return data.map<ServiceCategory>(ServiceCategory.fromMap).toList();
    } catch (_) {
      return MockData.categories;
    }
  }

  Future<List<ServiceItem>> fetchServices() async {
    if (!SupabaseConfig.isConfigured) return MockData.services;
    try {
      final data = await SupabaseConfig.client
          .from('services')
          .select()
          .eq('is_active', true);
      return data.map<ServiceItem>(ServiceItem.fromMap).toList();
    } catch (_) {
      return MockData.services;
    }
  }
}
