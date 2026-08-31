import '../../../core/router/app_route.dart';
import '../domain/entities/order_book.dart';

abstract final class MarketSwapLink {
  static String limitFromDraft(BookTicketDraft draft) {
    return Uri(
      path: AppRoute.swap.path,
      queryParameters: {
        'to': draft.currency.code,
        'quote': draft.quote.code,
        'type': 'limit',
        'limitPrice': draft.limitPrice.amount.toString(),
        'side': draft.side.name,
      },
    ).toString();
  }
}
