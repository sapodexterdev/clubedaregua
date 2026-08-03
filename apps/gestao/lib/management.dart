import 'dart:async';
import 'dart:convert';

import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/logo_file.dart';
import 'utils/logo_picker.dart';

part 'management_session.dart';
part 'management_models.dart';
part 'management_auth_screens.dart';
part 'management_shell.dart';
part 'management_agenda_page.dart';
part 'management_booking_requests_page.dart';
part 'management_availability_page.dart';
part 'management_clients_page.dart';
part 'management_commission_page.dart';
part 'management_barber_profile_sheet.dart';
part 'management_owner_dashboard_page.dart';
part 'management_services_page.dart';
part 'management_team_page.dart';
part 'management_settings_page.dart';
part 'management_cash_page.dart';
part 'management_shared_widgets.dart';

void _ignoreClientModeNavigation() {}

String _managementTime(dynamic value, String fallback) {
  final text = value?.toString() ?? '';
  return text.length >= 5 ? text.substring(0, 5) : fallback;
}

int _minutesFromTime(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return 0;
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
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

class EmbeddedManagementArea extends StatefulWidget {
  const EmbeddedManagementArea({
    required this.initialRole,
    required this.onOpenClientMode,
    required this.onSignedOut,
    this.onOpenProfile,
    this.onRoleChanged,
    super.key,
  });

  final ManagementRole initialRole;
  final VoidCallback onOpenClientMode;
  final VoidCallback onSignedOut;
  final VoidCallback? onOpenProfile;
  final Future<void> Function(ManagementRole role)? onRoleChanged;

  @override
  State<EmbeddedManagementArea> createState() => _EmbeddedManagementAreaState();
}

class _EmbeddedManagementAreaState extends State<EmbeddedManagementArea> {
  late final ManagementSession _session;

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    _session = ManagementSession();
    _session.restoreUnifiedSession(initialRole: widget.initialRole);
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _session,
      child: Theme(
        data: _buildManagementTheme(),
        child: Consumer<ManagementSession>(
          builder: (context, session, _) {
            if (session.isRestoringSession ||
                (session.isSignedIn && !session.professionalAccessResolved)) {
              return const Scaffold(
                body: CDRLoading.fullScreen(
                  message: 'Preparando sua área profissional...',
                ),
              );
            }
            if (!session.isSignedIn || !session.hasProfessionalAccess) {
              return _ProfessionalAccessDeniedScreen(
                onOpenClientMode: widget.onOpenClientMode,
              );
            }
            return ManagementHomeScreen(
              initialRole: widget.initialRole,
              onOpenClientMode: widget.onOpenClientMode,
              onOpenProfile: widget.onOpenProfile,
              onRoleChanged: widget.onRoleChanged,
              onSignedOut: () async {
                await session.signOut();
                widget.onSignedOut();
              },
            );
          },
        ),
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
