import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../providers/app_state.dart';
import '../../repositories/barber_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/service_card.dart';
import 'barber_details_screen.dart';

class BarbershopProfileScreen extends StatelessWidget {
  const BarbershopProfileScreen({super.key});

  static const route = '/barbershop-profile';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final shop = state.selectedBarbershop;
        if (shop == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
          );
        }

        final coverUrl = shop.identity.coverUrl.isEmpty
            ? AppConstants.promoBarber
            : shop.identity.coverUrl;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.text,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(coverUrl, fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black45, AppColors.background],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileHeader(shop: shop),
                      const SizedBox(height: 22),
                      _PrimaryScheduleButton(shop: shop),
                      const SizedBox(height: 26),
                      _InfoGrid(shop: shop),
                      const SizedBox(height: 26),
                      const _SectionTitle('Sobre'),
                      const SizedBox(height: 10),
                      Text(
                        'Barbearia parceira do Clube da Régua, com atendimento por horário marcado, profissionais verificados e experiência premium.',
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle('Serviços'),
                      const SizedBox(height: 12),
                      ...shop.services.map(
                        (service) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ServiceCard(
                            service: service,
                            isSelected: state.selectedService?.id == service.id,
                            onTap: () => state.selectService(service),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _SectionTitle('Profissionais'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 132,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: shop.barbers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final barber = shop.barbers[index];
                            return _ProfessionalCard(
                              name: barber.name,
                              imageUrl: barber.imageUrl,
                              rating: barber.rating,
                              selected: state.selectedBarber?.id == barber.id,
                              onTap: () => state.selectBarber(barber),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle('Fotos'),
                      const SizedBox(height: 12),
                      _PhotoStrip(shop: shop),
                      const SizedBox(height: 26),
                      const _SectionTitle('Redes sociais'),
                      const SizedBox(height: 12),
                      _SocialAndRoute(shop: shop),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.shop});

  final PublicBarbershop shop;

  @override
  Widget build(BuildContext context) {
    final logoUrl = shop.identity.logoUrl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 78,
            height: 78,
            color: AppColors.card,
            child: logoUrl.isEmpty
                ? Image.asset(AppConstants.brandIconCr, fit: BoxFit.cover)
                : Image.network(logoUrl, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shop.identity.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    icon: Icons.star_rounded,
                    text: '${shop.rating} • ${shop.reviewCount} avaliações',
                  ),
                  _MetaChip(
                    icon: Icons.place_outlined,
                    text: shop.distanceLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryScheduleButton extends StatelessWidget {
  const _PrimaryScheduleButton({required this.shop});

  final PublicBarbershop shop;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: shop.services.isEmpty || shop.barbers.isEmpty
          ? null
          : () {
              final state = context.read<AppState>();
              state.selectService(shop.services.first);
              state.selectBarber(shop.barbers.first);
              Navigator.pushNamed(context, BarberDetailsScreen.route);
            },
      icon: const Icon(Icons.calendar_month_rounded),
      label: const Text('Ver horários disponíveis'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.onGold,
        minimumSize: const Size.fromHeight(56),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.shop});

  final PublicBarbershop shop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.schedule_rounded,
            title: shop.statusLabel,
            subtitle: 'Hoje • ${shop.nextSlot}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.payments_outlined,
            title: shop.priceRange,
            subtitle: 'Faixa de preço',
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.orange),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String imageUrl;
  final double rating;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 138,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.orange : AppColors.stroke,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
              backgroundColor: AppColors.dark,
              child: imageUrl.isEmpty
                  ? const Icon(Icons.person_rounded, color: AppColors.orange)
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? AppColors.onGold : AppColors.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$rating ★',
              style: TextStyle(
                color: selected ? AppColors.onGold : AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.shop});

  final PublicBarbershop shop;

  @override
  Widget build(BuildContext context) {
    final images = [
      shop.identity.coverUrl.isEmpty
          ? AppConstants.promoBarber
          : shop.identity.coverUrl,
      AppConstants.heroBarbershop,
      AppConstants.promoBarber,
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(images[index], fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}

class _SocialAndRoute extends StatelessWidget {
  const _SocialAndRoute({required this.shop});

  final PublicBarbershop shop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.alternate_email_rounded,
          title: shop.identity.instagram.isEmpty
              ? 'Instagram não informado'
              : shop.identity.instagram,
          subtitle: 'Rede social da barbearia',
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.directions_rounded,
          title: 'Como chegar',
          subtitle: shop.identity.address.isEmpty
              ? shop.identity.locationLabel
              : shop.identity.address,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.orange, size: 16),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
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
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
