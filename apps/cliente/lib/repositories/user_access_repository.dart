import '../services/auth_service.dart';
import '../services/supabase_rest_service.dart';

class UserAccess {
  const UserAccess({
    required this.professionalRoles,
    required this.shopIds,
  });

  const UserAccess.client()
      : professionalRoles = const <String>{},
        shopIds = const <String>{};

  final Set<String> professionalRoles;
  final Set<String> shopIds;

  bool get hasBarberAccess => professionalRoles.contains('barber');

  bool get hasOwnerAccess => professionalRoles.any(
        (role) => const {'owner', 'manager', 'admin'}.contains(role),
      );

  bool get hasProfessionalAccess =>
      hasBarberAccess || hasOwnerAccess;
}

class UserAccessRepository {
  const UserAccessRepository({SupabaseRestService? rest})
      : _rest = rest ?? const SupabaseRestService();

  final SupabaseRestService _rest;

  Future<UserAccess> fetchAccess() async {
    if (!_rest.isConfigured) return const UserAccess.client();
    final auth = AuthService();
    final session = await auth.getValidSession();
    if (session == null) return const UserAccess.client();

    List<Map<String, dynamic>> memberships = const [];
    List<Map<String, dynamic>> ownedShops = const [];
    List<Map<String, dynamic>> linkedBarbers = const [];
    List<Map<String, dynamic>> users = const [];
    try {
      memberships = await _rest.getRows(
        'shop_members',
        select: 'barber_shop_id,role',
        filters: {
          'user_id': 'eq.${session.user.id}',
          'is_active': 'eq.true',
        },
        accessToken: session.accessToken,
      );
    } catch (_) {}
    try {
      linkedBarbers = await _rest.getRows(
        'barbers',
        select: 'barber_shop_id',
        filters: {
          'user_id': 'eq.${session.user.id}',
          'is_active': 'eq.true',
        },
        accessToken: session.accessToken,
      );
    } catch (_) {}
    try {
      ownedShops = await _rest.getRows(
        'barber_shops',
        select: 'id',
        filters: {
          'owner_id': 'eq.${session.user.id}',
          'is_active': 'eq.true',
        },
        accessToken: session.accessToken,
      );
    } catch (_) {}
    try {
      users = await _rest.getRows(
        'users',
        select: 'role',
        filters: {'id': 'eq.${session.user.id}'},
        accessToken: session.accessToken,
      );
    } catch (_) {}

    final roles = <String>{
      for (final row in memberships)
        if (row['role']?.toString().isNotEmpty == true) row['role'].toString(),
      if (ownedShops.isNotEmpty) 'owner',
      if (linkedBarbers.isNotEmpty) 'barber',
      for (final row in users)
        if (row['role']?.toString() == 'admin') 'admin',
    };
    final shopIds = <String>{
      for (final row in memberships)
        if (row['barber_shop_id']?.toString().isNotEmpty == true)
          row['barber_shop_id'].toString(),
      for (final row in ownedShops)
        if (row['id']?.toString().isNotEmpty == true) row['id'].toString(),
      for (final row in linkedBarbers)
        if (row['barber_shop_id']?.toString().isNotEmpty == true)
          row['barber_shop_id'].toString(),
    };
    return UserAccess(professionalRoles: roles, shopIds: shopIds);
  }
}
