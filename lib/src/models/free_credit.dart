class FreeCreditOffer {
  const FreeCreditOffer({
    required this.service,
    required this.freeType,
    required this.refreshRate,
    required this.limitations,
    required this.needsCard,
    required this.watermark,
    required this.signupUrl,
    required this.bestUse,
  });

  final String service;
  final String freeType;
  final String refreshRate;
  final String limitations;
  final bool needsCard;
  final bool watermark;
  final String signupUrl;
  final String bestUse;
}
