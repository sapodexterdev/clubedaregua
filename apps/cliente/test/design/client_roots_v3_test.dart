import 'package:clubedaregua/core/app_mode.dart';
import 'package:clubedaregua/models/appointment.dart';
import 'package:clubedaregua/providers/app_mode_controller.dart';
import 'package:clubedaregua/providers/app_state.dart';
import 'package:clubedaregua/screens/client/favorites_screen.dart';
import 'package:clubedaregua/screens/client/history_screen.dart';
import 'package:clubedaregua/screens/client/home_screen.dart';
import 'package:clubedaregua/screens/client/profile_screen.dart';
import 'package:clubedaregua/theme/app_colors.dart';
import 'package:clubedaregua/theme/app_theme.dart';
import 'package:clubedaregua/widgets/premium_bottom_nav.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('favorite and agenda loading use finite card skeletons',
      (tester) async {
    final state = _VisualAppState()
      ..isSignedIn = true
      ..isLoadingFavorites = true;

    await tester.pumpWidget(
      _app(state, const FavoritesScreen(onTabSelected: _ignoreTab)),
    );
    expect(find.byType(CDRSkeleton), findsWidgets);
    expect(find.byType(CDRLoading), findsNothing);

    state
      ..isLoadingFavorites = false
      ..isLoadingAppointments = true;
    await tester.pumpWidget(
      _app(
        state,
        const HistoryScreen(onTabSelected: _ignoreTab, isActive: false),
      ),
    );
    expect(find.byType(CDRSkeleton), findsWidgets);
    expect(find.byType(CDRLoading), findsNothing);
  });

  testWidgets('empty and error roots use the shared semantic states',
      (tester) async {
    final state = _VisualAppState()..isSignedIn = true;

    await tester.pumpWidget(
      _app(
        state,
        const HomeScreen(onTabSelected: _ignoreTab, isActive: false),
      ),
    );
    expect(find.byType(CDREmptyState), findsOneWidget);

    state.favoritesLoadError = 'erro interno';
    await tester.pumpWidget(
      _app(state, const FavoritesScreen(onTabSelected: _ignoreTab)),
    );
    expect(find.byType(CDRErrorState), findsOneWidget);
    expect(find.text('erro interno'), findsNothing);
  });

  testWidgets('active professional mode follows V3 contrast and avatar rules',
      (tester) async {
    final state = _VisualAppState()
      ..isSignedIn = true
      ..currentUserName = 'Rafael Luz'
      ..professionalRoles = const {'owner'};
    final modes = AppModeController()
      ..currentMode = AppMode.owner
      ..availableModes = const {AppMode.client, AppMode.owner};

    await tester.pumpWidget(
      _app(
        state,
        const ProfileScreen(showBottomNavigation: false),
        modes: modes,
      ),
    );

    expect(find.byType(CDRAvatar), findsOneWidget);
    final selectedTiles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .where((tile) => tile.selected)
        .toList();
    expect(selectedTiles, hasLength(1));
    expect(selectedTiles.single.selectedTileColor, AppColors.orange);
    final clippedCardMaterials = tester
        .widgetList<Material>(find.ancestor(
          of: find.text('Dono'),
          matching: find.byType(Material),
        ))
        .where(
          (material) =>
              material.color == AppColors.card &&
              material.clipBehavior == Clip.antiAlias,
        );
    expect(clippedCardMaterials, isNotEmpty);
    expect(find.text('Dono'), findsOneWidget);
  });

  testWidgets('profile editor remains scrollable on a compact scaled viewport',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final state = _VisualAppState()
      ..isSignedIn = true
      ..currentUserName = 'Rafael Luz';

    await tester.pumpWidget(
      _app(
        state,
        const ProfileScreen(showBottomNavigation: false),
        textScale: 2,
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Editar dados pessoais'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Editar dados pessoais'));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Salvar alterações'), findsOneWidget);
  });

  testWidgets('agenda status and bottom navigation support 200 percent text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final state = _VisualAppState()
      ..isSignedIn = true
      ..appointments = const [
        Appointment(
          id: 'appointment-1',
          barberName: 'Rafael',
          serviceName: 'Corte e barba',
          shopName: 'Barbearia de teste com nome longo',
          dateLabel: '2026-08-23',
          time: '10:00',
          status: 'new',
          total: 70,
        ),
      ];

    await tester.pumpWidget(
      _app(
        state,
        const HistoryScreen(onTabSelected: _ignoreTab, isActive: false),
        textScale: 2,
      ),
    );
    expect(find.text('Processando'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _app(
        state,
        Scaffold(
          bottomNavigationBar: PremiumBottomNav(
            currentIndex: 0,
            onTap: _ignoreTab,
          ),
        ),
        textScale: 2,
      ),
    );
    for (final label in ['Descobrir', 'Favoritos', 'Agenda', 'Perfil']) {
      final finder = find.byWidgetPredicate(
        (widget) =>
            widget is Text && widget.data?.replaceAll('\n', '') == label,
        description: 'legenda visual de navegação $label',
      );
      final semanticFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == label,
        description: 'rótulo semântico de navegação $label',
      );
      expect(finder, findsOneWidget);
      expect(semanticFinder, findsOneWidget);
      final text = tester.widget<Text>(finder);
      expect(text.maxLines, 3);
      expect(text.textAlign, TextAlign.center);
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: 'A legenda $label (${paragraph.text.toPlainText()}) deve '
            'permanecer totalmente visível em ${paragraph.size}.',
      );
    }
    expect(tester.takeException(), isNull);
  });
}

void _ignoreTab(int _) {}

Widget _app(
  AppState state,
  Widget child, {
  AppModeController? modes,
  double textScale = 1,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppState>.value(value: state),
      ChangeNotifierProvider<AppModeController>.value(
        value: modes ?? AppModeController(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: appChild ?? const SizedBox.shrink(),
      ),
      home: child,
    ),
  );
}

class _VisualAppState extends AppState {
  @override
  Future<void> refreshAppointments() async {}

  @override
  Future<void> refreshNotifications() async {}
}
