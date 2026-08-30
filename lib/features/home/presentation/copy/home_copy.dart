/// Screenshot / fixture copy. COMPLIANCE: APY and legal strings are placeholders.
abstract final class HomeCopy {
  static const alerts = {
    'home.alert.eurx_below_zero':
        'Your EURx balance is below zero. Add funds or restore. [placeholder]',
  };

  static const promos = {
    'home.promo.zero_interest.title': 'Zero-interest Credit',
    'home.promo.zero_interest.body':
        '[placeholder] Fixed credit product — compliance review',
  };

  static const news = {
    'home.news.placeholder': 'Markets wrap — fixture headline',
  };

  static String alert(String key) => alerts[key] ?? key;
  static String promoTitle(String key) => promos[key] ?? key;
  static String promoBody(String key) =>
      {
        ...promos,
      }[key] ??
      key;
  static String newsTitle(String key) => news[key] ?? key;
}
