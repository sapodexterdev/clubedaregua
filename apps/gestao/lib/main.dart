import 'dart:convert';

import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/app_mode_navigation.dart';
import 'utils/logo_file.dart';
import 'utils/logo_picker.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ManagementSession()..restoreUnifiedSession(),
      child: const ClubeDaReguaGestaoApp(),
    ),
  );
}

class ClubeDaReguaGestaoApp extends StatelessWidget {
  const ClubeDaReguaGestaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clube da Régua Gestão',
      debugShowCheckedModeBanner: false,
      theme: _buildManagementTheme(),
      home: Consumer<ManagementSession>(
        builder: (context, session, _) {
          final recoverySession = PasswordRecoveryLink.session;
          if (recoverySession != null) {
            return PasswordRecoveryScreen(session: recoverySession);
          }
          if (session.isRestoringSession) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: SharedAppColors.orange),
              ),
            );
          }
          if (!session.isSignedIn) return const ManagementLoginScreen();
          return const ManagementHomeScreen();
        },
      ),
    );
  }
}

ThemeData _buildManagementTheme() {
  const scheme = ColorScheme.dark(
    primary: SharedAppColors.orange,
    onPrimary: SharedAppColors.onGold,
    secondary: SharedAppColors.orange,
    onSecondary: SharedAppColors.onGold,
    surface: SharedAppColors.card,
    onSurface: SharedAppColors.text,
    error: Color(0xFFEF4444),
  );
  final base = ThemeData(
    colorScheme: scheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SharedAppColors.background,
    canvasColor: SharedAppColors.card,
    useMaterial3: true,
    fontFamily: 'Inter',
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: SharedAppColors.card,
      foregroundColor: SharedAppColors.text,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: SharedAppColors.text,
        fontFamily: 'Barlow Condensed',
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    ),
    dividerColor: SharedAppColors.stroke,
    cardColor: SharedAppColors.card,
    dialogTheme: DialogTheme(
      backgroundColor: SharedAppColors.elevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: SharedAppColors.card,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: SharedAppColors.card,
      showDragHandle: true,
      dragHandleColor: SharedAppColors.stroke,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SharedAppColors.card,
      labelStyle: const TextStyle(color: SharedAppColors.muted),
      hintStyle: const TextStyle(color: SharedAppColors.muted),
      prefixIconColor: SharedAppColors.muted,
      suffixIconColor: SharedAppColors.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SharedAppColors.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SharedAppColors.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SharedAppColors.orange, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SharedAppColors.orange,
        foregroundColor: SharedAppColors.onGold,
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SharedAppColors.text,
        minimumSize: const Size(64, 48),
        side: const BorderSide(color: SharedAppColors.stroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: SharedAppColors.orange),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: SharedAppColors.card,
      indicatorColor: SharedAppColors.orange,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? SharedAppColors.orange
              : SharedAppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? SharedAppColors.onGold
              : SharedAppColors.muted,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: SharedAppColors.elevated,
      selectedColor: SharedAppColors.orange,
      side: const BorderSide(color: SharedAppColors.stroke),
      labelStyle: const TextStyle(color: SharedAppColors.text),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: SharedAppColors.elevated,
      contentTextStyle: TextStyle(color: SharedAppColors.text),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class GestaoSupabaseConfig {
  const GestaoSupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      url.startsWith('https://') && anonKey.trim().isNotEmpty;
}

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
    final status = isActive ? 'agenda ativa' : 'inativo';
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
      appointmentId != null &&
      (status == 'Pendente' || status == 'Confirmado');

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
  final int appointmentCount;
  final String favoriteBarber;

  bool get canEdit =>
      relationshipId.isNotEmpty && !clientId.startsWith('booking:');
  bool get isActive => !isBlocked;
  String get statusLabel => isActive ? 'Ativo' : 'Inativo';
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
      appointmentCount: appointmentCount,
      favoriteBarber: favoriteBarber,
    );
  }

  ManagedCustomer copyWith({
    String? name,
    String? phone,
    String? notes,
    bool? isBlocked,
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

class ManagementSession extends ChangeNotifier {
  static const _unifiedSessionKey = 'clubedaregua.client.session';

  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  String? _barberShopId;
  bool _isPlatformAdmin = false;
  String? barberShopName;
  String? email;
  bool isLoading = false;
  bool isRestoringSession = true;
  String? errorMessage;
  bool isBookingRequestsLoading = false;
  String? bookingRequestsError;
  String? bookingRequestActionError;
  List<BookingRequest> bookingRequests = [];
  List<TeamBarber> teamBarbers = [];
  List<ScheduleEntry> scheduleEntries = [];
  List<ManagedService> services = [];
  List<ServiceCategory> serviceCategories = [];
  List<ManagedCustomer> customers = [];
  List<CustomerAppointment> customerAppointments = [];
  ShopConfiguration? shopConfiguration;
  bool isScheduleLoading = false;
  bool isServicesLoading = false;
  bool isCustomersLoading = false;
  bool isSettingsLoading = false;
  String? scheduleError;
  String? servicesError;
  String? customersError;
  String? settingsError;
  DateTime selectedScheduleDate = DateTime.now();
  String? selectedScheduleBarberId;
  bool scheduleAdminView = false;
  ServiceStatusFilter serviceStatusFilter = ServiceStatusFilter.all;
  CustomerStatusFilter customerStatusFilter = CustomerStatusFilter.all;
  String? selectedServiceCategoryId;
  String serviceSearchQuery = '';
  String customerSearchQuery = '';

  bool get isSignedIn => _accessToken != null;

  Future<void> restoreUnifiedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_unifiedSessionKey);
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _accessToken = data['access_token']?.toString();
      _refreshToken = data['refresh_token']?.toString();
      final user = data['user'];
      if (user is Map) {
        _userId = user['id']?.toString();
        email = user['email']?.toString();
      }
      if (_accessToken == null || _accessToken!.isEmpty) {
        _clearSessionInMemory();
        return;
      }
      await _resolvePlatformAdmin(_accessToken!);
      await _ensureBarberShopId(_accessToken!);
      await refreshManagementData();
    } catch (error) {
      _clearSessionInMemory();
      errorMessage = 'Sua conta não possui acesso profissional ativo.';
    } finally {
      isRestoringSession = false;
      notifyListeners();
    }
  }

  TeamBarber? get currentBarber {
    final userId = _userId;
    if (userId != null && userId.isNotEmpty) {
      for (final barber in teamBarbers) {
        if (barber.userId == userId && barber.isActive) return barber;
      }
    }

    return null;
  }

  String get barberHeaderName =>
      currentBarber?.name ?? barberShopName ?? 'Agenda do barbeiro';

  TeamBarber? get selectedScheduleBarber {
    final id = selectedScheduleBarberId;
    if (id == null || id.isEmpty) return null;
    for (final barber in teamBarbers) {
      if (barber.id == id) return barber;
    }
    return null;
  }

  List<ManagedService> get filteredServices {
    final query = serviceSearchQuery.trim().toLowerCase();
    return services.where((service) {
      final matchesStatus = switch (serviceStatusFilter) {
        ServiceStatusFilter.all => true,
        ServiceStatusFilter.active => service.isActive,
        ServiceStatusFilter.inactive => !service.isActive,
      };
      final matchesCategory = selectedServiceCategoryId == null ||
          selectedServiceCategoryId == service.categoryId;
      final matchesSearch =
          query.isEmpty || service.name.toLowerCase().contains(query);
      return matchesStatus && matchesCategory && matchesSearch;
    }).toList()
      ..sort((a, b) {
        final status = b.isActive.toString().compareTo(a.isActive.toString());
        if (status != 0) return status;
        return a.name.compareTo(b.name);
      });
  }

  List<ManagedCustomer> get filteredCustomers {
    final query = customerSearchQuery.trim().toLowerCase();
    return customers.where((customer) {
      final matchesStatus = switch (customerStatusFilter) {
        CustomerStatusFilter.all => true,
        CustomerStatusFilter.active => customer.isActive,
        CustomerStatusFilter.inactive => !customer.isActive,
        CustomerStatusFilter.recent => customer.isRecent,
      };
      final matchesSearch = query.isEmpty ||
          customer.name.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> signIn(String emailValue, String password) async {
    if (!GestaoSupabaseConfig.isConfigured) {
      errorMessage = 'Configure SUPABASE_URL e SUPABASE_ANON_KEY.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${GestaoSupabaseConfig.url}/auth/v1/token',
      ).replace(queryParameters: {'grant_type': 'password'});

      final response = await http.post(
        uri,
        headers: {
          'apikey': GestaoSupabaseConfig.anonKey,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'email': emailValue.trim(),
          'password': password,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Login inválido ou usuário sem acesso.');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken = data['access_token']?.toString();
      _refreshToken = data['refresh_token']?.toString();
      final user = data['user'];
      if (user is Map) _userId = user['id']?.toString();
      email = emailValue.trim();
      await _resolvePlatformAdmin(_accessToken!);
      await _ensureBarberShopId(_accessToken!);
      await _saveUnifiedSession(data);
      await refreshManagementData();
    } catch (error) {
      _accessToken = null;
      _refreshToken = null;
      errorMessage = _cleanErrorMessage(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshManagementData() async {
    await fetchBookingRequests();
    await fetchTeamBarbers();
    await fetchServiceCatalog();
    await fetchCustomers();
    await fetchShopConfiguration();
    await fetchScheduleEntries();
  }

  Future<void> fetchBookingRequests() async {
    final token = _accessToken;
    if (token == null) return;

    isBookingRequestsLoading = true;
    bookingRequestsError = null;
    notifyListeners();

    try {
      final rows = await _getRestRows(
        token,
        'booking_requests',
        query: {
          'select':
              'id,customer_name,customer_phone,requested_date,requested_time,status,total_price,notes,updated_at,barbers(name),services(name)',
          'order': 'created_at.desc',
          'limit': '20',
        },
      );
      bookingRequests = rows
          .map((row) => BookingRequest.fromMap(row))
          .toList();
      bookingRequestsError = null;
    } catch (error) {
      bookingRequestsError = _cleanErrorMessage(error);
    } finally {
      isBookingRequestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeamBarbers() async {
    final token = _accessToken;
    if (token == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final rows = await _getRestRows(
        token,
        'barbers',
        query: {
          'select':
              'id,barber_shop_id,user_id,name,bio,photo_url,starting_price,commission_percent,is_active',
          'barber_shop_id': 'eq.$shopId',
          'order': 'name.asc',
        },
      );

      teamBarbers = rows.map(TeamBarber.fromMap).toList();
      errorMessage = null;
    } catch (error) {
      errorMessage = _cleanErrorMessage(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setScheduleAdminView(bool value) async {
    if (scheduleAdminView == value) return;
    scheduleAdminView = value;
    if (!value) selectedScheduleBarberId = null;
    notifyListeners();
    await fetchScheduleEntries();
  }

  Future<void> selectScheduleDate(DateTime date) async {
    selectedScheduleDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
    await fetchScheduleEntries();
  }

  Future<void> selectScheduleBarber(String? barberId) async {
    selectedScheduleBarberId = barberId;
    notifyListeners();
    await fetchScheduleEntries();
  }

  Future<void> fetchScheduleEntries() async {
    final token = _accessToken;
    if (token == null) return;

    isScheduleLoading = true;
    scheduleError = null;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final barberId = scheduleAdminView
          ? selectedScheduleBarberId
          : currentBarber?.id ?? selectedScheduleBarberId;
      final date = _dateOnly(selectedScheduleDate);
      final start = DateTime(
        selectedScheduleDate.year,
        selectedScheduleDate.month,
        selectedScheduleDate.day,
      );
      final end = start.add(const Duration(days: 1));

      final requestQuery = <String, String>{
        'select':
            'id,customer_name,requested_date,requested_time,status,notes,barbers(name),services(name)',
        'barber_shop_id': 'eq.$shopId',
        'requested_date': 'eq.$date',
        'status': 'eq.converted',
        'appointment_id': 'is.null',
        'order': 'requested_time.asc',
      };
      if (barberId != null && barberId.isNotEmpty) {
        requestQuery['barber_id'] = 'eq.$barberId';
      }

      final appointmentQuery = <String, String>{
        'select': 'id,starts_at,status,notes,barbers(name),services(name)',
        'barber_shop_id': 'eq.$shopId',
        'starts_at': 'gte.${start.toIso8601String()}',
        'ends_at': 'lt.${end.toIso8601String()}',
        'order': 'starts_at.asc',
      };
      if (barberId != null && barberId.isNotEmpty) {
        appointmentQuery['barber_id'] = 'eq.$barberId';
      }

      final requests = await _getRestRows(
        token,
        'booking_requests',
        query: requestQuery,
      );
      final appointments = await _getRestRows(
        token,
        'appointments',
        query: appointmentQuery,
      );

      scheduleEntries = [
        ...requests.map(ScheduleEntry.fromBookingRequest),
        ...appointments.map(ScheduleEntry.fromAppointment),
      ]..sort((a, b) => a.time.compareTo(b.time));
      scheduleError = null;
    } catch (error) {
      scheduleError = _cleanErrorMessage(error);
    } finally {
      isScheduleLoading = false;
      notifyListeners();
    }
  }

  void setServiceStatusFilter(ServiceStatusFilter filter) {
    serviceStatusFilter = filter;
    notifyListeners();
  }

  void setServiceCategoryFilter(String? categoryId) {
    selectedServiceCategoryId = categoryId;
    notifyListeners();
  }

  void setServiceSearchQuery(String value) {
    serviceSearchQuery = value;
    notifyListeners();
  }

  void setCustomerStatusFilter(CustomerStatusFilter filter) {
    customerStatusFilter = filter;
    notifyListeners();
  }

  void setCustomerSearchQuery(String value) {
    customerSearchQuery = value;
    notifyListeners();
  }

  List<CustomerAppointment> appointmentsForCustomer(String clientId) {
    return customerAppointments
        .where((appointment) => appointment.clientId == clientId)
        .toList()
      ..sort((a, b) {
        final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
  }

  Future<void> fetchCustomers() async {
    final token = _accessToken;
    if (token == null) return;

    isCustomersLoading = true;
    customersError = null;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final rows = await _getRestRows(
        token,
        'management_clients',
        query: {
          'select':
              'relationship_id,barber_shop_id,client_id,first_seen_at,last_appointment_at,notes,is_blocked,email,user_is_active,full_name,phone,avatar_url,profile_created_at',
          'barber_shop_id': 'eq.$shopId',
          'order': 'full_name.asc',
        },
      );
      final appointmentRows = await _getRestRows(
        token,
        'management_client_appointments',
        query: {
          'select':
              'id,client_id,starts_at,status,notes,service_name,barber_name',
          'barber_shop_id': 'eq.$shopId',
          'order': 'starts_at.desc',
        },
      );
      final bookingRows = await _getRestRows(
        token,
        'booking_requests',
        query: {
          'select':
              'id,customer_name,customer_phone,requested_date,requested_time,status,notes,created_at,barbers(name),services(name)',
          'barber_shop_id': 'eq.$shopId',
          'order': 'created_at.desc',
        },
      );
      customerAppointments = [
        ...appointmentRows.map(CustomerAppointment.fromMap),
        ...bookingRows.map(CustomerAppointment.fromBookingRequest),
      ];

      final appointmentCounts = <String, int>{};
      final barberCounts = <String, Map<String, int>>{};
      final lastAppointments = <String, DateTime>{};
      for (final appointment in customerAppointments) {
        appointmentCounts[appointment.clientId] =
            (appointmentCounts[appointment.clientId] ?? 0) + 1;
        final byBarber =
            barberCounts.putIfAbsent(appointment.clientId, () => {});
        byBarber[appointment.barber] = (byBarber[appointment.barber] ?? 0) + 1;
        final date = appointment.date;
        if (date != null) {
          final current = lastAppointments[appointment.clientId];
          if (current == null || date.isAfter(current)) {
            lastAppointments[appointment.clientId] = date;
          }
        }
      }

      final relationshipCustomers = rows
          .map((row) {
            final clientId = row['client_id']?.toString() ?? '';
            final favoriteBarber = _favoriteBarber(barberCounts[clientId]);
            return ManagedCustomer.fromMap(
              row,
              appointmentCount: appointmentCounts[clientId] ?? 0,
              favoriteBarber: favoriteBarber,
              computedLastAppointmentAt: lastAppointments[clientId],
            );
          })
          .where((customer) => customer.clientId.isNotEmpty)
          .toList();

      final relationshipPhones = relationshipCustomers
          .map((customer) => ManagedCustomer._digitsOnly(customer.phone))
          .where((phone) => phone.isNotEmpty)
          .toSet();
      final bookingCustomersByPhone = <String, ManagedCustomer>{};
      for (final row in bookingRows) {
        final phone = ManagedCustomer._digitsOnly(
          row['customer_phone']?.toString() ?? '',
        );
        if (phone.isEmpty || relationshipPhones.contains(phone)) continue;
        final clientId = 'booking:$phone';
        final existing = bookingCustomersByPhone[phone];
        final favoriteBarber = _favoriteBarber(barberCounts[clientId]);
        final next = ManagedCustomer.fromBookingRequest(
          row,
          appointmentCount: appointmentCounts[clientId] ?? 0,
          favoriteBarber: favoriteBarber,
          computedLastAppointmentAt: lastAppointments[clientId],
        );
        if (existing == null ||
            (next.lastAppointmentAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .isAfter(existing.lastAppointmentAt ??
                    DateTime.fromMillisecondsSinceEpoch(0))) {
          bookingCustomersByPhone[phone] = next;
        }
      }

      customers = [
        ...relationshipCustomers,
        ...bookingCustomersByPhone.values,
      ];
      customersError = null;
    } catch (error) {
      customersError = _cleanErrorMessage(error);
    } finally {
      isCustomersLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCustomer(
    ManagedCustomer customer, {
    required String name,
    required String phone,
    required String notes,
    required bool isActive,
  }) async {
    final token = _accessToken;
    if (token == null) return;

    isCustomersLoading = true;
    customersError = null;
    notifyListeners();

    try {
      await _patchRestRows(
        token,
        'profiles',
        query: {'user_id': 'eq.${customer.clientId}'},
        data: {
          'full_name': name.trim(),
          'phone': phone.trim().isEmpty ? null : phone.trim(),
        },
      );
      await _patchRestRows(
        token,
        'client_shop_relationships',
        query: {'id': 'eq.${customer.relationshipId}'},
        data: {
          'notes': notes.trim().isEmpty ? null : notes.trim(),
          'is_blocked': !isActive,
        },
      );

      customers = [
        for (final item in customers)
          if (item.clientId == customer.clientId)
            item.copyWith(
              name: name.trim(),
              phone: phone.trim(),
              notes: notes.trim(),
              isBlocked: !isActive,
            )
          else
            item,
      ];
      customersError = null;
    } catch (error) {
      customersError = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isCustomersLoading = false;
      notifyListeners();
    }
  }

  String _favoriteBarber(Map<String, int>? counts) {
    if (counts == null || counts.isEmpty) return 'Não definido';
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  Future<void> fetchShopConfiguration() async {
    final token = _accessToken;
    if (token == null) return;

    isSettingsLoading = true;
    settingsError = null;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final shops = await _getRestRows(
        token,
        'barber_shops',
        query: {
          'select':
              'id,name,document,phone,whatsapp,address,city,state,logo_url,cover_url,opening_time,closing_time',
          'id': 'eq.$shopId',
          'limit': '1',
        },
      );
      if (shops.isEmpty) {
        throw StateError('Barbearia não encontrada.');
      }

      final settingsRows = await _getRestRows(
        token,
        'shop_settings',
        query: {
          'select': 'id,booking_interval_minutes,min_cancel_hours,settings',
          'barber_shop_id': 'eq.$shopId',
          'limit': '1',
        },
      );

      shopConfiguration = ShopConfiguration.fromRows(
        shop: shops.first,
        settings: settingsRows.isEmpty ? null : settingsRows.first,
      );
      barberShopName = shopConfiguration?.name;
      settingsError = null;
    } catch (error) {
      settingsError = _cleanErrorMessage(error);
    } finally {
      isSettingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveShopConfiguration(ShopConfiguration config) async {
    final token = _accessToken;
    if (token == null) return;

    isSettingsLoading = true;
    settingsError = null;
    notifyListeners();

    try {
      await _patchRestRows(
        token,
        'barber_shops',
        query: {'id': 'eq.${config.shopId}'},
        data: {
          'name': config.name.trim(),
          'document':
              config.document.trim().isEmpty ? null : config.document.trim(),
          'phone': config.phone.trim().isEmpty ? null : config.phone.trim(),
          'whatsapp':
              config.whatsapp.trim().isEmpty ? null : config.whatsapp.trim(),
          'address':
              config.address.trim().isEmpty ? null : config.address.trim(),
          'city': config.city.trim().isEmpty ? null : config.city.trim(),
          'state': config.state.trim().isEmpty ? null : config.state.trim(),
          'logo_url':
              config.logoUrl.trim().isEmpty ? null : config.logoUrl.trim(),
          'cover_url':
              config.coverUrl.trim().isEmpty ? null : config.coverUrl.trim(),
          'opening_time': _firstOpenTime(config.days),
          'closing_time': _lastCloseTime(config.days),
        },
      );

      final settingsData = {
        'barber_shop_id': config.shopId,
        'booking_interval_minutes': config.bookingIntervalMinutes,
        'min_cancel_hours': config.minCancelHours,
        'settings': config.settingsJson(),
      };
      if (config.settingsId.isEmpty) {
        await _postRestRows(token, 'shop_settings', data: settingsData);
      } else {
        await _patchRestRows(
          token,
          'shop_settings',
          query: {'id': 'eq.${config.settingsId}'},
          data: settingsData,
        );
      }

      shopConfiguration = config;
      barberShopName = config.name;
      settingsError = null;
    } catch (error) {
      settingsError = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isSettingsLoading = false;
      notifyListeners();
    }
  }

  Future<String> uploadShopMedia(LogoFile file,
      {required String folder}) async {
    final token = _accessToken;
    if (token == null) return '';

    final shopId = await _ensureBarberShopId(token);
    final safeFolder = folder
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    final safeName = file.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    final objectPath =
        '$shopId/$safeFolder/${DateTime.now().millisecondsSinceEpoch}-$safeName';
    final uri = Uri.parse(
      '${GestaoSupabaseConfig.url}/storage/v1/object/shop-media/$objectPath',
    );

    final response = await http.post(
      uri,
      headers: {
        'apikey': GestaoSupabaseConfig.anonKey,
        'authorization': 'Bearer $token',
        'content-type': file.contentType,
        'x-upsert': 'true',
      },
      body: file.bytes,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Supabase Storage ${response.statusCode}: ${response.body}');
    }

    return '${GestaoSupabaseConfig.url}/storage/v1/object/public/shop-media/$objectPath';
  }

  String? _firstOpenTime(List<ShopBusinessDay> days) {
    for (final day in days) {
      if (day.isOpen) return day.openTime;
    }
    return null;
  }

  String? _lastCloseTime(List<ShopBusinessDay> days) {
    for (final day in days.reversed) {
      if (day.isOpen) return day.closeTime;
    }
    return null;
  }

  Future<void> fetchServiceCatalog() async {
    final token = _accessToken;
    if (token == null) return;

    isServicesLoading = true;
    servicesError = null;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final categories = await _getRestRows(
        token,
        'service_categories',
        query: {
          'select': 'id,name,is_active,sort_order',
          'barber_shop_id': 'eq.$shopId',
          'order': 'sort_order.asc,name.asc',
        },
      );
      serviceCategories = categories
          .map(ServiceCategory.fromMap)
          .where((category) => category.id.isNotEmpty)
          .toList();

      final appointmentRows = await _getRestRows(
        token,
        'appointments',
        query: {
          'select': 'service_id',
          'barber_shop_id': 'eq.$shopId',
        },
      );
      final bookingRequestRows = await _getRestRows(
        token,
        'booking_requests',
        query: {
          'select': 'service_id',
          'barber_shop_id': 'eq.$shopId',
        },
      );
      final serviceUsageCounts = <String, int>{};
      for (final row in [...appointmentRows, ...bookingRequestRows]) {
        final id = row['service_id']?.toString();
        if (id == null || id.isEmpty) continue;
        serviceUsageCounts[id] = (serviceUsageCounts[id] ?? 0) + 1;
      }

      final rows = await _getRestRows(
        token,
        'services',
        query: {
          'select':
              'id,category_id,name,description,duration_minutes,price,image_url,is_active,service_categories(name)',
          'barber_shop_id': 'eq.$shopId',
          'order': 'name.asc',
        },
      );
      services = rows
          .map(
            (row) => ManagedService.fromMap(
              row,
              appointmentCount: serviceUsageCounts[row['id']?.toString()] ?? 0,
            ),
          )
          .where((service) => service.id.isNotEmpty)
          .toList();
      servicesError = null;
    } catch (error) {
      servicesError = _cleanErrorMessage(error);
    } finally {
      isServicesLoading = false;
      notifyListeners();
    }
  }

  Future<void> createService({
    required String name,
    required String description,
    required String? categoryId,
    required double price,
    required int durationMinutes,
    required String imageUrl,
    required bool isActive,
  }) async {
    final token = _accessToken;
    if (token == null) return;

    isServicesLoading = true;
    servicesError = null;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      await _postRestRows(
        token,
        'services',
        data: {
          'barber_shop_id': shopId,
          'category_id':
              categoryId == null || categoryId.isEmpty ? null : categoryId,
          'name': name.trim(),
          'description': description.trim().isEmpty ? null : description.trim(),
          'duration_minutes': durationMinutes,
          'price': price,
          'image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
          'is_active': isActive,
        },
      );

      await fetchServiceCatalog();
    } catch (error) {
      servicesError = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isServicesLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateService(
    ManagedService service, {
    required String name,
    required String description,
    required String? categoryId,
    required double price,
    required int durationMinutes,
    required String imageUrl,
    required bool isActive,
  }) async {
    final token = _accessToken;
    if (token == null) return;

    isServicesLoading = true;
    servicesError = null;
    notifyListeners();

    try {
      await _patchRestRows(
        token,
        'services',
        query: {'id': 'eq.${service.id}'},
        data: {
          'category_id':
              categoryId == null || categoryId.isEmpty ? null : categoryId,
          'name': name.trim(),
          'description': description.trim().isEmpty ? null : description.trim(),
          'duration_minutes': durationMinutes,
          'price': price,
          'image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
          'is_active': isActive,
        },
      );

      await fetchServiceCatalog();
    } catch (error) {
      servicesError = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isServicesLoading = false;
      notifyListeners();
    }
  }

  Future<void> deactivateService(ManagedService service) async {
    await updateService(
      service,
      name: service.name,
      description: service.description,
      categoryId: service.categoryId,
      price: service.price,
      durationMinutes: service.durationMinutes,
      imageUrl: service.imageUrl,
      isActive: false,
    );
  }

  Future<void> deleteOrDeactivateService(ManagedService service) async {
    if (service.appointmentCount > 0) {
      await deactivateService(service);
      return;
    }

    final token = _accessToken;
    if (token == null) return;

    isServicesLoading = true;
    servicesError = null;
    notifyListeners();

    try {
      await _deleteRestRows(
        token,
        'services',
        query: {'id': 'eq.${service.id}'},
      );
      services = [
        for (final item in services)
          if (item.id != service.id) item,
      ];
      await fetchServiceCatalog();
    } catch (error) {
      servicesError = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isServicesLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTeamBarber({
    required String name,
    required String bio,
    required String photoUrl,
    required double startingPrice,
    required double commissionPercent,
  }) async {
    final token = _accessToken;
    if (token == null) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final rows = await _postRestRows(
        token,
        'barbers',
        data: {
          'barber_shop_id': shopId,
          'name': name.trim(),
          'bio': bio.trim().isEmpty ? null : bio.trim(),
          'photo_url': photoUrl.trim().isEmpty ? null : photoUrl.trim(),
          'starting_price': startingPrice,
          'commission_percent': commissionPercent,
          'is_active': true,
        },
      );

      final created = rows.isEmpty ? null : TeamBarber.fromMap(rows.first);
      if (created != null) {
        teamBarbers = [...teamBarbers, created]
          ..sort((a, b) => a.name.compareTo(b.name));
      } else {
        await fetchTeamBarbers();
      }
    } catch (error) {
      errorMessage = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTeamBarber(
    TeamBarber barber, {
    required String name,
    required String bio,
    required String photoUrl,
    required double startingPrice,
    required double commissionPercent,
    required bool isActive,
  }) async {
    final token = _accessToken;
    if (token == null) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final rows = await _patchRestRows(
        token,
        'barbers',
        query: {'id': 'eq.${barber.id}'},
        data: {
          'name': name.trim(),
          'bio': bio.trim().isEmpty ? null : bio.trim(),
          'photo_url': photoUrl.trim().isEmpty ? null : photoUrl.trim(),
          'starting_price': startingPrice,
          'commission_percent': commissionPercent,
          'is_active': isActive,
        },
      );

      final updated = rows.isEmpty ? null : TeamBarber.fromMap(rows.first);
      if (updated != null) {
        teamBarbers = [
          for (final item in teamBarbers)
            if (item.id == updated.id) updated else item,
        ]..sort((a, b) => a.name.compareTo(b.name));
      } else {
        await fetchTeamBarbers();
      }
    } catch (error) {
      errorMessage = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deactivateTeamBarber(TeamBarber barber) async {
    await updateTeamBarber(
      barber,
      name: barber.name,
      bio: barber.bio,
      photoUrl: barber.photoUrl,
      startingPrice: barber.startingPrice,
      commissionPercent: barber.commissionPercent,
      isActive: false,
    );
  }

  Future<void> updateBookingRequestStatus(
    String id,
    String status, {
    String? reason,
  }) async {
    final token = _accessToken;
    if (token == null) return;

    isBookingRequestsLoading = true;
    bookingRequestActionError = null;
    notifyListeners();

    try {
      if (status == 'converted') {
        await _postRpc(
          token,
          'accept_booking_request',
          data: {'p_request_id': id},
        );
        await fetchBookingRequests();
        await fetchScheduleEntries();
        return;
      }
      final current = _bookingRequestById(id);
      final updatedAt = DateTime.now().toUtc().toIso8601String();
      final nextNotes = _notesWithReason(current?.notes ?? '', reason);
      final rows = await _patchRestRows(
        token,
        'booking_requests',
        query: {'id': 'eq.$id'},
        data: {
          'status': status,
          'updated_at': updatedAt,
          if (reason != null && reason.trim().isNotEmpty) 'notes': nextNotes,
        },
      );

      final updated = rows.isEmpty ? null : BookingRequest.fromMap(rows.first);
      bookingRequests = [
        for (final request in bookingRequests)
          if (request.id == id)
            updated ??
                request.copyWith(
                  status: status,
                  notes: nextNotes,
                  updatedAt: updatedAt,
                )
          else
            request,
      ];
      bookingRequestActionError = null;
      await fetchScheduleEntries();
    } catch (error) {
      final cleanMessage = _cleanErrorMessage(error);
      bookingRequestActionError = cleanMessage;
      throw StateError(cleanMessage);
    } finally {
      isBookingRequestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeAppointment(String appointmentId) async {
    final token = _accessToken;
    if (token == null || appointmentId.isEmpty) return;
    isScheduleLoading = true;
    scheduleError = null;
    notifyListeners();
    try {
      await _postRpc(
        token,
        'complete_appointment',
        data: {'p_appointment_id': appointmentId},
      );
      await fetchScheduleEntries();
    } catch (error) {
      scheduleError = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isScheduleLoading = false;
      notifyListeners();
    }
  }

  void signOut() {
    SharedPreferences.getInstance().then(
      (prefs) => prefs.remove(_unifiedSessionKey),
    );
    _clearSessionInMemory();
    notifyListeners();
  }

  void _clearSessionInMemory() {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _barberShopId = null;
    _isPlatformAdmin = false;
    barberShopName = null;
    email = null;
    bookingRequests = [];
    bookingRequestsError = null;
    isBookingRequestsLoading = false;
    scheduleEntries = [];
    scheduleError = null;
    isScheduleLoading = false;
    selectedScheduleBarberId = null;
    scheduleAdminView = false;
    services = [];
    serviceCategories = [];
    servicesError = null;
    isServicesLoading = false;
    serviceStatusFilter = ServiceStatusFilter.all;
    selectedServiceCategoryId = null;
    serviceSearchQuery = '';
    customers = [];
    customerAppointments = [];
    customersError = null;
    isCustomersLoading = false;
    customerStatusFilter = CustomerStatusFilter.all;
    customerSearchQuery = '';
    shopConfiguration = null;
    settingsError = null;
    isSettingsLoading = false;
    teamBarbers = [];
    errorMessage = null;
  }

  Future<void> _saveUnifiedSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unifiedSessionKey, jsonEncode(data));
  }

  BookingRequest? _bookingRequestById(String id) {
    for (final request in bookingRequests) {
      if (request.id == id) return request;
    }
    return null;
  }

  Future<String> _ensureBarberShopId(String token) async {
    if (_barberShopId != null) return _barberShopId!;
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      throw StateError('Usuário sem identificação válida.');
    }

    final memberships = await _getRestRows(
      token,
      'shop_members',
      query: {
        'select': 'barber_shop_id,barber_shops(name)',
        'user_id': 'eq.$userId',
        'is_active': 'eq.true',
        'order': 'created_at.asc',
        'limit': '1',
      },
    );

    if (memberships.isNotEmpty) {
      final membership = memberships.first;
      _barberShopId = membership['barber_shop_id']?.toString();
      final shop = membership['barber_shops'];
      if (shop is Map) barberShopName = shop['name']?.toString();
      if (_barberShopId != null && _barberShopId!.isNotEmpty) {
        return _barberShopId!;
      }
    }

    final shops = await _getRestRows(
      token,
      'barber_shops',
      query: {
        'select': 'id,name',
        if (!_isPlatformAdmin) 'owner_id': 'eq.$userId',
        'order': 'name.asc',
        'limit': '1',
      },
    );

    if (shops.isEmpty) {
      throw StateError('Nenhuma barbearia disponível para este usuário.');
    }

    final shop = shops.first;
    _barberShopId = shop['id']?.toString();
    barberShopName = shop['name']?.toString();
    if (_barberShopId == null || _barberShopId!.isEmpty) {
      throw StateError('Barbearia sem identificador válido.');
    }

    return _barberShopId!;
  }

  Future<void> _resolvePlatformAdmin(String token) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    final rows = await _getRestRows(
      token,
      'users',
      query: {
        'select': 'role',
        'id': 'eq.$userId',
        'limit': '1',
      },
    );
    _isPlatformAdmin =
        rows.isNotEmpty && rows.first['role']?.toString() == 'admin';
  }

  Future<List<Map<String, dynamic>>> _getRestRows(
    String token,
    String table, {
    required Map<String, String> query,
  }) async {
    final uri = Uri.parse('${GestaoSupabaseConfig.url}/rest/v1/$table')
        .replace(queryParameters: query);

    final response = await _requestWithRefresh(
      token,
      (accessToken) => http.get(uri, headers: _restHeaders(accessToken)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Supabase REST ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _postRestRows(
    String token,
    String table, {
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse('${GestaoSupabaseConfig.url}/rest/v1/$table');

    final response = await _requestWithRefresh(
      token,
      (accessToken) => http.post(
        uri,
        headers: _restHeaders(accessToken, preferRepresentation: true),
        body: jsonEncode(data),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Supabase REST ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _patchRestRows(
    String token,
    String table, {
    required Map<String, String> query,
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse('${GestaoSupabaseConfig.url}/rest/v1/$table')
        .replace(queryParameters: query);

    final response = await _requestWithRefresh(
      token,
      (accessToken) => http.patch(
        uri,
        headers: _restHeaders(accessToken, preferRepresentation: true),
        body: jsonEncode(data),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Supabase REST ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<dynamic> _postRpc(
    String token,
    String functionName, {
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse(
      '${GestaoSupabaseConfig.url}/rest/v1/rpc/$functionName',
    );
    final response = await _requestWithRefresh(
      token,
      (accessToken) => http.post(
        uri,
        headers: _restHeaders(accessToken),
        body: jsonEncode(data),
      ),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Supabase RPC ${response.statusCode}: ${response.body}',
      );
    }
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<void> _deleteRestRows(
    String token,
    String table, {
    required Map<String, String> query,
  }) async {
    final uri = Uri.parse('${GestaoSupabaseConfig.url}/rest/v1/$table')
        .replace(queryParameters: query);

    final response = await _requestWithRefresh(
      token,
      (accessToken) => http.delete(uri, headers: _restHeaders(accessToken)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Supabase REST ${response.statusCode}: ${response.body}');
    }
  }

  Future<http.Response> _requestWithRefresh(
    String token,
    Future<http.Response> Function(String accessToken) request,
  ) async {
    var response = await request(token);
    if (response.statusCode != 401) return response;
    final refreshedToken = await _refreshAccessToken();
    if (refreshedToken == null || refreshedToken.isEmpty) return response;
    response = await request(refreshedToken);
    return response;
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;
    final uri = Uri.parse(
      '${GestaoSupabaseConfig.url}/auth/v1/token',
    ).replace(queryParameters: {'grant_type': 'refresh_token'});
    final response = await http.post(
      uri,
      headers: {
        'apikey': GestaoSupabaseConfig.anonKey,
        'content-type': 'application/json',
      },
      body: jsonEncode({'refresh_token': refreshToken}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = data['access_token']?.toString();
    _refreshToken = data['refresh_token']?.toString() ?? refreshToken;
    await _saveUnifiedSession(data);
    return _accessToken;
  }

  Map<String, String> _restHeaders(
    String token, {
    bool preferRepresentation = false,
  }) {
    return {
      'apikey': GestaoSupabaseConfig.anonKey,
      'authorization': 'Bearer $token',
      'content-type': 'application/json',
      if (preferRepresentation) 'prefer': 'return=representation',
    };
  }

  String _cleanErrorMessage(Object error) {
    final message = error
        .toString()
        .replaceFirst(RegExp(r'^\s*Bad state:\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^\s*Exception:\s*', caseSensitive: false), '');

    if (message.contains('Failed to fetch') ||
        message.contains('XMLHttpRequest') ||
        message.contains('SocketException') ||
        message.contains('ClientException')) {
      return 'Sem internet ou Supabase indisponível. Verifique sua conexão.';
    }

    if (message.contains('management_clients') ||
        message.contains('management_client_appointments') ||
        message.contains('PGRST205')) {
      return 'Execute o script supabase/issue_006_customer_management.sql no Supabase e atualize a tela. Ele cria as views necessarias para listar clientes.';
    }

    if ((message.contains('409') || message.contains('23505')) &&
        (message.contains('appointments_barber_id_starts_at_key') ||
            message.contains('duplicate key value'))) {
      return 'Este horário já possui um atendimento na agenda. Recuse ou cancele esta solicitação e oriente o cliente a escolher outro horário.';
    }

    if (message.toLowerCase().contains('horario escolhido ja esta ocupado') ||
        message.toLowerCase().contains('horário escolhido já está ocupado')) {
      return 'Este horário já possui um atendimento na agenda. Recuse ou cancele esta solicitação e oriente o cliente a escolher outro horário.';
    }

    return switch (message) {
      'Login invalido ou usuario sem acesso.' =>
        'Login inválido ou usuário sem acesso.',
      'Login inválido ou usuário sem acesso.' =>
        'Login inválido ou usuário sem acesso.',
      'Nao foi possivel carregar pedidos.' =>
        'Não foi possível carregar os pedidos.',
      'Não foi possível carregar os pedidos.' =>
        'Não foi possível carregar os pedidos.',
      'Nao foi possivel atualizar o pedido.' =>
        'Não foi possível atualizar o pedido.',
      'Não foi possível atualizar o pedido.' =>
        'Não foi possível atualizar o pedido.',
      _ => message,
    };
  }

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _notesWithReason(String notes, String? reason) {
    final cleanReason = reason?.trim();
    if (cleanReason == null || cleanReason.isEmpty) return notes;

    final reasonLine = 'Motivo: $cleanReason';
    if (notes.trim().isEmpty) return reasonLine;
    if (notes.contains(reasonLine)) return notes;
    return '${notes.trim()}\n$reasonLine';
  }
}

class ManagementLoginScreen extends StatefulWidget {
  const ManagementLoginScreen({super.key});

  @override
  State<ManagementLoginScreen> createState() => _ManagementLoginScreenState();
}

class _ManagementLoginScreenState extends State<ManagementLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ManagementSession>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/brand_v3_logo_principal.svg',
                      width: 210,
                      height: 156,
                      fit: BoxFit.contain,
                      semanticsLabel: 'Clube da Régua',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: SharedAppColors.orange.withOpacity(.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: SharedAppColors.orange.withOpacity(.45),
                        ),
                      ),
                      child: const Text(
                        'PORTAL DE GESTÃO',
                        style: TextStyle(
                          color: SharedAppColors.orange,
                          fontSize: 11,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Entre para ver pedidos, agenda e operação da barbearia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SharedAppColors.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                      prefixIconColor: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      prefixIconColor: Colors.white70,
                      suffixIcon: TextButton(
                        onPressed: () => setState(
                          () => _showPassword = !_showPassword,
                        ),
                        child: Text(_showPassword ? 'Ocultar' : 'Mostrar'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: session.isLoading
                        ? null
                        : () => session.signIn(
                              _emailController.text,
                              _passwordController.text,
                            ),
                    style: FilledButton.styleFrom(
                      backgroundColor: SharedAppColors.orange,
                      foregroundColor: SharedAppColors.onGold,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: Text(session.isLoading ? 'Entrando...' : 'Entrar'),
                  ),
                  if (session.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      session.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key, required this.session});

  final PasswordRecoverySession session;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _showPassword = false;
  var _showConfirmPassword = false;
  var _isLoading = false;
  var _isDone = false;
  var _showLogin = false;
  String? _message;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.length < 6) {
      setState(() => _message = 'A senha precisa ter pelo menos 6 caracteres.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _message = 'As senhas digitadas não conferem.');
      return;
    }

    if (!GestaoSupabaseConfig.isConfigured) {
      setState(() => _message = 'Configure SUPABASE_URL e SUPABASE_ANON_KEY.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await _sendPasswordUpdate(
        accessToken: widget.session.accessToken,
        password: password,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final refreshedAccessToken = await _refreshRecoverySession();
        if (refreshedAccessToken == null) {
          throw StateError(_supabaseErrorMessage(response));
        }

        final retryResponse = await _sendPasswordUpdate(
          accessToken: refreshedAccessToken,
          password: password,
        );

        if (retryResponse.statusCode < 200 || retryResponse.statusCode >= 300) {
          throw StateError(_supabaseErrorMessage(retryResponse));
        }
      }

      setState(() {
        _isDone = true;
        _message = 'Senha redefinida com sucesso.';
      });
    } catch (error) {
      setState(() => _message = _cleanErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _cleanErrorMessage(Object error) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^\s*Bad state:\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^\s*Exception:\s*', caseSensitive: false), '');
  }

  Future<http.Response> _sendPasswordUpdate({
    required String accessToken,
    required String password,
  }) {
    return http.put(
      Uri.parse('${GestaoSupabaseConfig.url}/auth/v1/user'),
      headers: {
        'apikey': GestaoSupabaseConfig.anonKey,
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
      },
      body: jsonEncode({'password': password}),
    );
  }

  Future<String?> _refreshRecoverySession() async {
    final refreshToken = widget.session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final response = await http.post(
      Uri.parse('${GestaoSupabaseConfig.url}/auth/v1/token').replace(
        queryParameters: {'grant_type': 'refresh_token'},
      ),
      headers: {
        'apikey': GestaoSupabaseConfig.anonKey,
        'content-type': 'application/json',
      },
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['access_token']?.toString();
  }

  String _supabaseErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message =
          body['msg'] ?? body['message'] ?? body['error_description'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    } catch (_) {
      // Keep the fallback below when Supabase returns an empty or non-JSON body.
    }

    return 'Não foi possível redefinir a senha. Gere um novo link e tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return const ManagementLoginScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    _isDone
                        ? Icons.check_circle_rounded
                        : Icons.lock_reset_rounded,
                    color: _isDone
                        ? Colors.green.shade700
                        : SharedAppColors.orange,
                    size: 58,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _isDone ? 'Senha redefinida' : 'Redefinir senha',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isDone
                        ? 'Agora você já pode entrar com sua nova senha.'
                        : 'Digite sua nova senha para acessar a gestão.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: SharedAppColors.muted),
                  ),
                  const SizedBox(height: 28),
                  if (!_isDone) ...[
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Nova senha',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: TextButton(
                          onPressed: () => setState(
                            () => _showPassword = !_showPassword,
                          ),
                          child: Text(_showPassword ? 'Ocultar' : 'Mostrar'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmar nova senha',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: TextButton(
                          onPressed: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                          child: Text(
                            _showConfirmPassword ? 'Ocultar' : 'Mostrar',
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _isLoading
                        ? null
                        : _isDone
                            ? () => setState(() => _showLogin = true)
                            : _updatePassword,
                    style: FilledButton.styleFrom(
                      backgroundColor: SharedAppColors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: Text(
                      _isLoading
                          ? 'Salvando...'
                          : _isDone
                              ? 'Entrar'
                              : 'Salvar senha',
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isDone ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ManagementRole { barber, admin }

class ManagementHomeScreen extends StatefulWidget {
  const ManagementHomeScreen({super.key});

  @override
  State<ManagementHomeScreen> createState() => _ManagementHomeScreenState();
}

class _ManagementHomeScreenState extends State<ManagementHomeScreen> {
  var selectedRole = ManagementRole.barber;
  var selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = selectedRole == ManagementRole.admin;
    final tabs = isAdmin ? _adminTabs : _barberTabs;
    final safeTab = selectedTab >= tabs.length ? 0 : selectedTab;
    final page = tabs[safeTab];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSideNavigation = constraints.maxWidth >= 900;
        final extendedNavigation = constraints.maxWidth >= 1280;
        return Scaffold(
          appBar: _ManagementTopBar(title: page.title),
          bottomNavigationBar: useSideNavigation
              ? null
              : _ManagementBottomNavigation(
                  tabs: tabs,
                  selectedIndex: safeTab,
                  onSelected: _selectTab,
                ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (useSideNavigation)
                _ManagementSideNavigation(
                  tabs: tabs,
                  selectedIndex: safeTab,
                  extended: extendedNavigation,
                  onSelected: _selectTab,
                ),
              Expanded(
                child: _ManagementPageContent(
                  horizontalPadding: useSideNavigation ? 32 : 18,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _RoleSwitch(
                        selectedRole: selectedRole,
                        onChanged: (role) {
                          setState(() {
                            selectedRole = role;
                            selectedTab = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Consumer<ManagementSession>(
                      builder: (context, session, _) => _Header(
                        isAdmin: isAdmin,
                        title: isAdmin
                            ? session.barberShopName ?? 'Barbearia'
                            : session.barberHeaderName,
                      ),
                    ),
                    const SizedBox(height: 28),
                    page.child,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectTab(int index) => setState(() => selectedTab = index);
}

class _ManagementTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _ManagementTopBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return AppBar(
      toolbarHeight: 72,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SharedAppColors.orange.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SharedAppColors.orange.withOpacity(.5)),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: SharedAppColors.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CLUBE DA RÉGUA · GESTÃO',
                  style: TextStyle(
                    color: SharedAppColors.orange,
                    fontFamily: 'Inter',
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notificações',
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        if (compact)
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'client':
                  openClientMode();
                  return;
                case 'refresh':
                  context.read<ManagementSession>().refreshManagementData();
                  return;
                case 'logout':
                  context.read<ManagementSession>().signOut();
                  return;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'client', child: Text('Modo cliente')),
              PopupMenuItem(value: 'refresh', child: Text('Atualizar dados')),
              PopupMenuItem(value: 'logout', child: Text('Sair')),
            ],
          )
        else ...[
          IconButton(
            tooltip: 'Modo cliente',
            onPressed: openClientMode,
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () =>
                context.read<ManagementSession>().refreshManagementData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: () => context.read<ManagementSession>().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
        const SizedBox(width: 10),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: SharedAppColors.stroke),
      ),
    );
  }
}

class _ManagementPageContent extends StatelessWidget {
  const _ManagementPageContent({
    required this.children,
    required this.horizontalPadding,
  });

  final List<Widget> children;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) => ListView(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      );
}

class _ManagementSideNavigation extends StatelessWidget {
  const _ManagementSideNavigation({
    required this.tabs,
    required this.selectedIndex,
    required this.extended,
    required this.onSelected,
  });

  final List<_ManagementTab> tabs;
  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => NavigationRail(
        selectedIndex: selectedIndex,
        extended: extended,
        minWidth: 82,
        minExtendedWidth: 220,
        backgroundColor: SharedAppColors.card,
        indicatorColor: SharedAppColors.orange,
        selectedIconTheme: const IconThemeData(color: SharedAppColors.onGold),
        unselectedIconTheme: const IconThemeData(color: SharedAppColors.muted),
        selectedLabelTextStyle: const TextStyle(
          color: SharedAppColors.text,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: const TextStyle(color: SharedAppColors.muted),
        onDestinationSelected: onSelected,
        destinations: [
          for (final tab in tabs)
            NavigationRailDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: Text(tab.label),
            ),
        ],
      );
}

class _ManagementBottomNavigation extends StatelessWidget {
  const _ManagementBottomNavigation({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_ManagementTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      );
}

class _ManagementTab {
  const _ManagementTab({
    required this.label,
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.child,
  });

  final String label;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget child;
}

const _barberTabs = [
  _ManagementTab(
    label: 'Pedidos',
    title: 'Solicitações recebidas',
    icon: Icons.inbox_outlined,
    selectedIcon: Icons.inbox_rounded,
    child: _BookingRequestsPage(),
  ),
  _ManagementTab(
    label: 'Agenda',
    title: 'Agenda do barbeiro',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    child: _BarberAgendaPage(),
  ),
  _ManagementTab(
    label: 'Horários',
    title: 'Disponibilidade',
    icon: Icons.schedule_outlined,
    selectedIcon: Icons.schedule_rounded,
    child: _AvailabilityPage(),
  ),
  _ManagementTab(
    label: 'Clientes',
    title: 'Clientes atendidos',
    icon: Icons.people_alt_outlined,
    selectedIcon: Icons.people_alt_rounded,
    child: _ClientsPage(),
  ),
  _ManagementTab(
    label: 'Comissão',
    title: 'Comissão e faturamento',
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments_rounded,
    child: _CommissionPage(),
  ),
];

const _adminTabs = [
  _ManagementTab(
    label: 'Pedidos',
    title: 'Solicitações recebidas',
    icon: Icons.inbox_outlined,
    selectedIcon: Icons.inbox_rounded,
    child: _BookingRequestsPage(),
  ),
  _ManagementTab(
    label: 'Painel',
    title: 'Painel administrativo',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    child: _AdminDashboardPage(),
  ),
  _ManagementTab(
    label: 'Agenda',
    title: 'Agenda por barbeiro',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    child: _BarberAgendaPage(adminView: true),
  ),
  _ManagementTab(
    label: 'Serviços',
    title: 'Cadastro de serviços',
    icon: Icons.design_services_outlined,
    selectedIcon: Icons.design_services_rounded,
    child: _ServicesPage(),
  ),
  _ManagementTab(
    label: 'Equipe',
    title: 'Cadastro de barbeiros',
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge_rounded,
    child: _TeamPage(),
  ),
  _ManagementTab(
    label: 'Caixa',
    title: 'Caixa e estoque',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale_rounded,
    child: _CashPage(),
  ),
  _ManagementTab(
    label: 'Config',
    title: 'Configuração da barbearia',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    child: _SettingsPage(),
  ),
];

class _RoleSwitch extends StatelessWidget {
  const _RoleSwitch({
    required this.selectedRole,
    required this.onChanged,
  });

  final ManagementRole selectedRole;
  final ValueChanged<ManagementRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ManagementRole>(
      segments: const [
        ButtonSegment(
          value: ManagementRole.barber,
          label: Text('Barbeiro'),
          icon: Icon(Icons.content_cut_rounded),
        ),
        ButtonSegment(
          value: ManagementRole.admin,
          label: Text('Admin'),
          icon: Icon(Icons.admin_panel_settings_rounded),
        ),
      ],
      selected: {selectedRole},
      onSelectionChanged: (value) => onChanged(value.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? SharedAppColors.orange
              : SharedAppColors.card,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? SharedAppColors.onGold
              : SharedAppColors.muted,
        ),
        side: WidgetStateProperty.all(
          const BorderSide(color: SharedAppColors.stroke),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isAdmin,
    required this.title,
  });

  final bool isAdmin;
  final String title;

  @override
  Widget build(BuildContext context) {
    final logoUrl =
        context.watch<ManagementSession>().shopConfiguration?.logoUrl.trim() ??
            '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: SharedAppColors.elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SharedAppColors.stroke),
            ),
            clipBehavior: Clip.antiAlias,
            child: logoUrl.isEmpty
                ? const Icon(
                    Icons.storefront_rounded,
                    color: SharedAppColors.orange,
                  )
                : Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.storefront_rounded,
                      color: SharedAppColors.orange,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SharedAppColors.text,
                    fontFamily: 'Barlow Condensed',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAdmin
                      ? 'Controle equipe, serviços, caixa e desempenho da unidade.'
                      : 'Confirme atendimentos, bloqueie horários e acompanhe sua comissão.',
                  style: const TextStyle(
                    color: SharedAppColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarberAgendaPage extends StatelessWidget {
  const _BarberAgendaPage({this.adminView = false});

  final bool adminView;

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        if (session.scheduleAdminView != adminView) {
          Future.microtask(() => session.setScheduleAdminView(adminView));
        }
        final entries = session.scheduleEntries;
        final confirmedCount = entries
            .where((entry) =>
                entry.status == 'Aceito' || entry.status == 'Confirmado')
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsGrid(
              cards: [
                _MetricData(
                  'Hoje',
                  '${entries.length}',
                  Icons.calendar_today_rounded,
                ),
                _MetricData(
                  'Confirmados',
                  '$confirmedCount',
                  Icons.event_available_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ScheduleFilters(adminView: adminView),
            const SizedBox(height: 22),
            const _SectionTitle('Próximos horários'),
            const SizedBox(height: 12),
            if (session.isScheduleLoading) ...[
              const LinearProgressIndicator(color: SharedAppColors.orange),
              const SizedBox(height: 12),
            ],
            if (session.scheduleError != null)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                title: 'Não foi possível carregar a agenda',
                subtitle: session.scheduleError!,
              )
            else if (entries.isEmpty)
              const _InlineNotice(
                icon: Icons.event_busy_rounded,
                title: 'Agenda vazia',
                subtitle: 'Nenhum agendamento encontrado para esta data.',
              )
            else
              for (final entry in entries)
                _AppointmentTile(
                  entry: entry,
                  showBarber: adminView,
                  onTap: () => _showScheduleDetails(context, entry),
                ),
          ],
        );
      },
    );
  }

  void _showScheduleDetails(BuildContext context, ScheduleEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.client,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _RequestInfoRow(
                icon: Icons.schedule_rounded,
                label: 'Horário',
                value: entry.time,
              ),
              _RequestInfoRow(
                icon: Icons.content_cut_rounded,
                label: 'Serviço',
                value: entry.service,
              ),
              _RequestInfoRow(
                icon: Icons.badge_outlined,
                label: 'Barbeiro',
                value: entry.barber,
              ),
              _RequestInfoRow(
                icon: Icons.info_outline_rounded,
                label: 'Status',
                value: entry.status,
              ),
              _RequestInfoRow(
                icon: Icons.notes_rounded,
                label: 'Obs.',
                value: entry.notes,
              ),
              if (entry.canComplete) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await context
                          .read<ManagementSession>()
                          .completeAppointment(entry.appointmentId!);
                      if (!context.mounted) return;
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Atendimento concluído.'),
                        ),
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Não foi possível concluir o atendimento.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Text('Concluir atendimento'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ScheduleFilters extends StatelessWidget {
  const _ScheduleFilters({required this.adminView});

  final bool adminView;

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final date = session.selectedScheduleDate;
        final days = List.generate(7, (index) {
          final now = DateTime.now();
          return DateTime(now.year, now.month, now.day + index);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (adminView) ...[
              DropdownButtonFormField<String>(
                value: _validBarberDropdownValue(session),
                decoration: const InputDecoration(
                  labelText: 'Barbeiro',
                  prefixIcon: Icon(Icons.badge_outlined),
                  filled: true,
                  fillColor: SharedAppColors.card,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: _allBarbersDropdownValue,
                    child: Text('Todos os barbeiros'),
                  ),
                  for (final barber in _uniqueBarbers(session.teamBarbers))
                    DropdownMenuItem<String>(
                      value: barber.id,
                      child: Text(barber.name),
                    ),
                ],
                onChanged: (value) => session.selectScheduleBarber(
                  value == _allBarbersDropdownValue ? null : value,
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final day = days[index];
                  final selected = DateUtils.isSameDay(day, date);
                  return ChoiceChip(
                    label: Text(_dayLabel(day)),
                    selected: selected,
                    onSelected: (_) => session.selectScheduleDate(day),
                    selectedColor: SharedAppColors.orange,
                    backgroundColor: SharedAppColors.elevated,
                    side: const BorderSide(color: SharedAppColors.stroke),
                    labelStyle: TextStyle(
                      color: selected
                          ? SharedAppColors.onGold
                          : SharedAppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _dayLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _validBarberDropdownValue(ManagementSession session) {
    final selected = session.selectedScheduleBarberId;
    if (selected == null || selected.isEmpty) return _allBarbersDropdownValue;
    final exists = session.teamBarbers.any((barber) => barber.id == selected);
    return exists ? selected : _allBarbersDropdownValue;
  }

  List<TeamBarber> _uniqueBarbers(List<TeamBarber> barbers) {
    final seen = <String>{};
    return [
      for (final barber in barbers)
        if (barber.id.isNotEmpty && seen.add(barber.id)) barber,
    ];
  }
}

class _BookingRequestsPage extends StatelessWidget {
  const _BookingRequestsPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final requests = session.bookingRequests;
        final newCount =
            requests.where((request) => request.status == 'new').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsGrid(
              cards: [
                _MetricData(
                  'Novas',
                  '$newCount',
                  Icons.mark_email_unread_rounded,
                ),
                _MetricData(
                    'Pedidos', '${requests.length}', Icons.today_rounded),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Novas solicitações'),
            const SizedBox(height: 12),
            if (session.isBookingRequestsLoading) ...[
              const LinearProgressIndicator(color: SharedAppColors.orange),
              const SizedBox(height: 12),
            ],
            if (session.bookingRequestsError != null)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                title: 'Não foi possível carregar',
                subtitle: session.bookingRequestsError!,
              )
            else if (session.bookingRequestActionError != null) ...[
              _InlineNotice(
                icon: Icons.event_busy_rounded,
                title: 'Não foi possível aceitar a solicitação',
                subtitle: session.bookingRequestActionError!,
              ),
              const SizedBox(height: 12),
            ],
            if (requests.isEmpty && session.bookingRequestsError == null)
              const _InlineNotice(
                icon: Icons.inbox_rounded,
                title: 'Nenhum pedido por enquanto',
                subtitle: 'As solicitações do app cliente aparecerão aqui.',
              )
            else if (requests.isNotEmpty)
              for (final request in requests)
                _BookingRequestTile(
                  request: request,
                  total: _formatCurrency(request.total),
                  onAccepted: () => _runRequestAction(
                    context,
                    () => session.updateBookingRequestStatus(
                      request.id,
                      'converted',
                    ),
                  ),
                  onDeclined: () => _declineRequest(context, session, request),
                  onCancelled: () => _runRequestAction(
                    context,
                    () => session.updateBookingRequestStatus(
                      request.id,
                      'cancelled',
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Future<void> _declineRequest(
    BuildContext context,
    ManagementSession session,
    BookingRequest request,
  ) async {
    final reason = await _askOptionalReason(context);
    if (!context.mounted) return;
    await _runRequestAction(
      context,
      () => session.updateBookingRequestStatus(
        request.id,
        'cancelled',
        reason: reason,
      ),
    );
  }

  Future<String?> _askOptionalReason(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recusar solicitação'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Motivo opcional'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Recusar'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<void> _runRequestAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      final message = error
          .toString()
          .replaceFirst(RegExp(r'^\s*Bad state:\s*', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^\s*Exception:\s*', caseSensitive: false), '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    return 'R\$ ${parts[0]},${parts[1]}';
  }
}

class _AvailabilityPage extends StatelessWidget {
  const _AvailabilityPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Horários disponíveis'),
        SizedBox(height: 12),
        _ScheduleTile(day: 'Segunda a sexta', hours: '09:00 - 18:00'),
        _ScheduleTile(day: 'Sábado', hours: '09:00 - 14:00'),
        SizedBox(height: 22),
        _SectionTitle('Bloqueios'),
        SizedBox(height: 12),
        _BlockedTile(
          title: 'Almoço estendido',
          detail: 'Hoje, 12:00 - 13:30',
        ),
        _BlockedTile(
          title: 'Férias programadas',
          detail: '12/08 até 18/08',
        ),
        SizedBox(height: 22),
        _ActionPanel(
          title: 'Ajustar disponibilidade',
          subtitle: 'Crie horários fixos, folgas ou bloqueios rápidos.',
          buttonLabel: 'Novo bloqueio',
          icon: Icons.event_busy_rounded,
        ),
      ],
    );
  }
}

class _ClientsPage extends StatelessWidget {
  const _ClientsPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final customers = session.filteredCustomers;
        final activeCount =
            session.customers.where((customer) => customer.isActive).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActionPanel(
              title: 'Clientes atendidos',
              subtitle: '$activeCount cliente(s) ativo(s) na barbearia.',
              buttonLabel: 'Atualizar',
              icon: Icons.refresh_rounded,
              onPressed: session.fetchCustomers,
            ),
            const SizedBox(height: 18),
            _CustomerFilters(session: session),
            const SizedBox(height: 18),
            if (session.isCustomersLoading) ...[
              const LinearProgressIndicator(color: SharedAppColors.orange),
              const SizedBox(height: 12),
            ],
            if (session.customersError != null)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                title: 'Não foi possível carregar os clientes',
                subtitle: session.customersError!,
              )
            else if (customers.isEmpty)
              const _InlineNotice(
                icon: Icons.people_alt_rounded,
                title: 'Nenhum cliente encontrado',
                subtitle: 'Ajuste os filtros ou aguarde novos agendamentos.',
              )
            else
              for (final customer in customers)
                _ClientTile(
                  customer: customer,
                  onTap: () => _openCustomerDetails(context, customer),
                ),
          ],
        );
      },
    );
  }

  Future<void> _openCustomerDetails(
    BuildContext context,
    ManagedCustomer customer,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: SharedAppColors.card,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ManagementSession>(),
        child: _CustomerDetailsSheet(customer: customer),
      ),
    );
  }
}

// ignore: unused_element
class _UnusedLegacyClientsPage extends StatelessWidget {
  const _UnusedLegacyClientsPage();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _CustomerFilters extends StatelessWidget {
  const _CustomerFilters({required this.session});

  final ManagementSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: session.setCustomerSearchQuery,
          decoration: InputDecoration(
            hintText: 'Buscar por nome ou telefone',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: SharedAppColors.elevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChipButton(
                label: 'Todos',
                selected:
                    session.customerStatusFilter == CustomerStatusFilter.all,
                onSelected: () =>
                    session.setCustomerStatusFilter(CustomerStatusFilter.all),
              ),
              _FilterChipButton(
                label: 'Ativos',
                selected:
                    session.customerStatusFilter == CustomerStatusFilter.active,
                onSelected: () => session
                    .setCustomerStatusFilter(CustomerStatusFilter.active),
              ),
              _FilterChipButton(
                label: 'Inativos',
                selected: session.customerStatusFilter ==
                    CustomerStatusFilter.inactive,
                onSelected: () => session
                    .setCustomerStatusFilter(CustomerStatusFilter.inactive),
              ),
              _FilterChipButton(
                label: 'Novos 30 dias',
                selected:
                    session.customerStatusFilter == CustomerStatusFilter.recent,
                onSelected: () => session
                    .setCustomerStatusFilter(CustomerStatusFilter.recent),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomerDetailsSheet extends StatefulWidget {
  const _CustomerDetailsSheet({required this.customer});

  final ManagedCustomer customer;

  @override
  State<_CustomerDetailsSheet> createState() => _CustomerDetailsSheetState();
}

class _CustomerDetailsSheetState extends State<_CustomerDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  late bool _isActive;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _notesController = TextEditingController(text: widget.customer.notes);
    _isActive = widget.customer.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ManagementSession>();
    final customer = session.customers.firstWhere(
      (item) => item.clientId == widget.customer.clientId,
      orElse: () => widget.customer,
    );
    final appointments = session.appointmentsForCustomer(customer.clientId);
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom + 20;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(child: _CustomerAvatar(customer: customer, radius: 34)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              enabled: customer.canEdit,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do cliente.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              enabled: customer.canEdit,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            _RequestInfoRow(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: customer.email,
            ),
            _RequestInfoRow(
              icon: Icons.event_available_rounded,
              label: 'Cadastro',
              value: customer.firstSeenAt == null
                  ? '-'
                  : ManagedCustomer._formatDate(customer.firstSeenAt!),
            ),
            _RequestInfoRow(
              icon: Icons.content_cut_rounded,
              label: 'Favorito',
              value: customer.favoriteBarber,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              enabled: customer.canEdit,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Observações internas',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isActive,
              activeColor: SharedAppColors.orange,
              onChanged: _isSaving || !customer.canEdit
                  ? null
                  : (value) => setState(() => _isActive = value),
              title: const Text('Cliente ativo'),
              subtitle: const Text('Clientes inativos ficam filtraveis.'),
            ),
            const SizedBox(height: 12),
            if (!customer.canEdit)
              const _InlineNotice(
                icon: Icons.info_outline_rounded,
                title: 'Cliente vindo de solicitação',
                subtitle:
                    'Este cliente ainda não possui cadastro vinculado. Ele aparece pelo agendamento realizado, mas a edição fica bloqueada.',
              )
            else
              FilledButton(
                onPressed: _isSaving ? null : () => _save(customer),
                style: FilledButton.styleFrom(
                  backgroundColor: SharedAppColors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(_isSaving ? 'Salvando...' : 'Salvar'),
              ),
            const SizedBox(height: 22),
            const _SectionTitle('Historico de agendamentos'),
            const SizedBox(height: 12),
            if (appointments.isEmpty)
              const _InlineNotice(
                icon: Icons.event_busy_rounded,
                title: 'Sem historico',
                subtitle: 'Nenhum atendimento registrado para este cliente.',
              )
            else
              for (final appointment in appointments)
                _CustomerAppointmentTile(appointment: appointment),
          ],
        ),
      ),
    );
  }

  Future<void> _save(ManagedCustomer customer) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await context.read<ManagementSession>().updateCustomer(
            customer,
            name: _nameController.text,
            phone: _phoneController.text,
            notes: _notesController.text,
            isActive: _isActive,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente salvo com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _CustomerAppointmentTile extends StatelessWidget {
  const _CustomerAppointmentTile({required this.appointment});

  final CustomerAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const _IconBadge(Icons.event_available_rounded),
      title: appointment.service,
      subtitle: '${appointment.barber} - ${appointment.dateLabel}',
      trailing: Chip(
        label: Text(appointment.status),
        side: BorderSide.none,
        backgroundColor: SharedAppColors.background,
      ),
    );
  }
}

class _CommissionPage extends StatelessWidget {
  const _CommissionPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsGrid(
          cards: [
            _MetricData('Semana', 'R\$ 1.780', Icons.trending_up_rounded),
            _MetricData(
                'Comissão', 'R\$ 712', Icons.account_balance_wallet_rounded),
          ],
        ),
        SizedBox(height: 22),
        _SectionTitle('Resumo'),
        SizedBox(height: 12),
        _InsightTile(
          title: 'Atendimentos concluídos',
          value: '31',
          subtitle: 'Ticket médio de R\$ 57',
        ),
        _InsightTile(
          title: 'Serviço mais feito',
          value: 'Corte + barba',
          subtitle: '14 atendimentos no período',
        ),
      ],
    );
  }
}

class _AdminDashboardPage extends StatelessWidget {
  const _AdminDashboardPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsGrid(
          cards: [
            _MetricData('Faturamento', 'R\$ 4.820', Icons.trending_up_rounded),
            _MetricData('Agendamentos', '46', Icons.event_available_rounded),
          ],
        ),
        SizedBox(height: 22),
        _SectionTitle('Indicadores'),
        SizedBox(height: 12),
        _InsightTile(
          title: 'Barbeiro destaque',
          value: 'Equipe ativa',
          subtitle: '18 atendimentos esta semana',
        ),
        _InsightTile(
          title: 'Serviço mais vendido',
          value: 'Corte + barba',
          subtitle: '34% dos agendamentos',
        ),
        _InsightTile(
          title: 'Caixa do dia',
          value: 'R\$ 1.240',
          subtitle: 'PIX, dinheiro e cartão',
        ),
      ],
    );
  }
}

class _ServicesPage extends StatelessWidget {
  const _ServicesPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final services = session.filteredServices;
        final activeCount =
            session.services.where((service) => service.isActive).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActionPanel(
              title: 'Catálogo de serviços',
              subtitle:
                  '$activeCount serviço(s) ativo(s). Gerencie preços e duração.',
              buttonLabel: 'Novo serviço',
              icon: Icons.add_circle_rounded,
              onPressed: () => _openServiceForm(context),
            ),
            const SizedBox(height: 18),
            _ServiceFilters(session: session),
            const SizedBox(height: 18),
            if (session.isServicesLoading) ...[
              const LinearProgressIndicator(color: SharedAppColors.orange),
              const SizedBox(height: 12),
            ],
            if (session.servicesError != null)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                title: 'Não foi possível carregar os serviços',
                subtitle: session.servicesError!,
              )
            else if (services.isEmpty)
              const _InlineNotice(
                icon: Icons.content_cut_rounded,
                title: 'Nenhum serviço encontrado',
                subtitle: 'Ajuste os filtros ou cadastre um novo serviço.',
              )
            else
              for (final service in services)
                _ServiceTile(
                  service: service,
                  onTap: () => _openServiceForm(context, service: service),
                ),
          ],
        );
      },
    );
  }

  Future<void> _openServiceForm(
    BuildContext context, {
    ManagedService? service,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: SharedAppColors.card,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ManagementSession>(),
        child: _ServiceForm(service: service),
      ),
    );
  }
}

// ignore: unused_element
class _UnusedServicesPageSnapshot extends StatelessWidget {
  const _UnusedServicesPageSnapshot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// ignore: unused_element
class _UnusedLegacyServicesPageSnapshot extends StatelessWidget {
  const _UnusedLegacyServicesPageSnapshot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
    /*
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActionPanel(
          title: 'Catálogo de serviços',
          subtitle: 'Cadastre preços, duração e comissão por serviço.',
          buttonLabel: 'Novo serviço',
          icon: Icons.add_circle_rounded,
        ),
        SizedBox(height: 18),
      ],
    );
  }
}

    */
  }
}

class _ServiceFilters extends StatelessWidget {
  const _ServiceFilters({required this.session});

  final ManagementSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: session.setServiceSearchQuery,
          decoration: InputDecoration(
            hintText: 'Buscar serviço por nome',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: SharedAppColors.elevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChipButton(
                label: 'Todos',
                selected:
                    session.serviceStatusFilter == ServiceStatusFilter.all,
                onSelected: () =>
                    session.setServiceStatusFilter(ServiceStatusFilter.all),
              ),
              _FilterChipButton(
                label: 'Ativos',
                selected:
                    session.serviceStatusFilter == ServiceStatusFilter.active,
                onSelected: () =>
                    session.setServiceStatusFilter(ServiceStatusFilter.active),
              ),
              _FilterChipButton(
                label: 'Inativos',
                selected:
                    session.serviceStatusFilter == ServiceStatusFilter.inactive,
                onSelected: () => session
                    .setServiceStatusFilter(ServiceStatusFilter.inactive),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _validCategoryFilterValue(session),
          decoration: const InputDecoration(
            labelText: 'Categoria',
            prefixIcon: Icon(Icons.category_outlined),
            filled: true,
            fillColor: SharedAppColors.elevated,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: _allCategoriesDropdownValue,
              child: Text('Todas as categorias'),
            ),
            for (final category in _uniqueCategories(session.serviceCategories))
              DropdownMenuItem<String>(
                value: category.id,
                child: Text(category.name),
              ),
          ],
          onChanged: (value) => session.setServiceCategoryFilter(
            value == _allCategoriesDropdownValue ? null : value,
          ),
        ),
      ],
    );
  }

  String _validCategoryFilterValue(ManagementSession session) {
    final selected = session.selectedServiceCategoryId;
    if (selected == null || selected.isEmpty) {
      return _allCategoriesDropdownValue;
    }
    final exists =
        session.serviceCategories.any((category) => category.id == selected);
    return exists ? selected : _allCategoriesDropdownValue;
  }

  List<ServiceCategory> _uniqueCategories(List<ServiceCategory> categories) {
    final seen = <String>{};
    return [
      for (final category in categories)
        if (category.id.isNotEmpty && seen.add(category.id)) category,
    ];
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: SharedAppColors.orange,
        backgroundColor: SharedAppColors.elevated,
        side: const BorderSide(color: SharedAppColors.stroke),
        labelStyle: TextStyle(
          color: selected ? SharedAppColors.onGold : SharedAppColors.text,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ServiceForm extends StatefulWidget {
  const _ServiceForm({this.service});

  final ManagedService? service;

  @override
  State<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<_ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _colorController;
  late bool _isActive;
  String? _categoryId;
  var _isSaving = false;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _nameController = TextEditingController(text: service?.name ?? '');
    _descriptionController =
        TextEditingController(text: service?.description ?? '');
    _priceController = TextEditingController(
      text: service == null ? '' : service.price.toStringAsFixed(2),
    );
    _durationController = TextEditingController(
      text: service == null ? '' : service.durationMinutes.toString(),
    );
    _imageUrlController = TextEditingController(text: service?.imageUrl ?? '');
    _colorController = TextEditingController();
    _isActive = service?.isActive ?? true;
    _categoryId = service?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _imageUrlController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom + 20;
    final categories = context.watch<ManagementSession>().serviceCategories;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Editar serviço' : 'Novo serviço',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.content_cut_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do serviço.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _validFormCategoryValue(categories),
              decoration: const InputDecoration(
                labelText: 'Categoria',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: _noCategoryDropdownValue,
                  child: Text('Sem categoria'),
                ),
                for (final category in _uniqueFormCategories(categories))
                  DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() {
                        _categoryId =
                            value == _noCategoryDropdownValue ? null : value;
                      }),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descricao',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Preco',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: _validatePrice,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duracao min',
                      prefixIcon: Icon(Icons.schedule_rounded),
                    ),
                    validator: _validateDuration,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrlController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'URL da imagem',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _colorController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Cor de identificacao',
                helperText:
                    'Preparado para integrar quando houver coluna no banco.',
                prefixIcon: Icon(Icons.palette_outlined),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isActive,
              activeColor: SharedAppColors.orange,
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _isActive = value),
              title: const Text('Serviço ativo'),
              subtitle: const Text('Serviços inativos deixam de aparecer.'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: SharedAppColors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(_isSaving ? 'Salvando...' : 'Salvar'),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSaving ? null : _confirmDeleteOrDeactivate,
                child: const Text('Excluir serviço'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _validatePrice(String? value) {
    final parsed = _parseMoney(value);
    if (parsed == null || parsed <= 0) {
      return 'Informe um preco maior que zero.';
    }
    return null;
  }

  String? _validateDuration(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Informe a duracao.';
    return null;
  }

  double? _parseMoney(String? value) {
    if (value == null) return null;
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String _validFormCategoryValue(List<ServiceCategory> categories) {
    final selected = _categoryId;
    if (selected == null || selected.isEmpty) return _noCategoryDropdownValue;
    final exists = categories.any((category) => category.id == selected);
    return exists ? selected : _noCategoryDropdownValue;
  }

  List<ServiceCategory> _uniqueFormCategories(
      List<ServiceCategory> categories) {
    final seen = <String>{};
    return [
      for (final category in categories)
        if (category.id.isNotEmpty && seen.add(category.id)) category,
    ];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final session = context.read<ManagementSession>();
      final service = widget.service;
      if (service == null) {
        await session.createService(
          name: _nameController.text,
          description: _descriptionController.text,
          categoryId: _categoryId,
          price: _parseMoney(_priceController.text)!,
          durationMinutes: int.parse(_durationController.text.trim()),
          imageUrl: _imageUrlController.text,
          isActive: _isActive,
        );
      } else {
        await session.updateService(
          service,
          name: _nameController.text,
          description: _descriptionController.text,
          categoryId: _categoryId,
          price: _parseMoney(_priceController.text)!,
          durationMinutes: int.parse(_durationController.text.trim()),
          imageUrl: _imageUrlController.text,
          isActive: _isActive,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serviço salvo com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDeleteOrDeactivate() async {
    final service = widget.service;
    if (service == null) return;
    final session = context.read<ManagementSession>();
    final canDelete = service.appointmentCount == 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(canDelete ? 'Excluir serviço?' : 'Inativar serviço?'),
        content: Text(
          canDelete
              ? 'Este serviço não possui agendamentos e será removido do banco.'
              : 'Não é possível excluir este serviço porque existem agendamentos feitos nele. Para preservar o histórico, ele será apenas inativado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: SharedAppColors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(canDelete ? 'Excluir' : 'Inativar'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await session.deleteOrDeactivateService(service);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(canDelete ? 'Serviço excluído.' : 'Serviço inativado.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _TeamPage extends StatelessWidget {
  const _TeamPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final activeCount =
            session.teamBarbers.where((barber) => barber.isActive).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActionPanel(
              title: 'Equipe da unidade',
              subtitle:
                  '$activeCount barbeiro(s) ativo(s). Gerencie percentuais e agenda.',
              buttonLabel: 'Novo barbeiro',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () => _openTeamBarberForm(context),
            ),
            const SizedBox(height: 18),
            if (session.isLoading) ...[
              const LinearProgressIndicator(color: SharedAppColors.orange),
              const SizedBox(height: 12),
            ],
            if (session.errorMessage != null)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                title: 'Não foi possível carregar a equipe',
                subtitle: session.errorMessage!,
              )
            else if (session.teamBarbers.isEmpty)
              const _InlineNotice(
                icon: Icons.groups_rounded,
                title: 'Nenhum barbeiro cadastrado',
                subtitle: 'Cadastre o primeiro profissional da unidade.',
              )
            else
              for (final barber in session.teamBarbers)
                _TeamBarberTile(
                  barber: barber,
                  onTap: () => _openTeamBarberForm(context, barber: barber),
                ),
          ],
        );
      },
    );
  }

  Future<void> _openTeamBarberForm(
    BuildContext context, {
    TeamBarber? barber,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: SharedAppColors.card,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ManagementSession>(),
        child: _TeamBarberForm(barber: barber),
      ),
    );
  }
}

class LegacyTeamPage extends StatelessWidget {
  const LegacyTeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActionPanel(
          title: 'Equipe da unidade',
          subtitle: 'Gerencie barbeiros, permissões e percentuais.',
          buttonLabel: 'Novo barbeiro',
          icon: Icons.person_add_alt_1_rounded,
        ),
        SizedBox(height: 18),
        _TeamTile(
          name: 'Barbeiro demo',
          role: 'Barbeiro principal',
          detail: '40% comissão - agenda ativa',
        ),
        _TeamTile(
          name: 'Ricardo Anderson',
          role: 'Barbeiro',
          detail: '35% comissão - agenda ativa',
        ),
        _TeamTile(
          name: 'Camila Rocha',
          role: 'Recepção',
          detail: 'Acesso a agenda e caixa',
        ),
      ],
    );
  }
}

class _TeamBarberForm extends StatefulWidget {
  const _TeamBarberForm({this.barber});

  final TeamBarber? barber;

  @override
  State<_TeamBarberForm> createState() => _TeamBarberFormState();
}

class _TeamBarberFormState extends State<_TeamBarberForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _photoUrlController;
  late final TextEditingController _startingPriceController;
  late final TextEditingController _commissionController;
  late bool _isActive;
  var _isSaving = false;

  bool get _isEditing => widget.barber != null;

  @override
  void initState() {
    super.initState();
    final barber = widget.barber;
    _nameController = TextEditingController(text: barber?.name ?? '');
    _bioController = TextEditingController(text: barber?.bio ?? '');
    _photoUrlController = TextEditingController(text: barber?.photoUrl ?? '');
    _startingPriceController = TextEditingController(
      text: barber == null ? '' : barber.startingPrice.toStringAsFixed(2),
    );
    _commissionController = TextEditingController(
      text: barber == null ? '' : barber.commissionPercent.toStringAsFixed(0),
    );
    _isActive = barber?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _photoUrlController.dispose();
    _startingPriceController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom + 20;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Editar barbeiro' : 'Novo barbeiro',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Informe o nome do barbeiro.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bioController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _photoUrlController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'URL da foto',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startingPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Preço inicial',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: _validateMoney,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _commissionController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Comissão %',
                      prefixIcon: Icon(Icons.percent),
                    ),
                    validator: _validateCommission,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isActive,
              activeColor: SharedAppColors.orange,
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _isActive = value),
              title: const Text('Agenda ativa'),
              subtitle: const Text('Barbeiros inativos deixam de aparecer.'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: SharedAppColors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(_isSaving ? 'Salvando...' : 'Salvar'),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSaving ? null : _deactivate,
                child: const Text('Desativar barbeiro'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _validateMoney(String? value) {
    final parsed = _parseNumber(value);
    if (parsed == null || parsed < 0) return 'Valor inválido.';
    return null;
  }

  String? _validateCommission(String? value) {
    final parsed = _parseNumber(value);
    if (parsed == null || parsed < 0 || parsed > 100) {
      return 'Use 0 a 100.';
    }
    return null;
  }

  double? _parseNumber(String? value) {
    if (value == null) return null;
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final session = context.read<ManagementSession>();
      final barber = widget.barber;
      if (barber == null) {
        await session.createTeamBarber(
          name: _nameController.text,
          bio: _bioController.text,
          photoUrl: _photoUrlController.text,
          startingPrice: _parseNumber(_startingPriceController.text)!,
          commissionPercent: _parseNumber(_commissionController.text)!,
        );
      } else {
        await session.updateTeamBarber(
          barber,
          name: _nameController.text,
          bio: _bioController.text,
          photoUrl: _photoUrlController.text,
          startingPrice: _parseNumber(_startingPriceController.text)!,
          commissionPercent: _parseNumber(_commissionController.text)!,
          isActive: _isActive,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deactivate() async {
    final barber = widget.barber;
    if (barber == null) return;

    setState(() => _isSaving = true);
    try {
      await context.read<ManagementSession>().deactivateTeamBarber(barber);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final config = session.shopConfiguration;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActionPanel(
              title: 'Configuração da barbearia',
              subtitle: 'Defina dados públicos, horários e regras de agenda.',
              buttonLabel: 'Atualizar',
              icon: Icons.refresh_rounded,
              onPressed: session.fetchShopConfiguration,
            ),
            const SizedBox(height: 18),
            if (session.isSettingsLoading) ...[
              const LinearProgressIndicator(color: SharedAppColors.orange),
              const SizedBox(height: 12),
            ],
            if (session.settingsError != null)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                title: 'Não foi possível carregar as configurações',
                subtitle: session.settingsError!,
              )
            else if (config == null)
              const _InlineNotice(
                icon: Icons.settings_outlined,
                title: 'Configuração não carregada',
                subtitle: 'Toque em Atualizar para buscar os dados.',
              )
            else
              _SettingsForm(config: config),
          ],
        );
      },
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm({required this.config});

  final ShopConfiguration config;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _logoController;
  late final TextEditingController _coverController;
  late final TextEditingController _documentController;
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _emailController;
  late final TextEditingController _instagramController;
  late final TextEditingController _addressController;
  late final TextEditingController _zipController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _lunchStartController;
  late final TextEditingController _lunchEndController;
  late final TextEditingController _bookingDaysController;
  late final TextEditingController _minNoticeController;
  late final TextEditingController _maxDelayController;
  late final TextEditingController _cancelHoursController;
  late final TextEditingController _secondaryColorController;
  late List<ShopBusinessDay> _days;
  late bool _lunchEnabled;
  late int _bookingInterval;
  var _isSaving = false;
  var _isUploadingLogo = false;
  var _isUploadingCover = false;

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _nameController = TextEditingController(text: config.name);
    _logoController = TextEditingController(text: config.logoUrl);
    _coverController = TextEditingController(text: config.coverUrl);
    _documentController = TextEditingController(text: config.document);
    _phoneController = TextEditingController(text: config.phone);
    _whatsappController = TextEditingController(text: config.whatsapp);
    _emailController = TextEditingController(text: config.email);
    _instagramController = TextEditingController(text: config.instagram);
    _addressController = TextEditingController(text: config.address);
    _zipController = TextEditingController(text: config.zipCode);
    _cityController = TextEditingController(text: config.city);
    _stateController = TextEditingController(text: config.state);
    _lunchStartController = TextEditingController(text: config.lunchStart);
    _lunchEndController = TextEditingController(text: config.lunchEnd);
    _bookingDaysController =
        TextEditingController(text: config.bookingDaysAhead.toString());
    _minNoticeController =
        TextEditingController(text: config.minNoticeMinutes.toString());
    _maxDelayController =
        TextEditingController(text: config.maxDelayMinutes.toString());
    _cancelHoursController =
        TextEditingController(text: config.minCancelHours.toString());
    _secondaryColorController =
        TextEditingController(text: config.secondaryColor);
    _days = List.of(config.days);
    _lunchEnabled = config.lunchEnabled;
    _bookingInterval = config.bookingIntervalMinutes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _logoController.dispose();
    _coverController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _instagramController.dispose();
    _addressController.dispose();
    _zipController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _lunchStartController.dispose();
    _lunchEndController.dispose();
    _bookingDaysController.dispose();
    _minNoticeController.dispose();
    _maxDelayController.dispose();
    _cancelHoursController.dispose();
    _secondaryColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('Informações gerais'),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da barbearia',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _logoController,
                      decoration: const InputDecoration(
                        labelText: 'URL da logo',
                        helperText:
                            'Faça upload pelo Storage ou cole uma URL pública.',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: _isUploadingLogo ? null : _pickAndUploadLogo,
                    style: IconButton.styleFrom(
                      backgroundColor: SharedAppColors.orange,
                      foregroundColor: SharedAppColors.onGold,
                    ),
                    icon: _isUploadingLogo
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: SharedAppColors.onGold,
                            ),
                          )
                        : const Icon(Icons.upload_rounded),
                    tooltip: 'Enviar logo',
                  ),
                ],
              ),
              if (_logoController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    _logoController.text.trim(),
                    height: 88,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _coverController,
                      decoration: const InputDecoration(
                        labelText: 'URL da foto de capa',
                        helperText: 'Banner publico usado no app Cliente.',
                        prefixIcon: Icon(Icons.landscape_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: _isUploadingCover ? null : _pickAndUploadCover,
                    style: IconButton.styleFrom(
                      backgroundColor: SharedAppColors.orange,
                      foregroundColor: SharedAppColors.onGold,
                    ),
                    icon: _isUploadingCover
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: SharedAppColors.onGold,
                            ),
                          )
                        : const Icon(Icons.upload_rounded),
                    tooltip: 'Enviar foto de capa',
                  ),
                ],
              ),
              if (_coverController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    _coverController.text.trim(),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _documentController,
                decoration: const InputDecoration(
                  labelText: 'CNPJ',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _whatsappController,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp',
                        prefixIcon: Icon(Icons.chat_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instagramController,
                decoration: const InputDecoration(
                  labelText: 'Instagram',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Endereço completo',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _zipController,
                      decoration: const InputDecoration(labelText: 'CEP'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 82,
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'UF'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _secondaryColorController,
                decoration: const InputDecoration(
                  labelText: 'Cor secundaria da barbearia',
                  helperText:
                      'Use apenas como detalhe do estabelecimento. A marca Clube da Regua permanece fixa.',
                  prefixIcon: Icon(Icons.palette_outlined),
                ),
                validator: _validateHexColor,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Horário de funcionamento'),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              for (var index = 0; index < _days.length; index++)
                _BusinessDayEditor(
                  day: _days[index],
                  onChanged: (day) => setState(() => _days[index] = day),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Intervalo'),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _lunchEnabled,
                activeColor: SharedAppColors.orange,
                title: const Text('Almoço'),
                subtitle: const Text('Bloqueia intervalo recorrente.'),
                onChanged: (value) => setState(() => _lunchEnabled = value),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      enabled: _lunchEnabled,
                      controller: _lunchStartController,
                      decoration: const InputDecoration(labelText: 'Início'),
                      validator: _validateTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      enabled: _lunchEnabled,
                      controller: _lunchEndController,
                      decoration: const InputDecoration(labelText: 'Fim'),
                      validator: _validateTime,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Configuração de agendamento'),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              DropdownButtonFormField<int>(
                value: _bookingInterval,
                decoration: const InputDecoration(
                  labelText: 'Tempo entre atendimentos',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                items: const [5, 10, 15, 20, 30]
                    .map(
                      (value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value minutos'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _bookingInterval = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bookingDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dias no futuro para agendar',
                  prefixIcon: Icon(Icons.event_available_outlined),
                ),
                validator: _positiveInt,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minNoticeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Antecedência mínima em minutos',
                  prefixIcon: Icon(Icons.schedule_outlined),
                ),
                validator: _positiveInt,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxDelayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tempo maximo de atraso em minutos',
                  prefixIcon: Icon(Icons.hourglass_bottom_rounded),
                ),
                validator: _positiveInt,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cancelHoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cancelamento permitido até X horas antes',
                  prefixIcon: Icon(Icons.event_busy_outlined),
                ),
                validator: _positiveInt,
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: SharedAppColors.orange,
              foregroundColor: SharedAppColors.onGold,
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(_isSaving ? 'Salvando...' : 'Salvar configurações'),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório.';
    return null;
  }

  String? _positiveInt(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Informe um número válido.';
    return null;
  }

  String? _validateHexColor(String? value) {
    final color = value?.trim() ?? '';
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(color)) {
      return 'Use uma cor no formato #F3B200.';
    }
    return null;
  }

  String? _validateTime(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o horário.';
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(value.trim())) {
      return 'Use HH:mm.';
    }
    return null;
  }

  Future<void> _pickAndUploadLogo() async {
    final session = context.read<ManagementSession>();
    setState(() => _isUploadingLogo = true);
    try {
      final file = await pickLogoFile();
      if (file == null) return;
      final url = await session.uploadShopMedia(file, folder: 'logos');
      if (!mounted || url.isEmpty) return;
      setState(() => _logoController.text = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo enviada com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _pickAndUploadCover() async {
    final session = context.read<ManagementSession>();
    setState(() => _isUploadingCover = true);
    try {
      final file = await pickLogoFile();
      if (file == null) return;
      final url = await session.uploadShopMedia(file, folder: 'banners');
      if (!mounted || url.isEmpty) return;
      setState(() => _coverController.text = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de capa enviada com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final current = widget.config;
      final config = ShopConfiguration(
        shopId: current.shopId,
        settingsId: current.settingsId,
        name: _nameController.text,
        logoUrl: _logoController.text,
        coverUrl: _coverController.text,
        document: _documentController.text,
        phone: _phoneController.text,
        whatsapp: _whatsappController.text,
        email: _emailController.text,
        instagram: _instagramController.text,
        address: _addressController.text,
        zipCode: _zipController.text,
        city: _cityController.text,
        state: _stateController.text,
        days: _days,
        lunchEnabled: _lunchEnabled,
        lunchStart: _lunchStartController.text,
        lunchEnd: _lunchEndController.text,
        bookingIntervalMinutes: _bookingInterval,
        bookingDaysAhead: int.parse(_bookingDaysController.text.trim()),
        minNoticeMinutes: int.parse(_minNoticeController.text.trim()),
        maxDelayMinutes: int.parse(_maxDelayController.text.trim()),
        minCancelHours: int.parse(_cancelHoursController.text.trim()),
        secondaryColor: _secondaryColorController.text,
      );
      await context.read<ManagementSession>().saveShopConfiguration(config);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: SharedAppColors.dark,
            labelStyle: const TextStyle(color: SharedAppColors.muted),
            helperStyle: const TextStyle(color: SharedAppColors.muted),
            prefixIconColor: SharedAppColors.orange,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SharedAppColors.stroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SharedAppColors.orange),
            ),
          ),
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: SharedAppColors.text,
                displayColor: SharedAppColors.text,
              ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? SharedAppColors.orange
                  : SharedAppColors.muted,
            ),
          ),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: SharedAppColors.text),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _BusinessDayEditor extends StatelessWidget {
  const _BusinessDayEditor({
    required this.day,
    required this.onChanged,
  });

  final ShopBusinessDay day;
  final ValueChanged<ShopBusinessDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: day.isOpen,
            activeColor: SharedAppColors.orange,
            title: Text(day.label),
            subtitle: Text(day.isOpen ? 'Aberto' : 'Fechado'),
            onChanged: (value) => onChanged(day.copyWith(isOpen: value)),
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  enabled: day.isOpen,
                  initialValue: day.openTime,
                  decoration: const InputDecoration(labelText: 'Abertura'),
                  validator: (value) {
                    if (!day.isOpen) return null;
                    if (value == null ||
                        !RegExp(r'^\d{2}:\d{2}$').hasMatch(value.trim())) {
                      return 'HH:mm';
                    }
                    return null;
                  },
                  onChanged: (value) =>
                      onChanged(day.copyWith(openTime: value.trim())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  enabled: day.isOpen,
                  initialValue: day.closeTime,
                  decoration: const InputDecoration(labelText: 'Fechamento'),
                  validator: (value) {
                    if (!day.isOpen) return null;
                    if (value == null ||
                        !RegExp(r'^\d{2}:\d{2}$').hasMatch(value.trim())) {
                      return 'HH:mm';
                    }
                    return null;
                  },
                  onChanged: (value) =>
                      onChanged(day.copyWith(closeTime: value.trim())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashPage extends StatelessWidget {
  const _CashPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsGrid(
          cards: [
            _MetricData('Entradas', 'R\$ 1.240', Icons.south_west_rounded),
            _MetricData('Saídas', 'R\$ 180', Icons.north_east_rounded),
          ],
        ),
        SizedBox(height: 22),
        _SectionTitle('Movimentos de caixa'),
        SizedBox(height: 12),
        _CashMovementTile(title: 'PIX - Marcos Lima', value: '+ R\$ 85'),
        _CashMovementTile(title: 'Dinheiro - João Pedro', value: '+ R\$ 55'),
        _CashMovementTile(title: 'Compra de pomada', value: '- R\$ 180'),
        SizedBox(height: 22),
        _SectionTitle('Estoque crítico'),
        SizedBox(height: 12),
        _StockTile(name: 'Pomada modeladora', quantity: '3 un'),
        _StockTile(name: 'Lâmina descartável', quantity: '18 un'),
      ],
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.cards});

  final List<_MetricData> cards;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? cards.length.clamp(1, 4)
              : constraints.maxWidth >= 520
                  ? 2
                  : 1;
          final width =
              (constraints.maxWidth - ((columns - 1) * 12)) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final card in cards)
                SizedBox(width: width, child: _MetricCard(data: card)),
            ],
          );
        },
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: SharedAppColors.orange),
          const SizedBox(height: 16),
          Text(
            data.value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(data.label,
              style: const TextStyle(color: SharedAppColors.muted)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
    );
  }
}

// ignore: unused_element
class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: SharedAppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Row(
        children: [
          _IconBadge(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: SharedAppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({
    required this.entry,
    required this.showBarber,
    required this.onTap,
  });

  final ScheduleEntry entry;
  final bool showBarber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        showBarber ? '${entry.service} - ${entry.barber}' : entry.service;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: _SurfaceTile(
        leading: _TimeBadge(entry.time),
        title: entry.client,
        subtitle: subtitle,
        trailing: Chip(
          label: Text(entry.status),
          side: BorderSide.none,
          backgroundColor: SharedAppColors.background,
        ),
      ),
    );
  }
}

class _BookingRequestTile extends StatelessWidget {
  const _BookingRequestTile({
    required this.request,
    required this.total,
    required this.onAccepted,
    required this.onDeclined,
    required this.onCancelled,
  });

  final BookingRequest request;
  final String total;
  final VoidCallback onAccepted;
  final VoidCallback onDeclined;
  final VoidCallback onCancelled;

  @override
  Widget build(BuildContext context) {
    final status = request.status;
    final isClosed = status == 'converted' || status == 'cancelled';
    final wasDeclined =
        status == 'cancelled' && request.notes.contains('Motivo:');
    final statusLabel = switch (status) {
      'contacted' => 'Contatado',
      'converted' => 'Aceito',
      'cancelled' => wasDeclined ? 'Recusado' : 'Cancelado',
      _ => 'Novo',
    };
    final statusColor = switch (status) {
      'contacted' => Colors.blue.shade700,
      'converted' => Colors.green.shade700,
      'cancelled' => Colors.red.shade700,
      _ => SharedAppColors.orange,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ClientAvatar(photoUrl: request.clientPhotoUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.client,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.phone.isEmpty
                          ? 'Telefone não informado'
                          : request.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: SharedAppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    total,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(statusLabel),
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: statusColor.withOpacity(.1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RequestInfoRow(
            icon: Icons.content_cut_rounded,
            label: 'Serviço',
            value: request.service,
          ),
          _RequestInfoRow(
            icon: Icons.badge_outlined,
            label: 'Barbeiro',
            value: request.barber,
          ),
          _RequestInfoRow(
            icon: Icons.event_rounded,
            label: 'Data e horário',
            value: request.formattedDateTime,
          ),
          _RequestInfoRow(
            icon: Icons.payments_outlined,
            label: 'Pagamento',
            value: request.paymentMethod,
          ),
          _RequestInfoRow(
            icon: Icons.notes_rounded,
            label: 'Observações',
            value: request.observation,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isClosed ? null : onDeclined,
                  icon: const Icon(Icons.block_rounded),
                  label: const Text('Recusar'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Cancelar',
                onPressed: isClosed ? null : onCancelled,
                icon: const Icon(Icons.close_rounded),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: isClosed ? null : onAccepted,
                style: FilledButton.styleFrom(
                  backgroundColor: SharedAppColors.orange,
                  foregroundColor: SharedAppColors.onGold,
                ),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Aceitar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(photoUrl),
        backgroundColor: SharedAppColors.orange.withOpacity(.12),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: SharedAppColors.orange.withOpacity(.12),
      child: const Icon(Icons.person_rounded, color: SharedAppColors.orange),
    );
  }
}

class _RequestInfoRow extends StatelessWidget {
  const _RequestInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: SharedAppColors.muted),
          const SizedBox(width: 8),
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: SharedAppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge(this.time);

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SharedAppColors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        time,
        style: const TextStyle(
          color: SharedAppColors.orange,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.day, required this.hours});

  final String day;
  final String hours;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const _IconBadge(Icons.schedule_rounded),
      title: day,
      subtitle: hours,
      trailing: const Icon(Icons.edit_rounded, color: SharedAppColors.muted),
    );
  }
}

class _BlockedTile extends StatelessWidget {
  const _BlockedTile({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const _IconBadge(Icons.block_rounded),
      title: title,
      subtitle: detail,
      trailing:
          const Icon(Icons.more_horiz_rounded, color: SharedAppColors.muted),
    );
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({
    required this.customer,
    required this.onTap,
  });

  final ManagedCustomer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        customer.isActive ? Colors.green.shade700 : Colors.red.shade700;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: _SurfaceTile(
        leading: _CustomerAvatar(customer: customer),
        title: customer.name,
        subtitle:
            '${customer.phone.isEmpty ? 'Sem telefone' : customer.phone} - Ultimo: ${customer.lastAppointmentLabel}',
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${customer.appointmentCount} ag.',
              style: const TextStyle(
                color: SharedAppColors.orange,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              customer.statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({
    required this.customer,
    this.radius = 25,
  });

  final ManagedCustomer customer;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          customer.isActive ? SharedAppColors.orange : SharedAppColors.muted,
      backgroundImage:
          customer.avatarUrl.isEmpty ? null : NetworkImage(customer.avatarUrl),
      child: customer.avatarUrl.isEmpty
          ? const Icon(Icons.person_rounded, color: Colors.white)
          : null,
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.onTap,
  });

  final ManagedService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        service.isActive ? Colors.green.shade700 : Colors.red.shade700;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: _SurfaceTile(
        leading: service.imageUrl.isEmpty
            ? const _IconBadge(Icons.content_cut_rounded)
            : CircleAvatar(
                radius: 25,
                backgroundColor: SharedAppColors.orange.withOpacity(0.12),
                backgroundImage: NetworkImage(service.imageUrl),
              ),
        title: service.name,
        subtitle:
            '${service.categoryName} - ${service.durationLabel} - ${service.appointmentCount} agendamento(s)',
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              service.formattedPrice,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              service.statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({
    required this.name,
    required this.role,
    required this.detail,
  });

  final String name;
  final String role;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const CircleAvatar(
        radius: 25,
        backgroundColor: SharedAppColors.dark,
        child: Icon(Icons.person_rounded, color: Colors.white),
      ),
      title: name,
      subtitle: '$role · $detail',
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _TeamBarberTile extends StatelessWidget {
  const _TeamBarberTile({
    required this.barber,
    required this.onTap,
  });

  final TeamBarber barber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundColor:
            barber.isActive ? SharedAppColors.dark : SharedAppColors.muted,
        backgroundImage:
            barber.photoUrl.isEmpty ? null : NetworkImage(barber.photoUrl),
        child: barber.photoUrl.isEmpty
            ? const Icon(Icons.person_rounded, color: Colors.white)
            : null,
      ),
      title: barber.name,
      subtitle: '${barber.role} - ${barber.detail}',
      trailing: IconButton(
        tooltip: 'Editar barbeiro',
        onPressed: onTap,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _CashMovementTile extends StatelessWidget {
  const _CashMovementTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isPositive = value.trim().startsWith('+');
    return _SurfaceTile(
      leading: _IconBadge(
        isPositive ? Icons.south_west_rounded : Icons.north_east_rounded,
      ),
      title: title,
      subtitle: isPositive ? 'Entrada' : 'Saída',
      trailing: Text(
        value,
        style: TextStyle(
          color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.name, required this.quantity});

  final String name;
  final String quantity;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const _IconBadge(Icons.inventory_2_rounded),
      title: name,
      subtitle: 'Reposição recomendada',
      trailing: Text(
        quantity,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const _IconBadge(Icons.insights_rounded),
      title: value,
      subtitle: '$title · $subtitle',
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Row(
        children: [
          _IconBadge(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: SharedAppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onPressed ?? () {},
            style: FilledButton.styleFrom(
              backgroundColor: SharedAppColors.orange,
              foregroundColor: SharedAppColors.onGold,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _SurfaceTile extends StatelessWidget {
  const _SurfaceTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: SharedAppColors.muted),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SharedAppColors.orange.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: SharedAppColors.orange),
    );
  }
}
