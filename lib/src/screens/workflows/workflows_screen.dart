import 'package:flutter/material.dart';

import '../../ai_operator_app.dart';
import '../../data/seed_workflows.dart';
import '../../models/workflow_template.dart';

enum _WorkflowTab { templates, mine, community }

extension _WorkflowTabLabel on _WorkflowTab {
  String get label {
    return switch (this) {
      _WorkflowTab.templates => 'Шаблоны',
      _WorkflowTab.mine => 'Мои workflows',
      _WorkflowTab.community => 'Сообщество',
    };
  }
}

class WorkflowsScreen extends StatefulWidget {
  const WorkflowsScreen({super.key});

  @override
  State<WorkflowsScreen> createState() => _WorkflowsScreenState();
}

class _WorkflowsScreenState extends State<WorkflowsScreen> {
  _WorkflowTab _tab = _WorkflowTab.templates;

  @override
  Widget build(BuildContext context) {
    final workflows = _workflowsForTab(_tab);
    return Container(
      color: const Color(0xFF030303),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 34),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(onCreate: _openNewWorkflow),
                      const SizedBox(height: 16),
                      const _DraftNotice(),
                      const SizedBox(height: 26),
                      _WorkflowTabs(
                        value: _tab,
                        onChanged: (value) => setState(() => _tab = value),
                      ),
                      const SizedBox(height: 26),
                      _WorkflowGrid(workflows: workflows),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<WorkflowTemplate> _workflowsForTab(_WorkflowTab tab) {
    return switch (tab) {
      _WorkflowTab.templates => seedWorkflows,
      _WorkflowTab.mine => seedWorkflows.take(3).toList(),
      _WorkflowTab.community => seedWorkflows.reversed.toList(),
    };
  }

  void _openNewWorkflow() {
    final workflow = seedWorkflows.first;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkflowRunScreen(workflow: workflow),
      ),
    );
  }
}

class _DraftNotice extends StatelessWidget {
  const _DraftNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1118),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.route_rounded, color: Color(0xFF22D3EE)),
        title: Text(
          'Workflow templates are drafts.',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          'Execution will be connected later. Сейчас это библиотека production-шаблонов и стартовых сценариев.',
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WORKFLOW STUDIO',
          style: TextStyle(
            color: Color(0xFF22D3EE),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Workflows',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Создавай и запускай цепочки генерации: сценарий, кадры, видео, публикация и повторяемые production-процессы.',
          style: TextStyle(color: Colors.white54, height: 1.45),
        ),
      ],
    );
    final button = FilledButton.icon(
      onPressed: onCreate,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Создать workflow'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF22D3EE),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 18), button],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: title),
        const SizedBox(width: 20),
        button,
      ],
    );
  }
}

class _WorkflowTabs extends StatelessWidget {
  const _WorkflowTabs({required this.value, required this.onChanged});

  final _WorkflowTab value;
  final ValueChanged<_WorkflowTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x12FFFFFF))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in _WorkflowTab.values)
              _TabButton(
                label: tab.label,
                selected: value == tab,
                onTap: () => onChanged(tab),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? const Color(0xFF22D3EE) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: selected ? const Color(0xFF22D3EE) : Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkflowGrid extends StatelessWidget {
  const _WorkflowGrid({required this.workflows});

  final List<WorkflowTemplate> workflows;

  @override
  Widget build(BuildContext context) {
    if (workflows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 70),
        decoration: BoxDecoration(
          color: const Color(0x08FFFFFF),
          border: Border.all(color: const Color(0x12FFFFFF), width: 2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            'В этой секции пока нет workflows.',
            style: TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1280
            ? 6
            : constraints.maxWidth >= 1080
            ? 5
            : constraints.maxWidth >= 860
            ? 4
            : constraints.maxWidth >= 620
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: workflows.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 3 / 4,
          ),
          itemBuilder: (context, index) =>
              _WorkflowPoster(workflow: workflows[index]),
        );
      },
    );
  }
}

class _WorkflowPoster extends StatelessWidget {
  const _WorkflowPoster({required this.workflow});

  final WorkflowTemplate workflow;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final favorite = settings.isFavoriteWorkflow(workflow.id);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WorkflowRunScreen(workflow: workflow),
        ),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border.all(color: const Color(0x14FFFFFF)),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _WorkflowPosterPainter(seed: workflow.id.hashCode),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xE6000000)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => settings.toggleFavoriteWorkflow(workflow.id),
                icon: Icon(
                  favorite ? Icons.star_rounded : Icons.more_vert_rounded,
                ),
                color: Colors.white70,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0x66000000),
                  fixedSize: const Size(34, 34),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workflow.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF22D3EE),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    workflow.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      _MiniBadge(workflow.difficulty.label),
                      _MiniBadge(workflow.estimatedTime),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WorkflowPosterPainter extends CustomPainter {
  const _WorkflowPosterPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = [
      const Color(0xFF22D3EE),
      const Color(0xFFFFB86B),
      const Color(0xFFFF6B8A),
      const Color(0xFF8B5CF6),
    ];
    final a = palette[seed.abs() % palette.length];
    final b = palette[(seed.abs() + 1) % palette.length];
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            a.withValues(alpha: 0.22),
            b.withValues(alpha: 0.10),
            const Color(0xFF050505),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.14 + i * 0.12);
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 32), line);
    }
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.28),
      size.width * 0.22,
      Paint()
        ..color = a.withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );
  }

  @override
  bool shouldRepaint(covariant _WorkflowPosterPainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}

class WorkflowRunScreen extends StatefulWidget {
  const WorkflowRunScreen({super.key, required this.workflow});

  final WorkflowTemplate workflow;

  @override
  State<WorkflowRunScreen> createState() => _WorkflowRunScreenState();
}

class _WorkflowRunScreenState extends State<WorkflowRunScreen> {
  final Set<String> _done = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.workflow.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            widget.workflow.description,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          for (final step in widget.workflow.steps)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: const Color(0x14FFFFFF)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: CheckboxListTile(
                value: _done.contains(step.id),
                onChanged: (value) => setState(() {
                  if (value ?? false) {
                    _done.add(step.id);
                  } else {
                    _done.remove(step.id);
                  }
                }),
                title: Text(step.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.instruction),
                    const SizedBox(height: 8),
                    SelectableText(step.promptTemplate),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
        ],
      ),
    );
  }
}
