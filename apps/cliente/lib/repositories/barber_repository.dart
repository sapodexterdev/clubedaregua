import '../models/barber.dart';
import '../models/service_category.dart';
import '../models/service_item.dart';
import '../services/mock_data.dart';
import '../services/supabase_rest_service.dart';

class ShopIdentity {
  const ShopIdentity({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.coverUrl,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.instagram,
    required this.address,
    required this.city,
    required this.state,
    this.latitude,
    this.longitude,
    this.openingTime = '',
    this.closingTime = '',
    required this.secondaryColor,
    required this.bookingIntervalMinutes,
    required this.bookingDaysAhead,
    required this.minNoticeMinutes,
    required this.maxDelayMinutes,
    required this.minCancelHours,
  });

  final String id;
  final String name;
  final String logoUrl;
  final String coverUrl;
  final String phone;
  final String whatsapp;
  final String email;
  final String instagram;
  final String address;
  final String city;
  final String state;
  final double? latitude;
  final double? longitude;
  final String openingTime;
  final String closingTime;
  final String secondaryColor;
  final int bookingIntervalMinutes;
  final int bookingDaysAhead;
  final int minNoticeMinutes;
  final int maxDelayMinutes;
  final int minCancelHours;

  String get locationLabel {
    final parts = [city, state].where((part) => part.trim().isNotEmpty);
    return parts.isEmpty ? 'Barbearia parceira' : parts.join(' - ');
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get isOpenNow {
    final opening = _minutesFromTime(openingTime);
    final closing = _minutesFromTime(closingTime);
    if (opening == null || closing == null) return false;
    final now = DateTime.now();
    final current = now.hour * 60 + now.minute;
    if (closing > opening) return current >= opening && current < closing;
    return current >= opening || current < closing;
  }

  String get openingHoursLabel {
    final opening = _displayTime(openingTime);
    final closing = _displayTime(closingTime);
    if (opening.isEmpty || closing.isEmpty) return 'Horário não informado';
    return '$opening–$closing';
  }

  String get currentHoursDetail {
    final opening = _displayTime(openingTime);
    final closing = _displayTime(closingTime);
    if (opening.isEmpty || closing.isEmpty) return 'Consulte os horários';
    return isOpenNow ? 'Fecha às $closing' : 'Abre às $opening';
  }

  factory ShopIdentity.fromRows({
    required Map<String, dynamic> shop,
    required Map<String, dynamic>? settings,
  }) {
    final extra = settings?['settings'];
    final settingsJson =
        extra is Map ? Map<String, dynamic>.from(extra) : <String, dynamic>{};

    return ShopIdentity(
      id: shop['id']?.toString() ?? '',
      name: shop['name']?.toString() ?? 'Barbearia',
      logoUrl: shop['logo_url']?.toString() ?? '',
      coverUrl: shop['cover_url']?.toString() ?? '',
      phone: shop['phone']?.toString() ?? '',
      whatsapp: shop['whatsapp']?.toString() ?? '',
      email: settingsJson['email']?.toString() ?? '',
      instagram: settingsJson['instagram']?.toString() ?? '',
      address: shop['address']?.toString() ?? '',
      city: shop['city']?.toString() ?? '',
      state: shop['state']?.toString() ?? '',
      latitude: _asDouble(shop['latitude']),
      longitude: _asDouble(shop['longitude']),
      openingTime: shop['opening_time']?.toString() ?? '',
      closingTime: shop['closing_time']?.toString() ?? '',
      secondaryColor: settingsJson['secondary_color']?.toString() ?? '#F3B200',
      bookingIntervalMinutes: int.tryParse(
              settings?['booking_interval_minutes']?.toString() ?? '') ??
          30,
      bookingDaysAhead:
          int.tryParse(settingsJson['booking_days_ahead']?.toString() ?? '') ??
              30,
      minNoticeMinutes:
          int.tryParse(settingsJson['min_notice_minutes']?.toString() ?? '') ??
              60,
      maxDelayMinutes:
          int.tryParse(settingsJson['max_delay_minutes']?.toString() ?? '') ??
              15,
      minCancelHours:
          int.tryParse(settings?['min_cancel_hours']?.toString() ?? '') ?? 2,
    );
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _minutesFromTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  static String _displayTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return '';
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
}

class PublicBarbershop {
  const PublicBarbershop({
    required this.identity,
    required this.barbers,
    required this.services,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.nextSlot,
    required this.isOpen,
    required this.neighborhood,
  });

  final ShopIdentity identity;
  final List<Barber> barbers;
  final List<ServiceItem> services;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final String nextSlot;
  final bool isOpen;
  final String neighborhood;

  String get priceRange {
    if (services.isEmpty) return 'Consultar';
    final prices = services.map((service) => service.price).toList()..sort();
    final min = prices.first.toStringAsFixed(0);
    final max = prices.last.toStringAsFixed(0);
    if (min == max) return 'A partir de R\$ $min';
    return 'R\$ $min - R\$ $max';
  }

  String get distanceLabel => distanceKm.isFinite
      ? '${distanceKm.toStringAsFixed(1)} km'
      : 'Distância indisponível';
  String get statusLabel => isOpen ? 'Aberto' : 'Fechado';
}

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
            'id,barber_shop_id,name,bio,photo_url,rating,starting_price,barber_shops(name),barber_services(service_id,is_active,services(id,category_id,is_active))',
        filters: const {'is_active': 'eq.true'},
        order: 'name.asc',
      );

      final barbers = rows.map<Barber>((row) {
        final links = row['barber_services'] as List<dynamic>? ?? const [];
        final activeLinks = links.where((link) {
          final service = link['services'];
          return link['is_active'] != false && service?['is_active'] != false;
        });
        final categoryIds = activeLinks
            .map((link) => link['services']?['category_id'])
            .where((id) => id != null)
            .map((id) => id.toString())
            .toSet()
            .toList();
        final serviceIds = activeLinks
            .map((link) => link['service_id'] ?? link['services']?['id'])
            .where((id) => id != null)
            .map((id) => id.toString())
            .toSet()
            .toList();

        return Barber.fromMap({
          ...row,
          'category_ids': categoryIds,
          'service_ids': serviceIds,
        });
      }).toList();

      return barbers;
    } catch (_) {
      return const [];
    }
  }

  Future<ShopIdentity?> fetchShopIdentity({String? barberShopId}) async {
    if (!_rest.isConfigured) return null;

    try {
      final shops = await _rest.getRows(
        'barber_shops',
        select: 'id,name,phone,whatsapp,address,city,state,latitude,longitude,opening_time,closing_time,logo_url,cover_url',
        filters: {
          'is_active': 'eq.true',
          if (barberShopId != null && barberShopId.isNotEmpty)
            'id': 'eq.$barberShopId',
        },
        order: 'name.asc',
        limit: 1,
      );
      if (shops.isEmpty) return null;

      final shopId = shops.first['id']?.toString() ?? '';
      final settings = await _rest.getRows(
        'shop_settings',
        select: 'booking_interval_minutes,min_cancel_hours,settings',
        filters: {'barber_shop_id': 'eq.$shopId'},
        limit: 1,
      );

      return ShopIdentity.fromRows(
        shop: shops.first,
        settings: settings.isEmpty ? null : settings.first,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<ShopIdentity>> fetchShopIdentities() async {
    if (!_rest.isConfigured) {
      return const [
        ShopIdentity(
          id: MockData.demoShopId,
          name: 'Barbearia Elite',
          logoUrl: '',
          coverUrl: '',
          phone: '',
          whatsapp: '',
          email: '',
          instagram: '@barbeariaelite',
          address: 'Centro',
          city: 'Sao Paulo',
          state: 'SP',
          secondaryColor: '#F3B200',
          bookingIntervalMinutes: 30,
          bookingDaysAhead: 30,
          minNoticeMinutes: 60,
          maxDelayMinutes: 15,
          minCancelHours: 2,
        ),
      ];
    }

    try {
      final shops = await _rest.getRows(
        'barber_shops',
        select: 'id,name,phone,whatsapp,address,city,state,latitude,longitude,opening_time,closing_time,logo_url,cover_url',
        filters: const {'is_active': 'eq.true'},
        order: 'name.asc',
      );

      final identities = <ShopIdentity>[];
      for (final shop in shops) {
        final shopId = shop['id']?.toString() ?? '';
        if (shopId.isEmpty) continue;
        final settings = await _rest.getRows(
          'shop_settings',
          select: 'booking_interval_minutes,min_cancel_hours,settings',
          filters: {'barber_shop_id': 'eq.$shopId'},
          limit: 1,
        );
        identities.add(
          ShopIdentity.fromRows(
            shop: shop,
            settings: settings.isEmpty ? null : settings.first,
          ),
        );
      }
      return identities;
    } catch (_) {
      rethrow;
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
      return categories;
    } catch (_) {
      return const [];
    }
  }

  Future<List<ServiceItem>> fetchServices() async {
    if (!_rest.isConfigured) return MockData.services;

    try {
      final rows = await _rest.getRows(
        'services',
        select: 'id,barber_shop_id,name,duration_minutes,price,category_id',
        filters: const {'is_active': 'eq.true'},
        order: 'name.asc',
      );

      final services =
          rows.map<ServiceItem>((row) => ServiceItem.fromMap(row)).toList();
      return services;
    } catch (_) {
      return const [];
    }
  }
}
