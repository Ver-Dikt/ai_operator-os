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
      MonetizationPotential.low => 'Low potential',
      MonetizationPotential.medium => 'Medium potential',
      MonetizationPotential.high => 'High potential',
    };
  }
}

extension RevenueModelLabel on RevenueModel {
  String get label {
    return switch (this) {
      RevenueModel.freelance => 'Freelance',
      RevenueModel.agencyService => 'Agency service',
      RevenueModel.contentMonetization => 'Content monetization',
      RevenueModel.templateSales => 'Template sales',
      RevenueModel.affiliate => 'Affiliate',
      RevenueModel.jobSearch => 'Job search',
      RevenueModel.saasIdea => 'SaaS idea',
      RevenueModel.localService => 'Local service',
    };
  }
}
