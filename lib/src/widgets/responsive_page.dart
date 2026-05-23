import 'package:flutter/material.dart';

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 640;
    final horizontalPadding = width >= 1280
        ? 26.0
        : width >= 720
        ? 20.0
        : 14.0;
    final bottomPadding = isCompact ? 96.0 : 24.0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.1,
          colors: [Color(0xFF111821), Color(0xFF050609)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isCompact ? 12 : 18,
                horizontalPadding,
                bottomPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1360),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PageHeader(
                          title: title,
                          subtitle: subtitle,
                          actions: actions,
                          compact: isCompact,
                        ),
                        SizedBox(height: isCompact ? 12 : 16),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 15),
      decoration: BoxDecoration(
        color: const Color(0xA60D121A),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 10,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      (compact
                              ? Theme.of(context).textTheme.headlineSmall
                              : Theme.of(context).textTheme.headlineLarge)
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFF8FBFF),
                            height: 1.1,
                          ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style:
                      (compact
                              ? Theme.of(context).textTheme.bodyMedium
                              : Theme.of(context).textTheme.bodyLarge)
                          ?.copyWith(
                            color: const Color(0xFFA7B1C1),
                            height: 1.45,
                          ),
                ),
              ],
            ),
          ),
          if (actions.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}
