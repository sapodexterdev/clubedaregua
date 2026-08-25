import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child, {bool reduceMotion = false}) {
    return MaterialApp(
      theme: CDRTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('CDRCard expõe ação e respeita o toque', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      app(
        CDRCard(
          semanticLabel: 'Abrir barbearia',
          onTap: () => taps++,
          child: const Text('Sapão Barber'),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Abrir barbearia' &&
            widget.properties.button == true,
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Sapão Barber'));
    expect(taps, 1);
  });

  testWidgets('badge de status oferece um único rótulo semântico',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        const CDRStatusBadge(
          label: 'Confirmado',
          semanticLabel: 'Status: confirmado',
          tone: CDRStatusTone.success,
          icon: Icons.check_rounded,
        ),
      ),
    );

    expect(find.bySemanticsLabel('Status: confirmado'), findsOneWidget);
    expect(find.text('Confirmado'), findsOneWidget);
    final label = tester.widget<Text>(find.text('Confirmado'));
    expect(label.style?.color, CDRColorTokens.white);
    semantics.dispose();
  });

  testWidgets('todos os badges usam texto com contraste AA', (tester) async {
    await tester.pumpWidget(
      app(
        Wrap(
          children: CDRStatusTone.values
              .map((tone) => CDRStatusBadge(label: tone.name, tone: tone))
              .toList(),
        ),
      ),
    );

    for (final tone in CDRStatusTone.values) {
      final label = tester.widget<Text>(find.text(tone.name));
      expect(label.style?.color, CDRColorTokens.white);
    }
  });

  testWidgets('estados vazio e erro executam suas ações', (tester) async {
    var emptyAction = 0;
    var retries = 0;
    await tester.pumpWidget(
      app(
        ListView(
          children: [
            CDREmptyState(
              title: 'Nenhum produto',
              message: 'Cadastre o primeiro produto.',
              actionLabel: 'Cadastrar',
              onAction: () => emptyAction++,
            ),
            CDRErrorState(
              message: 'Verifique sua conexão.',
              onRetry: () => retries++,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Cadastrar'));
    await tester.tap(find.text('Tentar novamente'));
    expect(emptyAction, 1);
    expect(retries, 1);
  });

  testWidgets('painel inline e estado offline preservam ação e conteúdo',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      app(
        Column(
          children: [
            const CDRStatePanel(
              icon: Icons.info_outline_rounded,
              iconColor: CDRColorTokens.info,
              title: 'Atualização pendente',
              message: 'Os dados exibidos podem estar desatualizados.',
              layout: CDRStatePanelLayout.inline,
              backgroundColor: CDRColorTokens.graphite,
              borderColor: CDRColorTokens.border,
            ),
            CDROfflineState(
              layout: CDRStatePanelLayout.inline,
              onRetry: () => retries++,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Atualização pendente'), findsOneWidget);
    expect(find.text('Você está sem conexão'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    expect(retries, 1);
  });

  testWidgets('snackbar semântico mostra mensagem e ação', (tester) async {
    var actionCalled = false;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => CDRSnackbar.error(
              context,
              'Não foi possível salvar.',
              actionLabel: 'Tentar',
              onAction: () => actionCalled = true,
            ),
            child: const Text('Mostrar'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mostrar'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível salvar.'), findsOneWidget);
    final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackbar.action?.textColor, CDRColorTokens.white);
    await tester.tap(find.text('Tentar'));
    expect(actionCalled, isTrue);
  });

  testWidgets('avatar usa iniciais como fallback local', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(const CDRAvatar(name: 'Rafael Luz', semanticLabel: 'Rafael')),
    );

    expect(find.text('RL'), findsOneWidget);
    expect(find.bySemanticsLabel('Rafael'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('avatar decorativo não duplica o nome na árvore semântica',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        const CDRAvatar(
          name: 'Rafael Luz',
          semanticLabel: 'Rafael',
          excludeFromSemantics: true,
        ),
      ),
    );

    expect(find.text('RL'), findsOneWidget);
    expect(find.bySemanticsLabel('Rafael'), findsNothing);
    semantics.dispose();
  });

  testWidgets('skeleton elimina movimento quando solicitado', (tester) async {
    await tester.pumpWidget(
      app(const CDRSkeleton(width: 120, height: 20), reduceMotion: true),
    );

    final animation = tester.widget<TweenAnimationBuilder<double>>(
      find.byWidgetPredicate(
        (widget) => widget is TweenAnimationBuilder<double>,
      ),
    );
    expect(animation.duration, Duration.zero);
  });

  testWidgets('skeleton usa apenas uma transição curta', (tester) async {
    await tester.pumpWidget(
      app(const CDRSkeleton(width: 120, height: 20)),
    );

    final frames = await tester.pumpAndSettle();
    expect(frames, lessThan(10));
  });
}
