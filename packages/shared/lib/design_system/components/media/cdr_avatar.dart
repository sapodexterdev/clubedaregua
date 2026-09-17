import 'package:flutter/material.dart';

import '../../tokens/cdr_design_tokens.dart';

class CDRAvatar extends StatelessWidget {
  const CDRAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.imageProvider,
    this.size = 48,
    this.semanticLabel,
    this.fallbackIcon = Icons.person_outline_rounded,
    this.excludeFromSemantics = false,
  });

  final String? name;
  final String? imageUrl;
  final ImageProvider<Object>? imageProvider;
  final double size;
  final String? semanticLabel;
  final IconData fallbackIcon;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    final provider = imageProvider ?? _networkProvider;
    final label = semanticLabel ?? _defaultSemanticLabel;
    final fallback = _fallback();

    final avatar = ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: provider == null
              ? fallback
              : Image(
                  image: provider,
                  fit: BoxFit.cover,
                  frameBuilder: (context, child, frame, synchronous) =>
                      synchronous || frame != null ? child : fallback,
                  errorBuilder: (_, __, ___) => fallback,
                ),
        ),
      ),
    );

    if (excludeFromSemantics) return avatar;

    return Semantics(
      image: true,
      label: label,
      child: avatar,
    );
  }

  ImageProvider<Object>? get _networkProvider {
    final url = imageUrl?.trim();
    return url == null || url.isEmpty ? null : NetworkImage(url);
  }

  String get _defaultSemanticLabel {
    final normalizedName = name?.trim();
    return normalizedName == null || normalizedName.isEmpty
        ? 'Foto de perfil'
        : 'Foto de $normalizedName';
  }

  Widget _fallback() {
    final initials = _initials;
    return ColoredBox(
      color: CDRColorTokens.graphiteLight,
      child: Center(
        child: initials == null
            ? Icon(
                fallbackIcon,
                color: CDRColorTokens.brandYellow,
                size: size * .46,
              )
            : Text(
                initials,
                style: CDRTypographyTokens.label.copyWith(
                  color: CDRColorTokens.white,
                  fontSize: size * .32,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  String? get _initials {
    final parts = name
        ?.trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts == null || parts.isEmpty) return null;
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$last'.toUpperCase();
  }
}
