class TenantContext {
  const TenantContext({
    required this.barberShopId,
    required this.barberShopName,
    this.role,
  });

  final String barberShopId;
  final String barberShopName;
  final String? role;
}
