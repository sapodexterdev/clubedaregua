part of 'management.dart';

enum ProductStatusFilter { all, active, lowStock, inactive }

class PasswordRecoveryLink {
  const PasswordRecoveryLink._();

  static PasswordRecoverySession? get session {
    final params = <String, String>{...Uri.base.queryParameters};
    final fragmentParams = _fragmentParams(Uri.base.fragment);
    params.addAll(fragmentParams);

    final type = params['type'];
    final token = params['access_token'];
    if (type == 'recovery' && token != null && token.isNotEmpty) {
      return PasswordRecoverySession(
        accessToken: token,
        refreshToken: params['refresh_token'],
      );
    }

    return null;
  }

  static Map<String, String> _fragmentParams(String fragment) {
    if (fragment.isEmpty) return const {};

    if (fragment.contains('=') && !fragment.startsWith('/')) {
      return Uri.splitQueryString(fragment);
    }

    final parsed = Uri.tryParse(fragment);
    if (parsed == null) return const {};
    return parsed.queryParameters;
  }
}

class PasswordRecoverySession {
  const PasswordRecoverySession({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
}

class BookingRequest {
  const BookingRequest({
    required this.id,
    required this.barberId,
    required this.client,
    required this.phone,
    required this.clientPhotoUrl,
    required this.service,
    required this.barber,
    required this.date,
    required this.time,
    required this.status,
    required this.total,
    required this.notes,
    required this.updatedAt,
  });

  final String id;
  final String barberId;
  final String client;
  final String phone;
  final String clientPhotoUrl;
  final String service;
  final String barber;
  final String date;
  final String time;
  final String status;
  final double total;
  final String notes;
  final String updatedAt;

  String get paymentMethod {
    final match = RegExp(r'Pagamento:\s*([^.]+)').firstMatch(notes);
    return match?.group(1)?.trim() ?? 'Não informado';
  }

  String get formattedDate {
    final parts = date.split('-');
    if (parts.length != 3 || parts.first.length < 4) return date;

    final year = parts[0].substring(2);
    return '${parts[2]}/${parts[1]}/$year';
  }

  String get formattedDateTime => '$formattedDate às $time';

  String get observation {
    final value = notes
        .replaceAll(RegExp(r'Solicitacao criada pelo PWA Cliente\.\s*'), '')
        .replaceAll(RegExp(r'Pagamento:\s*[^.]+\.?'), '')
        .trim();
    return value.isEmpty ? 'Sem observações.' : value;
  }

  BookingRequest copyWith({
    String? status,
    String? notes,
    String? updatedAt,
  }) {
    return BookingRequest(
      id: id,
      barberId: barberId,
      client: client,
      phone: phone,
      clientPhotoUrl: clientPhotoUrl,
      service: service,
      barber: barber,
      date: date,
      time: time,
      status: status ?? this.status,
      total: total,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory BookingRequest.fromMap(Map<String, dynamic> map) {
    return BookingRequest(
      id: map['id']?.toString() ?? '',
      barberId: map['barber_id']?.toString() ?? '',
      client: map['customer_name']?.toString() ?? 'Cliente',
      phone: map['customer_phone']?.toString() ?? '',
      clientPhotoUrl: map['customer_photo_url']?.toString() ?? '',
      service: map['services']?['name']?.toString() ?? 'Serviço',
      barber: map['barbers']?['name']?.toString() ?? 'Barbeiro',
      date: map['requested_date']?.toString() ?? '',
      time: _timeOnly(map['requested_time']?.toString() ?? ''),
      status: map['status']?.toString() ?? 'new',
      total: (map['total_price'] as num?)?.toDouble() ?? 0,
      notes: map['notes']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
    );
  }

  static String _timeOnly(String value) {
    if (value.length >= 5) return value.substring(0, 5);
    return value;
  }
}

class TeamBarber {
  const TeamBarber({
    required this.id,
    required this.barberShopId,
    required this.userId,
    required this.name,
    required this.bio,
    required this.photoUrl,
    required this.startingPrice,
    required this.commissionPercent,
    required this.isActive,
  });

  final String id;
  final String barberShopId;
  final String userId;
  final String name;
  final String bio;
  final String photoUrl;
  final double startingPrice;
  final double commissionPercent;
  final bool isActive;

  String get role =>
      commissionPercent >= 40 ? 'Barbeiro principal' : 'Barbeiro';

  String get detail {
    final commission = commissionPercent.toStringAsFixed(0);
    final status = userId.isEmpty
        ? 'convite pendente'
        : isActive
            ? 'agenda ativa'
            : 'inativo';
    return '$commission% comissão - $status';
  }

  factory TeamBarber.fromMap(Map<String, dynamic> map) {
    return TeamBarber(
      id: map['id']?.toString() ?? '',
      barberShopId: map['barber_shop_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Barbeiro',
      bio: map['bio']?.toString() ?? '',
      photoUrl: map['photo_url']?.toString() ?? '',
      startingPrice: (map['starting_price'] as num?)?.toDouble() ?? 0,
      commissionPercent: (map['commission_percent'] as num?)?.toDouble() ?? 0,
      isActive: map['is_active'] != false,
    );
  }
}

class TeamInvitationLink {
  const TeamInvitationLink({
    required this.email,
    required this.url,
    this.setupWarning,
  });

  final String email;
  final String url;
  final String? setupWarning;
}

class ScheduleEntry {
  const ScheduleEntry({
    required this.id,
    required this.appointmentId,
    required this.time,
    required this.client,
    required this.service,
    required this.barber,
    required this.status,
    required this.notes,
  });

  final String id;
  final String? appointmentId;
  final String time;
  final String client;
  final String service;
  final String barber;
  final String status;
  final String notes;

  factory ScheduleEntry.fromBookingRequest(Map<String, dynamic> map) {
    return ScheduleEntry(
      id: 'request-${map['id']}',
      appointmentId: null,
      time: _timeOnly(map['requested_time']?.toString() ?? ''),
      client: map['customer_name']?.toString() ?? 'Cliente',
      service: map['services']?['name']?.toString() ?? 'Serviço',
      barber: map['barbers']?['name']?.toString() ?? 'Barbeiro',
      status: 'Aceito',
      notes: _cleanNotes(map['notes']?.toString() ?? ''),
    );
  }

  factory ScheduleEntry.fromAppointment(Map<String, dynamic> map) {
    final startsAt = map['starts_at']?.toString() ?? '';
    return ScheduleEntry(
      id: 'appointment-${map['id']}',
      appointmentId: map['id']?.toString(),
      time: startsAt.length >= 16 ? startsAt.substring(11, 16) : '',
      client: 'Cliente agendado',
      service: map['services']?['name']?.toString() ?? 'Serviço',
      barber: map['barbers']?['name']?.toString() ?? 'Barbeiro',
      status: _statusLabel(map['status']?.toString() ?? ''),
      notes: map['notes']?.toString().trim().isEmpty == false
          ? map['notes'].toString()
          : 'Sem observações.',
    );
  }

  bool get canComplete =>
      appointmentId != null && (status == 'Pendente' || status == 'Confirmado');

  static String _timeOnly(String value) {
    if (value.length >= 5) return value.substring(0, 5);
    return value;
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'Pendente',
      'confirmed' => 'Confirmado',
      'completed' => 'Concluido',
      'cancelled' => 'Cancelado',
      _ => status.isEmpty ? 'Agendado' : status,
    };
  }

  static String _cleanNotes(String notes) {
    final clean = notes
        .replaceAll(RegExp(r'Solicitacao criada pelo PWA Cliente\.\s*'), '')
        .trim();
    return clean.isEmpty ? 'Sem observações.' : clean;
  }
}

class BarberAvailabilityDay {
  const BarberAvailabilityDay({
    required this.weekday,
    required this.label,
    required this.isActive,
    required this.startTime,
    required this.endTime,
    this.slotMinutes = 30,
  });

  final int weekday;
  final String label;
  final bool isActive;
  final String startTime;
  final String endTime;
  final int slotMinutes;

  BarberAvailabilityDay copyWith({
    bool? isActive,
    String? startTime,
    String? endTime,
    int? slotMinutes,
  }) {
    return BarberAvailabilityDay(
      weekday: weekday,
      label: label,
      isActive: isActive ?? this.isActive,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      slotMinutes: slotMinutes ?? this.slotMinutes,
    );
  }

  static List<BarberAvailabilityDay> defaults() => const [
        BarberAvailabilityDay(
          weekday: 1,
          label: 'Segunda-feira',
          isActive: true,
          startTime: '09:00',
          endTime: '18:00',
        ),
        BarberAvailabilityDay(
          weekday: 2,
          label: 'Terça-feira',
          isActive: true,
          startTime: '09:00',
          endTime: '18:00',
        ),
        BarberAvailabilityDay(
          weekday: 3,
          label: 'Quarta-feira',
          isActive: true,
          startTime: '09:00',
          endTime: '18:00',
        ),
        BarberAvailabilityDay(
          weekday: 4,
          label: 'Quinta-feira',
          isActive: true,
          startTime: '09:00',
          endTime: '18:00',
        ),
        BarberAvailabilityDay(
          weekday: 5,
          label: 'Sexta-feira',
          isActive: true,
          startTime: '09:00',
          endTime: '18:00',
        ),
        BarberAvailabilityDay(
          weekday: 6,
          label: 'Sábado',
          isActive: true,
          startTime: '09:00',
          endTime: '14:00',
        ),
        BarberAvailabilityDay(
          weekday: 0,
          label: 'Domingo',
          isActive: false,
          startTime: '09:00',
          endTime: '14:00',
        ),
      ];
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final bool isActive;
  final int sortOrder;

  factory ServiceCategory.fromMap(Map<String, dynamic> map) {
    return ServiceCategory(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Categoria',
      isActive: map['is_active'] == true,
      sortOrder: int.tryParse(map['sort_order']?.toString() ?? '') ?? 0,
    );
  }
}

class ManagedService {
  const ManagedService({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.durationMinutes,
    required this.imageUrl,
    required this.isActive,
    required this.appointmentCount,
  });

  final String id;
  final String name;
  final String description;
  final String? categoryId;
  final String categoryName;
  final double price;
  final int durationMinutes;
  final String imageUrl;
  final bool isActive;
  final int appointmentCount;

  String get formattedPrice =>
      'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
  String get durationLabel => '$durationMinutes min';
  String get statusLabel => isActive ? 'Ativo' : 'Inativo';

  factory ManagedService.fromMap(
    Map<String, dynamic> map, {
    int appointmentCount = 0,
  }) {
    final category = map['service_categories'];
    return ManagedService(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Serviço',
      description: map['description']?.toString() ?? '',
      categoryId: map['category_id']?.toString(),
      categoryName: category is Map
          ? category['name']?.toString() ?? 'Sem categoria'
          : 'Sem categoria',
      price: double.tryParse(map['price']?.toString() ?? '') ?? 0,
      durationMinutes:
          int.tryParse(map['duration_minutes']?.toString() ?? '') ?? 30,
      imageUrl: map['image_url']?.toString() ?? '',
      isActive: map['is_active'] == true,
      appointmentCount: appointmentCount,
    );
  }

  ManagedService copyWith({
    int? appointmentCount,
  }) {
    return ManagedService(
      id: id,
      name: name,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      price: price,
      durationMinutes: durationMinutes,
      imageUrl: imageUrl,
      isActive: isActive,
      appointmentCount: appointmentCount ?? this.appointmentCount,
    );
  }
}

enum ServiceStatusFilter { all, active, inactive }

enum CustomerStatusFilter { all, active, inactive, recent }

const _allBarbersDropdownValue = '__all_barbers__';
const _allCategoriesDropdownValue = '__all_categories__';
const _noCategoryDropdownValue = '__no_category__';

class ManagedCustomer {
  const ManagedCustomer({
    required this.relationshipId,
    required this.clientId,
    required this.name,
    required this.phone,
    required this.email,
    required this.avatarUrl,
    required this.createdAt,
    required this.firstSeenAt,
    required this.lastAppointmentAt,
    required this.notes,
    required this.isBlocked,
    required this.blockedBarberIds,
    required this.appointmentCount,
    required this.favoriteBarber,
  });

  final String relationshipId;
  final String clientId;
  final String name;
  final String phone;
  final String email;
  final String avatarUrl;
  final DateTime? createdAt;
  final DateTime? firstSeenAt;
  final DateTime? lastAppointmentAt;
  final String notes;
  final bool isBlocked;
  final Set<String> blockedBarberIds;
  final int appointmentCount;
  final String favoriteBarber;

  bool get canEdit =>
      relationshipId.isNotEmpty && !clientId.startsWith('booking:');
  bool get isActive => !isBlocked;
  bool get hasBookingBlock => isBlocked || blockedBarberIds.isNotEmpty;
  String get statusLabel => isBlocked
      ? 'Bloqueado'
      : blockedBarberIds.isNotEmpty
          ? 'Restrito'
          : 'Ativo';
  String get lastAppointmentLabel => lastAppointmentAt == null
      ? 'Sem atendimento'
      : _formatDate(lastAppointmentAt!);
  bool get isRecent {
    final base = firstSeenAt ?? createdAt;
    if (base == null) return false;
    return base.isAfter(DateTime.now().subtract(const Duration(days: 30)));
  }

  factory ManagedCustomer.fromMap(
    Map<String, dynamic> map, {
    required int appointmentCount,
    required String favoriteBarber,
    DateTime? computedLastAppointmentAt,
  }) {
    return ManagedCustomer(
      relationshipId: map['relationship_id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      name: (map['full_name']?.toString().trim().isNotEmpty == true
              ? map['full_name']?.toString()
              : map['email']?.toString()) ??
          'Cliente',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      avatarUrl: map['avatar_url']?.toString() ?? '',
      createdAt: _parseDateTime(map['profile_created_at']?.toString()),
      firstSeenAt: _parseDateTime(map['first_seen_at']?.toString()),
      lastAppointmentAt: computedLastAppointmentAt ??
          _parseDateTime(map['last_appointment_at']?.toString()),
      notes: map['notes']?.toString() ?? '',
      isBlocked: map['is_blocked'] == true,
      blockedBarberIds: const {},
      appointmentCount: appointmentCount,
      favoriteBarber: favoriteBarber,
    );
  }

  factory ManagedCustomer.fromBookingRequest(
    Map<String, dynamic> map, {
    required int appointmentCount,
    required String favoriteBarber,
    DateTime? computedLastAppointmentAt,
  }) {
    final phone = map['customer_phone']?.toString() ?? '';
    return ManagedCustomer(
      relationshipId: '',
      clientId: 'booking:${_digitsOnly(phone)}',
      name: map['customer_name']?.toString() ?? 'Cliente',
      phone: phone,
      email: '',
      avatarUrl: '',
      createdAt: _parseDateTime(map['created_at']?.toString()),
      firstSeenAt: _parseDateTime(map['created_at']?.toString()),
      lastAppointmentAt: computedLastAppointmentAt,
      notes: map['notes']?.toString() ?? '',
      isBlocked: false,
      blockedBarberIds: const {},
      appointmentCount: appointmentCount,
      favoriteBarber: favoriteBarber,
    );
  }

  ManagedCustomer copyWith({
    String? name,
    String? phone,
    String? notes,
    bool? isBlocked,
    Set<String>? blockedBarberIds,
  }) {
    return ManagedCustomer(
      relationshipId: relationshipId,
      clientId: clientId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      firstSeenAt: firstSeenAt,
      lastAppointmentAt: lastAppointmentAt,
      notes: notes ?? this.notes,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedBarberIds: Set.unmodifiable(
        blockedBarberIds ?? this.blockedBarberIds,
      ),
      appointmentCount: appointmentCount,
      favoriteBarber: favoriteBarber,
    );
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  static String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }
}

class CustomerAppointment {
  const CustomerAppointment({
    required this.id,
    required this.clientId,
    required this.date,
    required this.service,
    required this.barber,
    required this.status,
    required this.notes,
  });

  final String id;
  final String clientId;
  final DateTime? date;
  final String service;
  final String barber;
  final String status;
  final String notes;

  String get dateLabel =>
      date == null ? '-' : ManagedCustomer._formatDate(date!);

  factory CustomerAppointment.fromMap(Map<String, dynamic> map) {
    return CustomerAppointment(
      id: map['id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      date: ManagedCustomer._parseDateTime(map['starts_at']?.toString()),
      service: map['service_name']?.toString() ?? 'Serviço',
      barber: map['barber_name']?.toString() ?? 'Barbeiro',
      status: ScheduleEntry._statusLabel(map['status']?.toString() ?? ''),
      notes: map['notes']?.toString() ?? '',
    );
  }

  factory CustomerAppointment.fromBookingRequest(Map<String, dynamic> map) {
    final date = map['requested_date']?.toString() ?? '';
    final time = map['requested_time']?.toString() ?? '';
    return CustomerAppointment(
      id: 'booking-${map['id']}',
      clientId:
          'booking:${ManagedCustomer._digitsOnly(map['customer_phone']?.toString() ?? '')}',
      date: ManagedCustomer._parseDateTime(
          '$date ${time.isEmpty ? '00:00' : time}'),
      service: map['services']?['name']?.toString() ?? 'Serviço',
      barber: map['barbers']?['name']?.toString() ?? 'Barbeiro',
      status: _bookingStatusLabel(map['status']?.toString() ?? ''),
      notes: map['notes']?.toString() ?? '',
    );
  }

  static String _bookingStatusLabel(String status) {
    return switch (status) {
      'new' => 'Novo',
      'contacted' => 'Contatado',
      'converted' => 'Aceito',
      'cancelled' => 'Cancelado',
      _ => status.isEmpty ? 'Solicitado' : status,
    };
  }
}

class ManagedProduct {
  const ManagedProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.sku,
    required this.barcode,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.minQuantity,
    required this.unitCost,
    required this.salePrice,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final String sku;
  final String barcode;
  final String category;
  final String unit;
  final int quantity;
  final int minQuantity;
  final double unitCost;
  final double salePrice;
  final bool isActive;

  bool get isLowStock => isActive && quantity <= minQuantity;
  double get stockCost => quantity * unitCost;
  double get stockSaleValue => quantity * salePrice;

  factory ManagedProduct.fromMap(Map<String, dynamic> map) {
    return ManagedProduct(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      sku: map['sku']?.toString() ?? '',
      barcode: map['barcode']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      unit: map['unit']?.toString() ?? 'un',
      quantity: int.tryParse(map['quantity']?.toString() ?? '') ?? 0,
      minQuantity: int.tryParse(map['min_quantity']?.toString() ?? '') ?? 0,
      unitCost: double.tryParse(map['unit_cost']?.toString() ?? '') ?? 0,
      salePrice: double.tryParse(map['sale_price']?.toString() ?? '') ?? 0,
      isActive: map['is_active'] != false,
    );
  }
}

class ProductSaleItem {
  const ProductSaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String productId;
  final String productName;
  final int quantity;
  final String unit;
  final double unitPrice;
  final double lineTotal;

  factory ProductSaleItem.fromMap(Map<String, dynamic> map) {
    return ProductSaleItem(
      productId: map['stock_item_id']?.toString() ?? '',
      productName: map['product_name']?.toString() ?? 'Produto',
      quantity: int.tryParse(map['quantity']?.toString() ?? '') ?? 0,
      unit: map['unit']?.toString() ?? 'un',
      unitPrice: double.tryParse(map['unit_price']?.toString() ?? '') ?? 0,
      lineTotal: double.tryParse(map['line_total']?.toString() ?? '') ?? 0,
    );
  }
}

class ProductSale {
  const ProductSale({
    required this.id,
    required this.status,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.customerName,
    required this.notes,
    required this.soldAt,
    required this.cancellationReason,
    required this.items,
  });

  final String id;
  final String status;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;
  final String customerName;
  final String notes;
  final DateTime? soldAt;
  final String cancellationReason;
  final List<ProductSaleItem> items;

  bool get isCancelled => status == 'cancelled';

  factory ProductSale.fromMap(Map<String, dynamic> map) {
    final rawItems = map['product_sale_items'];
    return ProductSale(
      id: map['id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'completed',
      subtotal: double.tryParse(map['subtotal']?.toString() ?? '') ?? 0,
      discount: double.tryParse(map['discount']?.toString() ?? '') ?? 0,
      total: double.tryParse(map['total']?.toString() ?? '') ?? 0,
      paymentMethod: map['payment_method']?.toString() ?? 'other',
      customerName: map['customer_name']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      soldAt: DateTime.tryParse(map['sold_at']?.toString() ?? ''),
      cancellationReason: map['cancellation_reason']?.toString() ?? '',
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => ProductSaleItem.fromMap(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }
}

class ProductCartLine {
  const ProductCartLine({required this.product, required this.quantity});

  final ManagedProduct product;
  final int quantity;
  double get total => product.salePrice * quantity;
}

class ShopBusinessDay {
  const ShopBusinessDay({
    required this.key,
    required this.label,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  final String key;
  final String label;
  final bool isOpen;
  final String openTime;
  final String closeTime;

  ShopBusinessDay copyWith({
    bool? isOpen,
    String? openTime,
    String? closeTime,
  }) {
    return ShopBusinessDay(
      key: key,
      label: label,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_open': isOpen,
        'open_time': openTime,
        'close_time': closeTime,
      };
}

class ShopConfiguration {
  const ShopConfiguration({
    required this.shopId,
    required this.settingsId,
    required this.name,
    required this.logoUrl,
    required this.coverUrl,
    required this.document,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.instagram,
    required this.address,
    required this.zipCode,
    required this.city,
    required this.state,
    required this.days,
    required this.lunchEnabled,
    required this.lunchStart,
    required this.lunchEnd,
    required this.bookingIntervalMinutes,
    required this.bookingDaysAhead,
    required this.minNoticeMinutes,
    required this.maxDelayMinutes,
    required this.minCancelHours,
    required this.secondaryColor,
  });

  final String shopId;
  final String settingsId;
  final String name;
  final String logoUrl;
  final String coverUrl;
  final String document;
  final String phone;
  final String whatsapp;
  final String email;
  final String instagram;
  final String address;
  final String zipCode;
  final String city;
  final String state;
  final List<ShopBusinessDay> days;
  final bool lunchEnabled;
  final String lunchStart;
  final String lunchEnd;
  final int bookingIntervalMinutes;
  final int bookingDaysAhead;
  final int minNoticeMinutes;
  final int maxDelayMinutes;
  final int minCancelHours;
  final String secondaryColor;

  factory ShopConfiguration.fromRows({
    required Map<String, dynamic> shop,
    required Map<String, dynamic>? settings,
  }) {
    final extra = settings?['settings'];
    final settingsJson =
        extra is Map ? Map<String, dynamic>.from(extra) : <String, dynamic>{};
    final weekly = settingsJson['weekly_hours'];
    final weeklyJson =
        weekly is Map ? Map<String, dynamic>.from(weekly) : <String, dynamic>{};

    return ShopConfiguration(
      shopId: shop['id']?.toString() ?? '',
      settingsId: settings?['id']?.toString() ?? '',
      name: shop['name']?.toString() ?? '',
      logoUrl: shop['logo_url']?.toString() ?? '',
      coverUrl: shop['cover_url']?.toString() ?? '',
      document: shop['document']?.toString() ?? '',
      phone: shop['phone']?.toString() ?? '',
      whatsapp: shop['whatsapp']?.toString() ?? '',
      email: settingsJson['email']?.toString() ?? '',
      instagram: settingsJson['instagram']?.toString() ?? '',
      address: shop['address']?.toString() ?? '',
      zipCode: settingsJson['zip_code']?.toString() ?? '',
      city: shop['city']?.toString() ?? '',
      state: shop['state']?.toString() ?? '',
      days: _defaultDays.map((day) {
        final row = weeklyJson[day.key];
        final rowJson =
            row is Map ? Map<String, dynamic>.from(row) : <String, dynamic>{};
        return day.copyWith(
          isOpen: rowJson['is_open'] is bool
              ? rowJson['is_open'] as bool
              : day.isOpen,
          openTime: rowJson['open_time']?.toString() ?? day.openTime,
          closeTime: rowJson['close_time']?.toString() ?? day.closeTime,
        );
      }).toList(),
      lunchEnabled: settingsJson['lunch_enabled'] == true,
      lunchStart: settingsJson['lunch_start']?.toString() ?? '12:00',
      lunchEnd: settingsJson['lunch_end']?.toString() ?? '13:00',
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
      secondaryColor: settingsJson['secondary_color']?.toString() ?? '#F3B200',
    );
  }

  Map<String, dynamic> settingsJson() => {
        'email': email,
        'instagram': instagram,
        'zip_code': zipCode,
        'lunch_enabled': lunchEnabled,
        'lunch_start': lunchStart,
        'lunch_end': lunchEnd,
        'booking_days_ahead': bookingDaysAhead,
        'min_notice_minutes': minNoticeMinutes,
        'max_delay_minutes': maxDelayMinutes,
        'secondary_color': secondaryColor,
        'weekly_hours': {
          for (final day in days) day.key: day.toJson(),
        },
      };

  static const _defaultDays = [
    ShopBusinessDay(
      key: 'monday',
      label: 'Segunda',
      isOpen: true,
      openTime: '09:00',
      closeTime: '18:00',
    ),
    ShopBusinessDay(
      key: 'tuesday',
      label: 'Terça',
      isOpen: true,
      openTime: '09:00',
      closeTime: '18:00',
    ),
    ShopBusinessDay(
      key: 'wednesday',
      label: 'Quarta',
      isOpen: true,
      openTime: '09:00',
      closeTime: '18:00',
    ),
    ShopBusinessDay(
      key: 'thursday',
      label: 'Quinta',
      isOpen: true,
      openTime: '09:00',
      closeTime: '18:00',
    ),
    ShopBusinessDay(
      key: 'friday',
      label: 'Sexta',
      isOpen: true,
      openTime: '09:00',
      closeTime: '18:00',
    ),
    ShopBusinessDay(
      key: 'saturday',
      label: 'Sábado',
      isOpen: true,
      openTime: '09:00',
      closeTime: '14:00',
    ),
    ShopBusinessDay(
      key: 'sunday',
      label: 'Domingo',
      isOpen: false,
      openTime: '09:00',
      closeTime: '14:00',
    ),
  ];
}
