import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.tags,
    required this.selectedTag,
    required this.onCategoryChanged,
    required this.onTagChanged,
  });

  final List<String> categories;
  final String selectedCategory;
  final List<String> tags;
  final String selectedTag;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onTagChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xCC0F141E),
        border: Border.all(color: const Color(0xFF263244)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterSection(
            title: 'Категории',
            children: categories.map((category) {
              final selected = selectedCategory == category;
              return _FilterPill(
                label: category,
                selected: selected,
                onTap: () => onCategoryChanged(category),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _FilterSection(
            title: 'Теги',
            children: tags.map((tag) {
              final selected = selectedTag == tag;
              return _FilterPill(
                label: tag == 'all' ? 'all tags' : tag,
                selected: selected,
                compact: true,
                onTap: () => onTagChanged(tag),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8B97A8),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF173534) : const Color(0xFF111722),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 14,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? const Color(0xFF6BE4C9)
                  : const Color(0xFF263244),
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF9CF5E2)
                  : const Color(0xFFC8D2E1),
              fontSize: compact ? 12 : 13,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
