import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tokens públicos refletem a paleta V3', () {
    expect(CDRColorTokens.brandBlack.value, 0xFF050505);
    expect(CDRColorTokens.night.value, 0xFF09090B);
    expect(CDRColorTokens.graphite.value, 0xFF18181B);
    expect(CDRColorTokens.graphiteLight.value, 0xFF27272A);
    expect(CDRColorTokens.border.value, 0xFF3F3F46);
    expect(CDRColorTokens.brandYellow.value, 0xFFF3B200);
    expect(CDRColorTokens.gray.value, 0xFFA1A1AA);
    expect(CDRColorTokens.success.value, 0xFF22C55E);
  });

  test('aliases legados apontam para os tokens canônicos', () {
    expect(SharedAppColors.orange, CDRColorTokens.brandYellow);
    expect(SharedAppColors.background, CDRColorTokens.night);
    expect(SharedAppColors.card, CDRColorTokens.graphite);
    expect(SharedAppColors.elevated, CDRColorTokens.graphiteLight);
    expect(SharedAppColors.muted, CDRColorTokens.gray);
    expect(SharedAppColors.success, CDRColorTokens.success);
  });

  test('tema usa tipografia e contraste de seleção V3', () {
    final theme = CDRTheme.dark();

    expect(
      theme.textTheme.displayLarge?.fontFamily,
      CDRTypographyTokens.displayFontFamily,
    );
    expect(
      theme.textTheme.bodyLarge?.fontFamily,
      CDRTypographyTokens.interfaceFontFamily,
    );
    expect(theme.chipTheme.selectedColor, CDRColorTokens.brandYellow);
    expect(theme.chipTheme.checkmarkColor, CDRColorTokens.onGold);
    expect(
      theme.chipTheme.secondaryLabelStyle?.color,
      CDRColorTokens.onGold,
    );
  });

  test('larguras de Cliente e Gestão permanecem separadas', () {
    expect(CDRSizeTokens.clientFrameMaxWidth, 430);
    expect(CDRSizeTokens.clientContentMaxWidth, 720);
    expect(CDRSizeTokens.managementContentMaxWidth, 1180);
    expect(CDRSizeTokens.contentMaxWidth, 720);
  });
}
