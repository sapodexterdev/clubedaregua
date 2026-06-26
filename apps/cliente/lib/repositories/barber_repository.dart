import '../models/barber.dart';
import '../models/service_category.dart';
import '../models/service_item.dart';
import '../services/mock_data.dart';

class BarberRepository {
  Future<List<Barber>> fetchBarbers() async {
    return MockData.barbers;
  }

  Future<List<ServiceCategory>> fetchCategories() async {
    return MockData.categories;
  }

  Future<List<ServiceItem>> fetchServices() async {
    return MockData.services;
  }
}
