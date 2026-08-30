import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/pin_draft.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/pin_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late CreatePin createPin;
  late ConfirmPin confirmPin;

  setUp(() {
    auth = MockAuthRepository();
    createPin = CreatePin(auth);
    confirmPin = ConfirmPin(auth);
  });

  test('CreatePin rejects a non-4-digit PIN', () async {
    final result = await createPin('12');

    expect(
      result,
      Either<Failure, PinDraft>.left(const ValidationFailure('pin_must_be_4_digits')),
    );
  });

  test('ConfirmPin sends matching draft to the repository', () async {
    const draft = PinDraft(id: 'd1');
    when(() => auth.confirmPin(draft: draft, pin: '2580')).thenAnswer(
      (_) async => Either.right(unit),
    );

    final result = await confirmPin(
      const ConfirmPinParams(draft: draft, pin: '2580'),
    );

    expect(result, Either<Failure, Unit>.right(unit));
  });
}
