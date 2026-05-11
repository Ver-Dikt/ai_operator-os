import 'package:flutter/material.dart';

import '../models/workflow.dart';

class WorkflowCard extends StatelessWidget {
  const WorkflowCard({super.key, required this.workflow});

  final Workflow workflow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11130F),
        border: Border.all(color: const Color(0xFF34382E)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8DCC2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.timeline,
                  color: Color(0xFF12100A),
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  workflow.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFFF1E7CF),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            workflow.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFC7BEA8), height: 1.35),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: workflow.steps.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final step = workflow.steps[index];
                return Row(
                  children: [
                    Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: Color(0xFFE34F34),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE8DCC2),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
