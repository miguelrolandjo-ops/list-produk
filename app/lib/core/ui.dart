import 'package:flutter/material.dart';

/// Look of the app, after the inventory dashboard reference: a soft blue
/// canvas, white cards with a hairline border, navy for actions, and small
/// coloured badges for status. Built for phones first, then tablets.
abstract final class AppColors {
  static const navy = Color(0xFF213A8F);
  static const canvas = Color(0xFFF0F4FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE1E7F1);
  static const tint = Color(0xFFE9F0FB); // behind the emoji, where a photo would be
  static const muted = Color(0xFF6B7385);
  static const ink = Color(0xFF151A26);
  static const ok = Color(0xFF1E9E55);
  static const warn = Color(0xFFE5484D);
  static const neutral = Color(0xFF5B6475);
  static const attention = Color(0xFFB7791F);
}

/// Width classes. Tests render at 800 px, which is "medium".
enum ScreenSize { compact, medium, expanded }

ScreenSize screenSizeOf(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 600) return ScreenSize.compact;
  if (w < 1024) return ScreenSize.medium;
  return ScreenSize.expanded;
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.navy,
    primary: AppColors.navy,
    surface: AppColors.surface,
    error: AppColors.warn,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final text = base.textTheme.apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: rounded,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: rounded,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: AppColors.navy),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      constraints: const BoxConstraints(minHeight: 52),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.tint,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(
        text.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// The small coloured label in a card's corner ("Margin rendah", "Aman").
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

/// The bordered box of label/value rows on a card ("Produk  12").
class StatBox extends StatelessWidget {
  const StatBox({super.key, required this.rows});

  final List<(String label, String value, Color? color)> rows;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 12, endIndent: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].$1,
                      style: text.bodySmall?.copyWith(color: AppColors.muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rows[i].$2,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: rows[i].$3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A category as a card: emoji where a photo would be, the name, a stat box,
/// and "Lihat produk". The whole card is tappable too.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.caption,
    required this.rows,
    required this.onOpen,
    this.badge,
    this.onEmojiTap,
  });

  final String emoji;
  final String name;

  /// Small grey line above the name (like the SKU line in the reference).
  final String caption;
  final List<(String, String, Color?)> rows;
  final VoidCallback onOpen;
  final StatusBadge? badge;

  /// Owner only: change the emoji.
  final VoidCallback? onEmojiTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 104,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.tint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Semantics(
                          label: onEmojiTap == null ? null : 'Ubah ikon $name',
                          button: onEmojiTap != null,
                          child: GestureDetector(
                            onTap: onEmojiTap,
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 52),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (badge != null) Positioned(left: 8, top: 8, child: badge!),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caption,
                      style: text.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatBox(rows: rows),
              const Spacer(),
              FilledButton.tonal(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.canvas,
                  foregroundColor: AppColors.navy,
                  minimumSize: const Size(0, 42),
                ),
                child: const Text('Lihat produk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid of [CategoryCard]s: two columns on a phone, more on a tablet.
SliverGrid categoryGrid(BuildContext context, List<Widget> cards) {
  final width = MediaQuery.sizeOf(context).width;
  // Taller cards when the phone uses large text, so nothing gets cut off.
  final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
  return SliverGrid(
    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: width < 380 ? 400 : 280,
      mainAxisExtent: 200 + 118 * textScale,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
    ),
    delegate: SliverChildListDelegate(cards),
  );
}

/// "Kategori: 6   Produk: 120   ..." under the page title.
class SummaryLine extends StatelessWidget {
  const SummaryLine({super.key, required this.items});

  final List<(String, String, Color?)> items;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.bodyMedium;
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        for (final (label, value, color) in items)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: text?.copyWith(color: AppColors.muted),
                ),
                TextSpan(
                  text: value,
                  style: text?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Page heading for wide layouts: title, subtitle and actions on one row; on a
/// phone the actions wrap under the text.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: text.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ],
    );
    if (screenSizeOf(context) == ScreenSize.compact || actions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading,
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: heading),
        const SizedBox(width: 16),
        Wrap(spacing: 8, children: actions),
      ],
    );
  }
}
