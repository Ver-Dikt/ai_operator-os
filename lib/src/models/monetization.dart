enum MonetizationPotential { low, medium, high }

enum RevenueModel {
  freelance,
  agencyService,
  contentMonetization,
  templateSales,
  affiliate,
  jobSearch,
  saasIdea,
  localService,
}

extension MonetizationPotentialLabel on MonetizationPotential {
  String get label {
    return switch (this) {
      MonetizationPotential.low => 'Низкий потенциал',
      MonetizationPotential.medium => 'Средний потенциал',
      MonetizationPotential.high => 'Высокий потенциал',
    };
  }
}

extension RevenueModelLabel on RevenueModel {
  String get label {
    return switch (this) {
      RevenueModel.freelance => 'Фриланс',
      RevenueModel.agencyService => 'Услуга агентства',
      RevenueModel.contentMonetization => 'Монетизация контента',
      RevenueModel.templateSales => 'Продажа шаблонов',
      RevenueModel.affiliate => 'Партнерские ссылки',
      RevenueModel.jobSearch => 'Поиск работы',
      RevenueModel.saasIdea => 'SaaS-идея',
      RevenueModel.localService => 'Локальная услуга',
    };
  }
}
