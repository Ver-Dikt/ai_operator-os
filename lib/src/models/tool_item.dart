enum ToolAccess { free, freemium, paid, local, sensitive }

class ToolItem {
  const ToolItem({
    required this.id,
    required this.category,
    required this.name,
    required this.url,
    required this.description,
    required this.access,
    required this.priceNote,
    required this.bestFor,
    required this.signal,
    required this.tags,
  });

  final String id;
  final String category;
  final String name;
  final String url;
  final String description;
  final ToolAccess access;
  final String priceNote;
  final String bestFor;
  final int signal;
  final List<String> tags;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    final haystack = [
      category,
      name,
      description,
      access.label,
      priceNote,
      bestFor,
      ...tags,
    ].join(' ').toLowerCase();

    return haystack.contains(normalized);
  }
}

extension ToolAccessLabel on ToolAccess {
  String get label {
    return switch (this) {
      ToolAccess.free => 'Бесплатно',
      ToolAccess.freemium => 'Есть бесплатный лимит',
      ToolAccess.paid => 'Платно',
      ToolAccess.local => 'Локально',
      ToolAccess.sensitive => 'Осторожно',
    };
  }

  String get groupTitle {
    return switch (this) {
      ToolAccess.free => 'Бесплатные онлайн',
      ToolAccess.freemium => 'С бесплатным лимитом',
      ToolAccess.local => 'Локальные и open source',
      ToolAccess.paid => 'Платные / premium',
      ToolAccess.sensitive => 'Экспериментальные',
    };
  }

  int get sortWeight {
    return switch (this) {
      ToolAccess.free => 0,
      ToolAccess.freemium => 1,
      ToolAccess.local => 2,
      ToolAccess.paid => 3,
      ToolAccess.sensitive => 4,
    };
  }
}
