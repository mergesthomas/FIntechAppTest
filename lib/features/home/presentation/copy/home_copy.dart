/// Screenshot / fixture copy. COMPLIANCE: APY and legal strings are placeholders.
abstract final class HomeCopy {
  static const alerts = {
    'home.alert.eurx_below_zero':
        'Your EURx balance is below zero. Add funds or restore. [placeholder]',
  };

  static const promos = <String, String>{};

  static const news = {
    'home.news.placeholder': 'Markets wrap — fixture headline',
  };

  static String alert(String key) => alerts[key] ?? key;
  static String promoTitle(String key) => promos[key] ?? key;
  static String promoBody(String key) => promos[key] ?? key;
  static String newsTitle(String key) => news[key] ?? key;
}
