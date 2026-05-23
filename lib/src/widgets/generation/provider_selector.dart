import 'package:flutter/material.dart';

import '../../models/generation/generation_provider.dart';

class ProviderSelector extends StatelessWidget {
  const ProviderSelector({
    super.key,
    required this.providers,
    required this.selectedProviderId,
    required this.onChanged,
  });

  final List<GenerationProvider> providers;
  final String selectedProviderId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected =
        providers.any((provider) => provider.id == selectedProviderId)
        ? selectedProviderId
        : providers.first.id;
    return _StudioDropdown(
      icon: Icons.hub_outlined,
      value: selected,
      items: [
        for (final provider in providers)
          DropdownMenuItem(
            value: provider.id,
            child: Text(
              '${provider.name} · ${provider.type.label} · ${provider.statusLabel}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _StudioDropdown extends StatelessWidget {
  const _StudioDropdown({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        color: const Color(0x8011161F),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7D8798)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: const Color(0xFF0B0F16),
                iconEnabledColor: const Color(0xFF7D8798),
                style: const TextStyle(
                  color: Color(0xFFE8EEF8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
