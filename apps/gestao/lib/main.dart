import 'dart:convert';

import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/app_mode_navigation.dart';
import 'utils/logo_file.dart';
import 'utils/logo_picker.dart';

String _managementTime(dynamic value, String fallback) {
  final text = value?.toString() ?? '';
  return text.length >= 5 ? text.substring(0, 5) : fallback;
}

int _minutesFromTime(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return 0;
  return (int.tryParse(parts[0]) ?? 0) * 60 +
      (int.tryParse(parts[1]) ?? 0);
}

// A identidade oficial da plataforma e carregada pelos assets da Gestao.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = ManagementSession();
  await session.restoreUnifiedSession();

  runApp(
    ChangeNotifierProvider.value(
      value: session,
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
          if (session.isRestoringSession ||
              (session.isSignedIn && !session.professionalAccessResolved)) {
            return const Scaffold(
              body: CDRLoading.fullScreen(
                message: 'Preparando sua área profissional...',
              ),
            );
          }
          if (!session.isSignedIn) return const ManagementLoginScreen();
          if (!session.hasProfessionalAccess) {
            return const _ProfessionalAccessDeniedScreen();
          }
          return const ManagementHomeScreen();
        },
      ),
    );
  }
}

ThemeData _buildManagementTheme() {
  final base = CDRTheme.dark();
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
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: SharedAppColors.background,
      indicatorColor: SharedAppColors.orange.withOpacity(.14),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? SharedAppColors.orange
              : SharedAppColors.muted,
          fontSize: 10,
          letterSpacing: .1,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? SharedAppColors.orange
              : SharedAppColors.muted,
          size: 23,
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
  });

  final String email;
  final String url;
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
  bool _isShopOwner = false;
  bool _isLinkedBarber = false;
  String? _membershipRole;
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
  bool isAvailabilityLoading = false;
  bool isAvailabilitySaving = false;
  bool isServicesLoading = false;
  bool isCustomersLoading = false;
  bool isSettingsLoading = false;
  String? scheduleError;
  String? availabilityError;
  String? servicesError;
  String? customersError;
  String? settingsError;
  DateTime selectedScheduleDate = DateTime.now();
  String? selectedScheduleBarberId;
  bool scheduleAdminView = false;
  List<BarberAvailabilityDay> weeklyAvailability =
      BarberAvailabilityDay.defaults();
  ServiceStatusFilter serviceStatusFilter = ServiceStatusFilter.all;
  CustomerStatusFilter customerStatusFilter = CustomerStatusFilter.all;
  String? selectedServiceCategoryId;
  String serviceSearchQuery = '';
  String customerSearchQuery = '';

  bool get isSignedIn => _accessToken != null;
  bool get professionalAccessResolved =>
      !isSignedIn || _professionalAccessResolved;
  bool get canWorkAsBarber =>
      _isLinkedBarber || _membershipRole == 'barber';
  bool get canManageShop =>
      _isPlatformAdmin ||
      _isShopOwner ||
      _membershipRole == 'owner' ||
      _membershipRole == 'manager';
  bool get hasProfessionalAccess => canWorkAsBarber || canManageShop;

  bool _professionalAccessResolved = false;

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
      _professionalAccessResolved = false;
      await _loadRestoredManagementData();
    } catch (error) {
      _clearSessionInMemory();
      errorMessage = 'Sua conta não possui acesso profissional ativo.';
    } finally {
      isRestoringSession = false;
      notifyListeners();
    }
  }

  Future<void> _loadRestoredManagementData() async {
    final token = _accessToken;
    if (token == null || token.isEmpty) return;

    try {
      await _resolvePlatformAdmin(token).timeout(const Duration(seconds: 8));
      await _ensureBarberShopId(token).timeout(const Duration(seconds: 8));
      await _resolveShopCapabilities(token).timeout(const Duration(seconds: 8));
      await refreshManagementData();
    } catch (error) {
      errorMessage = _cleanErrorMessage(error);
    } finally {
      _professionalAccessResolved = true;
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

  List<BookingRequest> get currentBarberBookingRequests {
    final barberId = currentBarber?.id;
    if (barberId == null || barberId.isEmpty) return const [];
    return bookingRequests
        .where((request) => request.barberId == barberId)
        .toList();
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
      await _resolveShopCapabilities(_accessToken!);
      if (!hasProfessionalAccess) {
        throw StateError('Sua conta não possui acesso profissional ativo.');
      }
      _professionalAccessResolved = true;
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
    await fetchWeeklyAvailability();
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
      final shopId = await _ensureBarberShopId(token);
      final rows = await _getRestRows(
        token,
        'booking_requests',
        query: {
          'select':
              'id,barber_id,customer_name,customer_phone,requested_date,requested_time,status,total_price,notes,updated_at,barbers(name),services(name)',
          'barber_shop_id': 'eq.$shopId',
          'order': 'created_at.desc',
          'limit': '200',
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

  Future<void> fetchWeeklyAvailability() async {
    final token = _accessToken;
    final barber = currentBarber;
    if (token == null || barber == null) {
      weeklyAvailability = BarberAvailabilityDay.defaults();
      return;
    }

    isAvailabilityLoading = true;
    availabilityError = null;
    notifyListeners();

    try {
      final rows = await _getRestRows(
        token,
        'schedules',
        query: {
          'select': 'weekday,start_time,end_time,slot_minutes,is_active',
          'barber_id': 'eq.${barber.id}',
          'order': 'weekday.asc,start_time.asc',
        },
      );
      final byWeekday = <int, Map<String, dynamic>>{};
      for (final row in rows) {
        final weekday = (row['weekday'] as num?)?.toInt();
        if (weekday != null) byWeekday.putIfAbsent(weekday, () => row);
      }
      weeklyAvailability = [
        for (final fallback in BarberAvailabilityDay.defaults())
          if (byWeekday[fallback.weekday] case final row?)
            BarberAvailabilityDay(
              weekday: fallback.weekday,
              label: fallback.label,
              isActive: row['is_active'] != false,
              startTime: _managementTime(row['start_time'], fallback.startTime),
              endTime: _managementTime(row['end_time'], fallback.endTime),
              slotMinutes:
                  (row['slot_minutes'] as num?)?.toInt() ?? fallback.slotMinutes,
            )
          else
            fallback.copyWith(isActive: false),
      ];
    } catch (error) {
      availabilityError = _cleanErrorMessage(error);
    } finally {
      isAvailabilityLoading = false;
      notifyListeners();
    }
  }

  void updateAvailabilityDay(BarberAvailabilityDay updated) {
    weeklyAvailability = [
      for (final day in weeklyAvailability)
        if (day.weekday == updated.weekday) updated else day,
    ];
    availabilityError = null;
    notifyListeners();
  }

  Future<void> saveWeeklyAvailability() async {
    final token = _accessToken;
    final barber = currentBarber;
    if (token == null || barber == null) {
      throw StateError('Não foi possível identificar o barbeiro.');
    }
    for (final day in weeklyAvailability.where((day) => day.isActive)) {
      if (_minutesFromTime(day.endTime) <= _minutesFromTime(day.startTime)) {
        throw StateError(
          'Em ${day.label}, o horário final deve ser depois do inicial.',
        );
      }
    }

    isAvailabilitySaving = true;
    availabilityError = null;
    notifyListeners();
    try {
      await _postRpc(
        token,
        'replace_barber_weekly_schedule',
        data: {
          'p_barber_id': barber.id,
          'p_days': [
            for (final day in weeklyAvailability)
              {
                'weekday': day.weekday,
                'is_active': day.isActive,
                'start_time': day.startTime,
                'end_time': day.endTime,
                'slot_minutes': day.slotMinutes,
              },
          ],
        },
      );
      await fetchWeeklyAvailability();
    } catch (error) {
      availabilityError = _cleanErrorMessage(error);
      rethrow;
    } finally {
      isAvailabilitySaving = false;
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

  Future<void> saveShopConfiguration(
    ShopConfiguration config, {
    bool applyHoursToTeam = false,
  }) async {
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

      if (applyHoursToTeam) {
        final activeBarbers =
            teamBarbers.where((barber) => barber.isActive).toList();
        for (final barber in activeBarbers) {
          await _postRpc(
            token,
            'replace_barber_weekly_schedule',
            data: {
              'p_barber_id': barber.id,
              'p_days': [
                for (final day in config.days)
                  {
                    'weekday': _weekdayForBusinessDay(day.key),
                    'is_active': day.isOpen,
                    'start_time': day.openTime,
                    'end_time': day.closeTime,
                    'slot_minutes': config.bookingIntervalMinutes,
                  },
              ],
            },
          );
        }
        await fetchWeeklyAvailability();
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

  int _weekdayForBusinessDay(String key) {
    return switch (key) {
      'monday' => 1,
      'tuesday' => 2,
      'wednesday' => 3,
      'thursday' => 4,
      'friday' => 5,
      'saturday' => 6,
      'sunday' => 0,
      _ => throw StateError('Dia de funcionamento inválido: $key'),
    };
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
      final createdRows = await _postRestRows(
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
      final serviceId =
          createdRows.isEmpty ? null : createdRows.first['id']?.toString();
      if (serviceId != null && serviceId.isNotEmpty) {
        for (final barber in teamBarbers.where((item) => item.isActive)) {
          await _postRestRows(
            token,
            'barber_services',
            data: {
              'barber_shop_id': shopId,
              'barber_id': barber.id,
              'service_id': serviceId,
              'is_active': isActive,
            },
          );
        }
      }

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

  Future<TeamInvitationLink> createTeamBarber({
    required String email,
    required String name,
    required String bio,
    required String photoUrl,
    required double startingPrice,
    required double commissionPercent,
  }) async {
    final token = _accessToken;
    if (token == null) {
      throw StateError('Sua sessão expirou. Entre novamente.');
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final shopId = await _ensureBarberShopId(token);
      final result = await _postRpc(
        token,
        'create_shop_invitation',
        data: {
          'p_barber_shop_id': shopId,
          'p_email': email.trim().toLowerCase(),
          'p_name': name.trim(),
          'p_role': 'barber',
          'p_bio': bio.trim().isEmpty ? null : bio.trim(),
          'p_photo_url': photoUrl.trim().isEmpty ? null : photoUrl.trim(),
          'p_starting_price': startingPrice,
          'p_commission_percent': commissionPercent,
        },
      );

      if (result is! Map) {
        throw StateError('O servidor não retornou o convite criado.');
      }
      final invitation = Map<String, dynamic>.from(result);
      final barberId = invitation['barber_id']?.toString() ?? '';
      final rawInviteToken = invitation['token']?.toString() ?? '';
      if (barberId.isEmpty || rawInviteToken.isEmpty) {
        throw StateError('O convite foi criado sem os dados necessários.');
      }

      final rows = await _getRestRows(
        token,
        'barbers',
        query: {
          'select':
              'id,barber_shop_id,user_id,name,bio,photo_url,starting_price,commission_percent,is_active',
          'id': 'eq.$barberId',
          'limit': '1',
        },
      );
      final created = rows.isEmpty ? null : TeamBarber.fromMap(rows.first);
      if (created != null) {
        await _postRpc(
          token,
          'replace_barber_weekly_schedule',
          data: {
            'p_barber_id': created.id,
            'p_days': [
              for (final day in BarberAvailabilityDay.defaults())
                {
                  'weekday': day.weekday,
                  'is_active': day.isActive,
                  'start_time': day.startTime,
                  'end_time': day.endTime,
                  'slot_minutes': day.slotMinutes,
                },
            ],
          },
        );
        for (final service in services.where((item) => item.isActive)) {
          await _postRestRows(
            token,
            'barber_services',
            data: {
              'barber_shop_id': shopId,
              'barber_id': created.id,
              'service_id': service.id,
              'is_active': true,
            },
          );
        }
        teamBarbers = [...teamBarbers, created]
          ..sort((a, b) => a.name.compareTo(b.name));
      } else {
        await fetchTeamBarbers();
      }
      final inviteUri = Uri.base.replace(
        path: '/',
        queryParameters: {'team_invite': rawInviteToken},
        fragment: '',
      );
      return TeamInvitationLink(
        email: invitation['email']?.toString() ?? email.trim().toLowerCase(),
        url: inviteUri.toString(),
      );
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
    _isShopOwner = false;
    _isLinkedBarber = false;
    _membershipRole = null;
    _professionalAccessResolved = false;
    barberShopName = null;
    email = null;
    bookingRequests = [];
    bookingRequestsError = null;
    isBookingRequestsLoading = false;
    scheduleEntries = [];
    scheduleError = null;
    isScheduleLoading = false;
    weeklyAvailability = BarberAvailabilityDay.defaults();
    availabilityError = null;
    isAvailabilityLoading = false;
    isAvailabilitySaving = false;
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

    final linkedBarbers = await _getRestRows(
      token,
      'barbers',
      query: {
        'select': 'barber_shop_id,barber_shops(name)',
        'user_id': 'eq.$userId',
        'is_active': 'eq.true',
        'limit': '1',
      },
    );

    if (linkedBarbers.isNotEmpty) {
      final barber = linkedBarbers.first;
      _barberShopId = barber['barber_shop_id']?.toString();
      final shop = barber['barber_shops'];
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

  Future<void> _resolveShopCapabilities(String token) async {
    final userId = _userId;
    final shopId = _barberShopId;
    if (userId == null ||
        userId.isEmpty ||
        shopId == null ||
        shopId.isEmpty) {
      return;
    }

    final memberships = await _getRestRows(
      token,
      'shop_members',
      query: {
        'select': 'role',
        'barber_shop_id': 'eq.$shopId',
        'user_id': 'eq.$userId',
        'is_active': 'eq.true',
        'limit': '1',
      },
    );
    _membershipRole =
        memberships.isEmpty ? null : memberships.first['role']?.toString();

    final shops = await _getRestRows(
      token,
      'barber_shops',
      query: {
        'select': 'owner_id',
        'id': 'eq.$shopId',
        'limit': '1',
      },
    );
    _isShopOwner =
        shops.isNotEmpty && shops.first['owner_id']?.toString() == userId;

    final barbers = await _getRestRows(
      token,
      'barbers',
      query: {
        'select': 'id',
        'barber_shop_id': 'eq.$shopId',
        'user_id': 'eq.$userId',
        'is_active': 'eq.true',
        'limit': '1',
      },
    );
    _isLinkedBarber = barbers.isNotEmpty;
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

class _ProfessionalAccessDeniedScreen extends StatelessWidget {
  const _ProfessionalAccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const _IconBadge(Icons.lock_person_outlined),
                  const SizedBox(height: 18),
                  Text(
                    'Acesso profissional não encontrado',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Esta conta pode continuar usando o Clube da Régua como cliente. Para acessar a área profissional, ela precisa estar vinculada como barbeiro ou responsável por uma barbearia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SharedAppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CDRButton.primary(
                    label: 'VOLTAR AO MODO CLIENTE',
                    onPressed: openClientMode,
                    leading: const Icon(Icons.search_rounded),
                  ),
                  const SizedBox(height: 10),
                  CDRButton.ghost(
                    label: 'SAIR DA CONTA',
                    onPressed:
                        context.read<ManagementSession>().signOut,
                    leading: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/splash_v3_loading_v3.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB8050505),
                  Color(0xE609090B),
                  Color(0xFA09090B),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                    decoration: BoxDecoration(
                      color: const Color(0xF2111114),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFF34343A)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 36,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: SvgPicture.asset(
                              'assets/images/brand_v3_logo_principal.svg',
                              width: 176,
                              height: 118,
                              fit: BoxFit.contain,
                              semanticsLabel: 'Clube da Régua',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x1AF3B200),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0x73F3B200),
                                ),
                              ),
                              child: const Text(
                                'PORTAL DE GESTÃO',
                                style: TextStyle(
                                  color: SharedAppColors.orange,
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Sua barbearia, sob controle.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: SharedAppColors.text,
                              fontFamily: 'Barlow Condensed',
                              fontSize: 27,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Acesse pedidos, agenda, equipe e toda a operação em um só lugar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: SharedAppColors.muted,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 26),
                          CDRTextField(
                            controller: _emailController,
                            label: 'E-mail profissional',
                            leading: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                          ),
                          const SizedBox(height: 14),
                          CDRPasswordField(
                            controller: _passwordController,
                            onSubmitted: session.isLoading
                                ? null
                                : (_) => session.signIn(
                                      _emailController.text,
                                      _passwordController.text,
                                    ),
                          ),
                          const SizedBox(height: 18),
                          CDRButton.primary(
                            label: 'ENTRAR NO PORTAL',
                            onPressed: session.isLoading
                                ? null
                                : () => session.signIn(
                                      _emailController.text,
                                      _passwordController.text,
                                    ),
                            isLoading: session.isLoading,
                          ),
                          if (session.errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0x1FEF4444),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0x66EF4444),
                                ),
                              ),
                              child: Text(
                                session.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFFA3A3),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 15,
                                color: SharedAppColors.muted,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Acesso seguro para profissionais autorizados',
                                style: TextStyle(
                                  color: SharedAppColors.muted,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
                    CDRPasswordField(
                      controller: _passwordController,
                      label: 'Nova senha',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    CDRPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar nova senha',
                      onSubmitted: _isLoading ? null : (_) => _updatePassword(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  CDRButton.primary(
                    label: _isDone ? 'ENTRAR' : 'SALVAR SENHA',
                    onPressed: _isLoading
                        ? null
                        : _isDone
                            ? () => setState(() => _showLogin = true)
                            : _updatePassword,
                    isLoading: _isLoading,
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
  late ManagementRole selectedRole;
  var selectedTab = 0;

  @override
  void initState() {
    super.initState();
    selectedRole = Uri.base.queryParameters['mode'] == 'owner'
        ? ManagementRole.admin
        : ManagementRole.barber;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ManagementSession>();
    final effectiveRole = switch (selectedRole) {
      ManagementRole.admin when session.canManageShop => ManagementRole.admin,
      ManagementRole.barber when session.canWorkAsBarber =>
        ManagementRole.barber,
      _ when session.canManageShop => ManagementRole.admin,
      _ => ManagementRole.barber,
    };
    final isAdmin = effectiveRole == ManagementRole.admin;
    final tabs = isAdmin ? _adminTabs : _barberTabs;
    final safeTab = selectedTab >= tabs.length ? 0 : selectedTab;
    final page = tabs[safeTab];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSideNavigation = constraints.maxWidth >= 900;
        final extendedNavigation = constraints.maxWidth >= 1280;
        return Scaffold(
          backgroundColor: SharedAppColors.background,
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
                  horizontalPadding: useSideNavigation ? 32 : 16,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child:
                          session.canWorkAsBarber && session.canManageShop
                              ? _RoleSwitch(
                                  selectedRole: effectiveRole,
                                  onChanged: (role) async {
                                    setState(() {
                                      selectedRole = role;
                                      selectedTab = 0;
                                    });
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString(
                                      'clubedaregua.last_mode',
                                      role == ManagementRole.admin
                                          ? 'owner'
                                          : 'barber',
                                    );
                                  },
                                )
                              : _AvailabilityStatus(
                                  label: isAdmin
                                      ? 'MODO DONO'
                                      : 'MODO BARBEIRO',
                                  color: SharedAppColors.orange,
                                ),
                    ),
                    const SizedBox(height: 16),
                    _Header(
                      isAdmin: isAdmin,
                      title: isAdmin
                          ? session.barberShopName ?? 'Barbearia'
                          : session.barberHeaderName,
                    ),
                    const SizedBox(height: 24),
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
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return AppBar(
      toolbarHeight: 68,
      titleSpacing: compact ? 16 : 22,
      backgroundColor: SharedAppColors.background,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: SharedAppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SharedAppColors.stroke),
            ),
            child: SvgPicture.asset(
              'assets/images/brand_v3_segunda_logo.svg',
              fit: BoxFit.contain,
              semanticsLabel: 'Clube da Régua',
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CLUBE DA RÉGUA • GESTÃO',
                  style: TextStyle(
                    color: SharedAppColors.orange,
                    fontSize: 9,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _TopBarAction(
          tooltip: 'Notificações',
          onPressed: () {},
          icon: Icons.notifications_none_rounded,
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
          _TopBarAction(
            tooltip: 'Modo cliente',
            onPressed: openClientMode,
            icon: Icons.swap_horiz_rounded,
          ),
          _TopBarAction(
            tooltip: 'Atualizar',
            onPressed: () =>
                context.read<ManagementSession>().refreshManagementData(),
            icon: Icons.refresh_rounded,
          ),
          _TopBarAction(
            tooltip: 'Sair',
            onPressed: () => context.read<ManagementSession>().signOut(),
            icon: Icons.logout_rounded,
          ),
        ],
        SizedBox(width: compact ? 8 : 14),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: SharedAppColors.stroke),
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: SharedAppColors.card,
          foregroundColor: SharedAppColors.muted,
          side: const BorderSide(color: SharedAppColors.stroke),
          minimumSize: const Size(40, 40),
        ),
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
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          18,
          horizontalPadding,
          36,
        ),
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
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: SharedAppColors.card,
          border: Border(
            right: BorderSide(color: SharedAppColors.stroke),
          ),
        ),
        child: NavigationRail(
          selectedIndex: selectedIndex,
          extended: extended,
          minWidth: 82,
          minExtendedWidth: 220,
          groupAlignment: -.72,
          backgroundColor: SharedAppColors.card,
          indicatorColor: SharedAppColors.orange.withOpacity(.14),
          selectedIconTheme:
              const IconThemeData(color: SharedAppColors.orange),
          unselectedIconTheme:
              const IconThemeData(color: SharedAppColors.muted),
          selectedLabelTextStyle: const TextStyle(
            color: SharedAppColors.text,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelTextStyle:
              const TextStyle(color: SharedAppColors.muted),
          onDestinationSelected: onSelected,
          destinations: [
            for (final tab in tabs)
              NavigationRailDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: Text(tab.label),
              ),
          ],
        ),
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
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: SharedAppColors.background,
          border: Border(
            top: BorderSide(color: SharedAppColors.stroke),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
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
          ),
        ),
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
    child: _BookingRequestsPage(adminView: true),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final expanded = constraints.maxWidth < 520;
        return Container(
          width: expanded ? double.infinity : null,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: SharedAppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SharedAppColors.stroke),
          ),
          child: SegmentedButton<ManagementRole>(
            segments: const [
              ButtonSegment(
                value: ManagementRole.barber,
                label: Text('Barbeiro'),
                icon: Icon(Icons.content_cut_rounded),
              ),
              ButtonSegment(
                value: ManagementRole.admin,
                label: Text('Dono'),
                icon: Icon(Icons.storefront_rounded),
              ),
            ],
            selected: {selectedRole},
            onSelectionChanged: (value) => onChanged(value.first),
            showSelectedIcon: false,
            expandedInsets: expanded ? EdgeInsets.zero : null,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              minimumSize: WidgetStateProperty.all(
                Size(expanded ? 0 : 112, 40),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? SharedAppColors.orange
                    : Colors.transparent,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? SharedAppColors.onGold
                    : SharedAppColors.muted,
              ),
              side: WidgetStateProperty.all(BorderSide.none),
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            selectedIcon: const Icon(Icons.check_rounded),
            multiSelectionEnabled: false,
            emptySelectionAllowed: false,
          ),
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Container(
          padding: EdgeInsets.all(compact ? 18 : 22),
          decoration: BoxDecoration(
            color: SharedAppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SharedAppColors.stroke),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: compact ? 50 : 58,
                height: compact ? 50 : 58,
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
              SizedBox(width: compact ? 14 : 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdmin ? 'VISÃO DA BARBEARIA' : 'MINHA OPERAÇÃO',
                      style: const TextStyle(
                        color: SharedAppColors.orange,
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: compact
                          ? Theme.of(context).textTheme.headlineSmall
                          : Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isAdmin
                          ? 'Equipe, serviços, caixa e desempenho em um só lugar.'
                          : 'Pedidos, agenda, horários e comissão do seu dia.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                  'Agendamentos',
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
            const SizedBox(height: 28),
            _SectionTitle(
              'Horários do dia',
              eyebrow: 'AGENDA',
              trailing: _selectedDateLabel(session.selectedScheduleDate),
            ),
            const SizedBox(height: 12),
            if (session.isScheduleLoading) ...[
              const CDRLoading.section(height: 88),
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

  String _selectedDateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _showScheduleDetails(BuildContext context, ScheduleEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DETALHES DO ATENDIMENTO',
                  style: TextStyle(
                    color: SharedAppColors.orange,
                    fontSize: 10,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.client,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 6),
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
                  CDRButton.primary(
                    label: 'CONCLUIR ATENDIMENTO',
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
                    leading: const Icon(Icons.task_alt_rounded),
                  ),
                ],
              ],
            ),
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

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SharedAppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SharedAppColors.stroke),
          ),
          child: Column(
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
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final selected = DateUtils.isSameDay(day, date);
                    return ChoiceChip(
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _weekdayLabel(day),
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(height: 2),
                          Text(_dayLabel(day)),
                        ],
                      ),
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
          ),
        );
      },
    );
  }

  String _dayLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _weekdayLabel(DateTime date) {
    const labels = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
    return labels[date.weekday - 1];
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
  const _BookingRequestsPage({this.adminView = false});

  final bool adminView;

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final requests = adminView
            ? session.bookingRequests
            : session.currentBarberBookingRequests;
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
            const SizedBox(height: 28),
            _SectionTitle(
              newCount > 0 ? 'Novas solicitações' : 'Solicitações',
              eyebrow: 'PEDIDOS',
              trailing: requests.isEmpty
                  ? null
                  : '${requests.length} no total',
            ),
            const SizedBox(height: 12),
            if (session.isBookingRequestsLoading) ...[
              const CDRLoading.section(height: 88),
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
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final activeDays =
            session.weeklyAvailability.where((day) => day.isActive).length;
        final activeServices =
            session.services.where((service) => service.isActive).length;
        final barber = session.currentBarber;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsGrid(
              cards: [
                _MetricData(
                  'Dias ativos',
                  '$activeDays',
                  Icons.event_available_rounded,
                ),
                _MetricData(
                  'Serviços ativos',
                  '$activeServices',
                  Icons.content_cut_rounded,
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (barber == null)
              const _InlineNotice(
                icon: Icons.person_off_outlined,
                title: 'Perfil de barbeiro não encontrado',
                subtitle:
                    'Cadastre ou vincule seu perfil profissional antes de configurar a agenda.',
              )
            else ...[
              if (activeServices == 0) ...[
                const _InlineNotice(
                  icon: Icons.info_outline_rounded,
                  title: 'Falta cadastrar um serviço',
                  subtitle:
                      'A agenda só aparece para o cliente quando existe ao menos um serviço ativo. Acesse o modo Dono e abra Serviços.',
                ),
                const SizedBox(height: 18),
              ],
              _SectionTitle(
                'Jornada de ${barber.name}',
                eyebrow: 'DISPONIBILIDADE SEMANAL',
                trailing: '$activeDays dias ativos',
              ),
              const SizedBox(height: 12),
              if (session.isAvailabilityLoading)
                const CDRLoading.section(height: 116)
              else if (session.availabilityError != null)
                _InlineNotice(
                  icon: Icons.warning_amber_rounded,
                  title: 'Não foi possível carregar os horários',
                  subtitle: session.availabilityError!,
                )
              else
                for (final day in session.weeklyAvailability)
                  _AvailabilityDayTile(
                    day: day,
                    enabled: !session.isAvailabilitySaving,
                    onChanged: session.updateAvailabilityDay,
                    onPickTime: (isStart) =>
                        _pickTime(context, session, day, isStart),
                  ),
              const SizedBox(height: 12),
              CDRButton.primary(
                label: 'SALVAR HORÁRIOS',
                leading: const Icon(Icons.save_outlined),
                isLoading: session.isAvailabilitySaving,
                onPressed: session.isAvailabilityLoading ||
                        session.isAvailabilitySaving
                    ? null
                    : () => _save(context, session),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 17,
                    color: SharedAppColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Os horários disponíveis consideram a duração do serviço, bloqueios e agendamentos confirmados.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    ManagementSession session,
    BarberAvailabilityDay day,
    bool isStart,
  ) async {
    final current = isStart ? day.startTime : day.endTime;
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 9,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
      helpText: isStart ? 'HORÁRIO DE INÍCIO' : 'HORÁRIO DE TÉRMINO',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
    );
    if (picked == null) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    session.updateAvailabilityDay(
      isStart ? day.copyWith(startTime: value) : day.copyWith(endTime: value),
    );
  }

  Future<void> _save(
    BuildContext context,
    ManagementSession session,
  ) async {
    try {
      await session.saveWeeklyAvailability();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horários atualizados com sucesso.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(session.availabilityError ?? error.toString())),
      );
    }
  }
}

class _AvailabilityDayTile extends StatelessWidget {
  const _AvailabilityDayTile({
    required this.day,
    required this.enabled,
    required this.onChanged,
    required this.onPickTime,
  });

  final BarberAvailabilityDay day;
  final bool enabled;
  final ValueChanged<BarberAvailabilityDay> onChanged;
  final ValueChanged<bool> onPickTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: day.isActive
              ? SharedAppColors.orange.withOpacity(.32)
              : SharedAppColors.stroke,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final times = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimeButton(
                label: day.startTime,
                enabled: enabled && day.isActive,
                onPressed: () => onPickTime(true),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('até',
                    style: TextStyle(color: SharedAppColors.muted)),
              ),
              _TimeButton(
                label: day.endTime,
                enabled: enabled && day.isActive,
                onPressed: () => onPickTime(false),
              ),
            ],
          );
          final heading = Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: day.isActive
                      ? SharedAppColors.orange.withOpacity(.12)
                      : SharedAppColors.elevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  day.isActive
                      ? Icons.event_available_outlined
                      : Icons.event_busy_outlined,
                  size: 19,
                  color: day.isActive
                      ? SharedAppColors.orange
                      : SharedAppColors.muted,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      day.isActive ? 'Atendimento ativo' : 'Dia fechado',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: day.isActive,
                activeColor: SharedAppColors.orange,
                onChanged: enabled
                    ? (value) => onChanged(day.copyWith(isActive: value))
                    : null,
              ),
            ],
          );
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, const SizedBox(height: 8), times],
                )
              : Row(
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 18),
                    times,
                  ],
                );
        },
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.schedule_rounded, size: 18),
      label: Text(label),
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
        final recentCount =
            session.customers.where((customer) => customer.isRecent).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsGrid(
              cards: [
                _MetricData(
                  'Clientes ativos',
                  '$activeCount',
                  Icons.people_alt_outlined,
                ),
                _MetricData(
                  'Novos em 30 dias',
                  '$recentCount',
                  Icons.person_add_alt_rounded,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle(
              'Encontre rapidamente',
              eyebrow: 'CLIENTES',
            ),
            const SizedBox(height: 12),
            _CustomerFilters(session: session),
            const SizedBox(height: 24),
            _SectionTitle(
              'Base de clientes',
              eyebrow: 'RELACIONAMENTO',
              trailing: '${customers.length} clientes',
            ),
            const SizedBox(height: 12),
            if (session.isCustomersLoading) ...[
              const CDRLoading.section(height: 88),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: session.setCustomerSearchQuery,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Buscar por nome ou telefone',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChipButton(
                  label: 'Todos',
                  selected:
                      session.customerStatusFilter == CustomerStatusFilter.all,
                  onSelected: () => session
                      .setCustomerStatusFilter(CustomerStatusFilter.all),
                ),
                _FilterChipButton(
                  label: 'Ativos',
                  selected: session.customerStatusFilter ==
                      CustomerStatusFilter.active,
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
                  selected: session.customerStatusFilter ==
                      CustomerStatusFilter.recent,
                  onSelected: () => session
                      .setCustomerStatusFilter(CustomerStatusFilter.recent),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PERFIL DO CLIENTE',
                        style: TextStyle(
                          color: SharedAppColors.orange,
                          fontSize: 10,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        customer.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
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
            const SizedBox(height: 20),
            const Divider(height: 1),
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
              label: 'E-mail',
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
              subtitle: const Text('Clientes inativos ficam filtráveis.'),
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
              CDRButton.primary(
                label: 'SALVAR ALTERAÇÕES',
                onPressed: _isSaving ? null : () => _save(customer),
                isLoading: _isSaving,
                leading: const Icon(Icons.save_outlined),
              ),
            const SizedBox(height: 28),
            _SectionTitle(
              'Histórico de agendamentos',
              eyebrow: 'ATENDIMENTOS',
              trailing: '${appointments.length} registros',
            ),
            const SizedBox(height: 12),
            if (appointments.isEmpty)
              const _InlineNotice(
                icon: Icons.event_busy_rounded,
                title: 'Sem histórico',
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
    final normalizedStatus = appointment.status.toLowerCase();
    final statusColor = normalizedStatus.contains('conclu')
        ? CDRColorTokens.success
        : normalizedStatus.contains('cancel')
            ? CDRColorTokens.error
            : SharedAppColors.orange;
    return _SurfaceTile(
      leading: const _IconBadge(Icons.event_available_rounded),
      title: appointment.service,
      subtitle: '${appointment.barber} - ${appointment.dateLabel}',
      trailing: _AvailabilityStatus(
        label: appointment.status.toUpperCase(),
        color: statusColor,
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
            _MetricData(
              'Produção na semana',
              'R\$ 1.780',
              Icons.trending_up_rounded,
            ),
            _MetricData(
              'Comissão estimada',
              'R\$ 712',
              Icons.account_balance_wallet_rounded,
            ),
          ],
        ),
        SizedBox(height: 14),
        _InlineNotice(
          icon: Icons.science_outlined,
          title: 'Prévia financeira',
          subtitle:
              'Valores ilustrativos enquanto a movimentação financeira real não está ativa.',
        ),
        SizedBox(height: 24),
        _SectionTitle(
          'Desempenho da semana',
          eyebrow: 'COMISSÃO',
          trailing: 'Período atual',
        ),
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
        SizedBox(height: 28),
        _SectionTitle(
          'Resumo financeiro',
          eyebrow: 'FATURAMENTO',
          trailing: 'Estimativa',
        ),
        SizedBox(height: 12),
        _CommissionBreakdown(),
      ],
    );
  }
}

class _CommissionBreakdown extends StatelessWidget {
  const _CommissionBreakdown();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: const Column(
        children: [
          _FinancialLine(label: 'Produção bruta', value: 'R\$ 1.780,00'),
          Divider(height: 28),
          _FinancialLine(
            label: 'Comissão estimada (40%)',
            value: 'R\$ 712,00',
            emphasized: true,
          ),
          Divider(height: 28),
          _FinancialLine(
            label: 'Repasse da barbearia',
            value: 'R\$ 1.068,00',
          ),
        ],
      ),
    );
  }
}

class _FinancialLine extends StatelessWidget {
  const _FinancialLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized
                  ? SharedAppColors.text
                  : SharedAppColors.muted,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          style: TextStyle(
            color: emphasized
                ? SharedAppColors.orange
                : SharedAppColors.text,
            fontSize: emphasized ? 18 : 15,
            fontWeight: FontWeight.w900,
          ),
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
            _MetricData(
              'Faturamento estimado',
              'R\$ 4.820',
              Icons.trending_up_rounded,
            ),
            _MetricData(
              'Agendamentos na semana',
              '46',
              Icons.event_available_rounded,
            ),
          ],
        ),
        SizedBox(height: 14),
        _InlineNotice(
          icon: Icons.science_outlined,
          title: 'Painel em evolução',
          subtitle:
              'Os indicadores financeiros serão substituídos por dados reais após a integração.',
        ),
        SizedBox(height: 24),
        _SectionTitle(
          'Indicadores operacionais',
          eyebrow: 'VISÃO GERAL',
          trailing: 'Semana atual',
        ),
        SizedBox(height: 12),
        _DashboardInsightsGrid(
          cards: [
            _DashboardInsightData(
              icon: Icons.workspace_premium_outlined,
              label: 'Barbeiro destaque',
              value: 'Equipe ativa',
              detail: '18 atendimentos nesta semana',
            ),
            _DashboardInsightData(
              icon: Icons.content_cut_rounded,
              label: 'Serviço mais vendido',
              value: 'Corte + barba',
              detail: '34% dos agendamentos',
            ),
            _DashboardInsightData(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Caixa do dia',
              value: 'R\$ 1.240',
              detail: 'PIX, dinheiro e cartão',
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardInsightData {
  const _DashboardInsightData({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
}

class _DashboardInsightsGrid extends StatelessWidget {
  const _DashboardInsightsGrid({required this.cards});

  final List<_DashboardInsightData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 540
                ? 2
                : 1;
        final width =
            (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: _DashboardInsightCard(data: card),
              ),
          ],
        );
      },
    );
  }
}

class _DashboardInsightCard extends StatelessWidget {
  const _DashboardInsightCard({required this.data});

  final _DashboardInsightData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 164),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(data.icon),
          const SizedBox(height: 14),
          Text(
            data.label.toUpperCase(),
            style: const TextStyle(
              color: SharedAppColors.muted,
              fontSize: 10,
              letterSpacing: .8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(data.value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(data.detail, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
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
              subtitle: activeCount == 1
                  ? '1 serviço ativo. Gerencie preço, duração e disponibilidade.'
                  : '$activeCount serviços ativos. Gerencie preços, durações e disponibilidade.',
              buttonLabel: 'Novo serviço',
              icon: Icons.add_circle_rounded,
              onPressed: () => _openServiceForm(context),
            ),
            const SizedBox(height: 22),
            const _SectionTitle(
              'Encontre e organize',
              eyebrow: 'SERVIÇOS',
            ),
            const SizedBox(height: 12),
            _ServiceFilters(session: session),
            const SizedBox(height: 24),
            _SectionTitle(
              'Serviços cadastrados',
              eyebrow: 'CATÁLOGO',
              trailing: services.length == 1
                  ? '1 serviço'
                  : '${services.length} serviços',
            ),
            const SizedBox(height: 12),
            if (session.isServicesLoading) ...[
              const CDRLoading.section(height: 88),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: session.setServiceSearchQuery,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Buscar serviço por nome',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
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
                  onSelected: () => session
                      .setServiceStatusFilter(ServiceStatusFilter.active),
                ),
                _FilterChipButton(
                  label: 'Inativos',
                  selected: session.serviceStatusFilter ==
                      ServiceStatusFilter.inactive,
                  onSelected: () => session
                      .setServiceStatusFilter(ServiceStatusFilter.inactive),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _validCategoryFilterValue(session),
            decoration: const InputDecoration(
              labelText: 'Categoria',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: _allCategoriesDropdownValue,
                child: Text('Todas as categorias'),
              ),
              for (final category
                  in _uniqueCategories(session.serviceCategories))
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
      ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'EDITAR SERVIÇO' : 'NOVO SERVIÇO',
                        style: const TextStyle(
                          color: SharedAppColors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isEditing
                            ? 'Atualize o serviço'
                            : 'Cadastre um serviço',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: SharedAppColors.stroke),
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
                labelText: 'Descrição',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            _ResponsiveFieldRow(
              children: [
                TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Preço',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: _validatePrice,
                  ),
                TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duração (min)',
                      prefixIcon: Icon(Icons.schedule_rounded),
                    ),
                    validator: _validateDuration,
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
                labelText: 'Cor de identificação',
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
            CDRButton.primary(
              label: _isEditing ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR SERVIÇO',
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
              leading: const Icon(Icons.save_outlined),
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
      return 'Informe um preço maior que zero.';
    }
    return null;
  }

  String? _validateDuration(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Informe a duração.';
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
        final pendingCount = session.teamBarbers
            .where((barber) => barber.userId.isEmpty)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsGrid(
              cards: [
                _MetricData(
                  'Profissionais ativos',
                  '$activeCount',
                  Icons.groups_2_outlined,
                ),
                _MetricData(
                  'Convites pendentes',
                  '$pendingCount',
                  Icons.mark_email_unread_outlined,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ActionPanel(
              title: 'Equipe da unidade',
              subtitle:
                  '$activeCount barbeiro(s) ativo(s). Gerencie percentuais e agenda.',
              buttonLabel: 'Novo barbeiro',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () => _openTeamBarberForm(context),
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              'Profissionais cadastrados',
              eyebrow: 'EQUIPE',
              trailing: '${session.teamBarbers.length} no total',
            ),
            const SizedBox(height: 12),
            if (session.isLoading) ...[
              const CDRLoading.section(height: 88),
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
  late final TextEditingController _emailController;
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
    _emailController = TextEditingController();
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
    _emailController.dispose();
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
            if (!_isEditing) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'E-mail de acesso',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                  helperText:
                      'O convite será válido somente para este e-mail.',
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(email)) {
                    return 'Informe um e-mail válido.';
                  }
                  return null;
                },
              ),
            ],
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
            _ResponsiveFieldRow(
              children: [
                TextFormField(
                    controller: _startingPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Preço inicial',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: _validateMoney,
                  ),
                TextFormField(
                    controller: _commissionController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Comissão %',
                      prefixIcon: Icon(Icons.percent),
                    ),
                    validator: _validateCommission,
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
            CDRButton.primary(
              onPressed: _isSaving ? null : _save,
              label: 'SALVAR PROFISSIONAL',
              isLoading: _isSaving,
              leading: const Icon(Icons.save_outlined),
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
        final invitation = await session.createTeamBarber(
          email: _emailController.text,
          name: _nameController.text,
          bio: _bioController.text,
          photoUrl: _photoUrlController.text,
          startingPrice: _parseNumber(_startingPriceController.text)!,
          commissionPercent: _parseNumber(_commissionController.text)!,
        );
        if (!mounted) return;
        await _showInvitationCreated(invitation);
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

  Future<void> _showInvitationCreated(TeamInvitationLink invitation) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.mark_email_read_outlined,
          color: SharedAppColors.orange,
          size: 34,
        ),
        title: const Text('Convite criado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envie este link para ${invitation.email}. '
              'O profissional deverá entrar ou criar a conta usando esse mesmo e-mail.',
            ),
            const SizedBox(height: 14),
            SelectableText(
              invitation.url,
              style: const TextStyle(
                color: SharedAppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Concluir'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: invitation.url));
              if (!dialogContext.mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Link do convite copiado.')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copiar link'),
          ),
        ],
      ),
    );
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
              const CDRLoading.section(height: 88),
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
  var _applyHoursToTeam = false;
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
          const _SectionTitle(
            'Informações gerais',
            eyebrow: 'PERFIL DA BARBEARIA',
          ),
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
                        ? const CDRLoading.compact(size: 22)
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
                        ? const CDRLoading.compact(size: 22)
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
              _ResponsiveFieldRow(
                children: [
                  TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  TextFormField(
                      controller: _whatsappController,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp',
                        prefixIcon: Icon(Icons.chat_outlined),
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
              _ResponsiveFieldRow(
                children: [
                  TextFormField(
                      controller: _zipController,
                      decoration: const InputDecoration(labelText: 'CEP'),
                    ),
                  TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                    ),
                  TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'UF'),
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
          const _SectionTitle(
            'Horário de funcionamento',
            eyebrow: 'OPERAÇÃO',
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              for (var index = 0; index < _days.length; index++)
                _BusinessDayEditor(
                  day: _days[index],
                  onChanged: (day) => setState(() => _days[index] = day),
                ),
              const Divider(color: SharedAppColors.stroke, height: 28),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _applyHoursToTeam,
                activeColor: SharedAppColors.orange,
                title: const Text(
                  'Aplicar à agenda dos profissionais',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Substitui a disponibilidade semanal dos barbeiros ativos pelos horários acima.',
                ),
                onChanged: (value) =>
                    setState(() => _applyHoursToTeam = value),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            'Intervalo',
            eyebrow: 'PAUSAS',
          ),
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
              _ResponsiveFieldRow(
                children: [
                  TextFormField(
                      enabled: _lunchEnabled,
                      controller: _lunchStartController,
                      decoration: const InputDecoration(labelText: 'Início'),
                      validator: _validateTime,
                    ),
                  TextFormField(
                      enabled: _lunchEnabled,
                      controller: _lunchEndController,
                      decoration: const InputDecoration(labelText: 'Fim'),
                      validator: _validateTime,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            'Configuração de agendamento',
            eyebrow: 'REGRAS DA AGENDA',
          ),
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
          CDRButton.primary(
            onPressed: _isSaving ? null : _save,
            label: 'SALVAR CONFIGURAÇÕES',
            isLoading: _isSaving,
            leading: const Icon(Icons.save_outlined),
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
      await context.read<ManagementSession>().saveShopConfiguration(
            config,
            applyHoursToTeam: _applyHoursToTeam,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _applyHoursToTeam
                ? 'Configurações e agendas da equipe atualizadas.'
                : 'Configurações salvas com sucesso.',
          ),
        ),
      );
      setState(() => _applyHoursToTeam = false);
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

class _ResponsiveFieldRow extends StatelessWidget {
  const _ResponsiveFieldRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 560;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index < children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
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
        SizedBox(height: 14),
        _InlineNotice(
          icon: Icons.science_outlined,
          title: 'Prévia do caixa',
          subtitle:
              'Movimentos ilustrativos enquanto a integração financeira não está ativa.',
        ),
        SizedBox(height: 24),
        _SectionTitle(
          'Movimentos de caixa',
          eyebrow: 'FINANCEIRO',
          trailing: 'Hoje',
        ),
        SizedBox(height: 12),
        _CashMovementTile(title: 'PIX - Marcos Lima', value: '+ R\$ 85'),
        _CashMovementTile(title: 'Dinheiro - João Pedro', value: '+ R\$ 55'),
        _CashMovementTile(title: 'Compra de pomada', value: '- R\$ 180'),
        SizedBox(height: 24),
        _SectionTitle(
          'Estoque crítico',
          eyebrow: 'PRODUTOS',
          trailing: '2 alertas',
        ),
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
              : cards.length == 1
                  ? 1
                  : 2;
          final width =
              (constraints.maxWidth - ((columns - 1) * 10)) / columns;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
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
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SharedAppColors.orange.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: SharedAppColors.orange, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 3),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.eyebrow, this.trailing});

  final String title;
  final String? eyebrow;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!,
                  style: const TextStyle(
                    color: SharedAppColors.orange,
                    fontSize: 9,
                    letterSpacing: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: SharedAppColors.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: SharedAppColors.stroke),
            ),
            child: Text(
              trailing!,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
      ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Row(
        children: [
          _IconBadge(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
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
    final normalizedStatus = entry.status.toLowerCase();
    final statusColor = normalizedStatus.contains('conclu')
        ? CDRColorTokens.success
        : normalizedStatus.contains('cancel')
            ? CDRColorTokens.error
            : normalizedStatus.contains('confirm') ||
                    normalizedStatus.contains('aceito')
                ? CDRColorTokens.info
                : SharedAppColors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _TimeBadge(entry.time),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.client,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry.service,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (showBarber) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 14,
                            color: SharedAppColors.muted,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              entry.barber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 104),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      entry.status.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        letterSpacing: .3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: SharedAppColors.muted,
                  ),
                ],
              ),
            ],
          ),
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
      'contacted' => CDRColorTokens.info,
      'converted' => CDRColorTokens.success,
      'cancelled' => CDRColorTokens.error,
      _ => SharedAppColors.orange,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 2,
            color: isClosed ? SharedAppColors.stroke : statusColor,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ClientAvatar(photoUrl: request.clientPhotoUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.client,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.phone.isEmpty
                                ? 'Telefone não informado'
                                : request.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(total, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              letterSpacing: .4,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 6),
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
                if (!isClosed) ...[
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 430;
                      final decline = CDRButton.outlined(
                        label: 'RECUSAR',
                        onPressed: onDeclined,
                        isExpanded: compact,
                        leading: const Icon(Icons.block_rounded),
                      );
                      final accept = CDRButton.primary(
                        label: 'ACEITAR',
                        onPressed: onAccepted,
                        isExpanded: compact,
                        leading: const Icon(Icons.check_rounded),
                      );
                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            accept,
                            const SizedBox(height: 10),
                            decline,
                            const SizedBox(height: 4),
                            TextButton.icon(
                              onPressed: onCancelled,
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('Cancelar solicitação'),
                            ),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: onCancelled,
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          decline,
                          const SizedBox(width: 10),
                          accept,
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
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
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SharedAppColors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SharedAppColors.orange.withOpacity(.22),
        ),
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
      trailing: const _AvailabilityStatus(
        label: 'ABERTO',
        color: CDRColorTokens.success,
      ),
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
      trailing: const _AvailabilityStatus(
        label: 'BLOQUEADO',
        color: CDRColorTokens.error,
      ),
    );
  }
}

class _AvailabilityStatus extends StatelessWidget {
  const _AvailabilityStatus({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9,
          letterSpacing: .4,
          fontWeight: FontWeight.w900,
        ),
      ),
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
        customer.isActive ? CDRColorTokens.success : CDRColorTokens.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              _CustomerAvatar(customer: customer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      customer.phone.isEmpty
                          ? 'Telefone não informado'
                          : customer.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Último atendimento: ${customer.lastAppointmentLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AvailabilityStatus(
                    label: customer.appointmentCount == 1
                        ? '1 ATENDIMENTO'
                        : '${customer.appointmentCount} ATEND.',
                    color: SharedAppColors.orange,
                  ),
                  const SizedBox(height: 6),
                  _AvailabilityStatus(
                    label: customer.statusLabel.toUpperCase(),
                    color: statusColor,
                  ),
                ],
              ),
            ],
          ),
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
        service.isActive ? CDRColorTokens.success : CDRColorTokens.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SharedAppColors.stroke),
            ),
            child: Row(
              children: [
                service.imageUrl.isEmpty
                    ? const _IconBadge(Icons.content_cut_rounded)
                    : CircleAvatar(
                        radius: 27,
                        backgroundColor:
                            SharedAppColors.orange.withOpacity(0.12),
                        backgroundImage: NetworkImage(service.imageUrl),
                      ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${service.categoryName} • ${service.durationLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      _AvailabilityStatus(
                        label: service.statusLabel.toUpperCase(),
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      service.formattedPrice,
                      style: const TextStyle(
                        color: SharedAppColors.orange,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.appointmentCount == 1
                          ? '1 agendamento'
                          : '${service.appointmentCount} agendamentos',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: SharedAppColors.muted,
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          color:
              isPositive ? CDRColorTokens.success : CDRColorTokens.error,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final content = Row(
          children: [
            _IconBadge(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        );

        final action = onPressed == null
            ? const _AvailabilityStatus(
                label: 'EM BREVE',
                color: SharedAppColors.muted,
              )
            : CDRButton.primary(
                label: buttonLabel.toUpperCase(),
                onPressed: onPressed,
                isExpanded: compact,
              );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SharedAppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SharedAppColors.stroke),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    content,
                    const SizedBox(height: 16),
                    action,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 16),
                    action,
                  ],
                ),
        );
      },
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
        borderRadius: BorderRadius.circular(18),
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
                Text(title, style: Theme.of(context).textTheme.titleSmall),
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
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SharedAppColors.orange.withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: SharedAppColors.orange, size: 21),
    );
  }
}
