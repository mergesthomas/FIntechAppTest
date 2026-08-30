import 'package:fintech_app_test/core/auth/auth_port.dart';
import 'package:fintech_app_test/core/auth/eligibility_status.dart';
import 'package:fintech_app_test/core/auth/product_area.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/add_funds/domain/entities/buy_crypto.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthPort extends Mock implements AuthPort {}

void registerAuthFallbacks() {
  registerFallbackValue(ProductArea.funding);
  registerFallbackValue(Money.zero(Currency.eur));
  registerFallbackValue(PurchaseFrequency.oneTime);
}

void stubSignedIn(
  MockAuthPort auth, {
  EligibilityStatus status = EligibilityStatus.approved,
}) {
  when(() => auth.hasValidSession()).thenAnswer(
    (_) async => Either.right(true),
  );
  when(() => auth.eligibility(any())).thenAnswer(
    (_) async => Either.right(status),
  );
}

void stubSignedOut(MockAuthPort auth) {
  when(() => auth.hasValidSession()).thenAnswer(
    (_) async => Either.right(false),
  );
}

void stubEligibility(MockAuthPort auth, ProductArea area, EligibilityStatus status) {
  when(() => auth.eligibility(area)).thenAnswer(
    (_) async => Either.right(status),
  );
}
