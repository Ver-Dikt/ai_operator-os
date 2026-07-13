import 'package:flutter/material.dart';

class StudioWorkflowSteps extends StatelessWidget {
  const StudioWorkflowSteps({
    super.key,
    required this.steps,
    this.activeStep = 0,
  });

  final List<String> steps;
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Этапы работы',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x8A080B10),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Wrap(
          spacing: 7,
          runSpacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var index = 0; index < steps.length; index++) ...[
              _Step(
                number: index + 1,
                label: steps[index],
                active: index == activeStep,
                completed: index < activeStep,
              ),
              if (index < steps.length - 1)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0x557D8796),
                  size: 17,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.label,
    required this.active,
    required this.completed,
  });

  final int number;
  final String label;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = active || completed
        ? const Color(0xFFC8FFF4)
        : const Color(0xFF7D8796);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: active
              ? const Color(0xFFC8FFF4)
              : const Color(0x1FFFFFFF),
          child: completed
              ? Icon(Icons.check_rounded, size: 13, color: color)
              : Text(
                  '$number',
                  style: TextStyle(
                    color: active ? const Color(0xFF061311) : color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: active ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
