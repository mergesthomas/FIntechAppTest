import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../market/quote_freshness.dart';
import '../market/watch_market_connection.dart';

class MarketConnectionCubit extends Cubit<QuoteFreshness> {
  MarketConnectionCubit(this._watch) : super(_watch.current) {
    _sub = _watch().listen((freshness) {
      if (!isClosed && state != freshness) {
        emit(freshness);
      }
    });
  }

  final WatchMarketConnection _watch;
  StreamSubscription<QuoteFreshness>? _sub;

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _watch.dispose();
    return super.close();
  }
}
