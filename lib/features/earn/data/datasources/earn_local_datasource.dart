import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/observe/settlement_breadcrumb.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/earn.dart';

final class EarnLocalDataSource {
  bool earnInNexo = true;
  bool stopped = false;
  final Set<String> requestIds = {};

  SavingsHubOverview overview() {
    return SavingsHubOverview(
      interestEarned: Money.parse('2477.10', Currency.usd),
    );
  }

  List<EarnProductTeaser> products() {
    return const [
      EarnProductTeaser(
        id: 'dual',
        label: 'Dual Investment',
        teaser: 'Up to 117.05% placeholder',
      ),
      EarnProductTeaser(
        id: 'fixed',
        label: 'Fixed-term',
        teaser: 'Product flow not available',
      ),
      EarnProductTeaser(
        id: 'vaults',
        label: 'Wealth Vaults',
        teaser: 'Product flow not available',
      ),
      EarnProductTeaser(
        id: 'recurring',
        label: 'Recurring buys',
        teaser: 'Product flow not available',
      ),
    ];
  }

  EarnPreference preference() => EarnPreference(earnInNexo: earnInNexo);

  SettlementStatus setEarnInNexo({
    required String requestId,
    required bool enabled,
  }) {
    if (requestIds.contains(requestId)) {
      return SettlementStatus.inFlight;
    }
    requestIds.add(requestId);
    earnInNexo = enabled;
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    return SettlementStatus.inFlight;
  }

  SettlementStatus stop({required String requestId}) {
    if (requestIds.contains(requestId)) {
      return SettlementStatus.inFlight;
    }
    requestIds.add(requestId);
    stopped = true;
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    return SettlementStatus.inFlight;
  }
}
