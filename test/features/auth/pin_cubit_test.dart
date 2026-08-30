import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/pin_draft.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/pin_usecases.dart';
import 'package:fintech_app_test/features/auth/presentation/cubit/pin_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late PinCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    cubit = PinCubit(
      createPin: CreatePin(auth),
      confirmPin: ConfirmPin(auth),
      resetPinDraft: ResetPinDraft(auth),
    );
  });

  tearDown(() => cubit.close());

  test('create then confirm success', () async {
    const draft = PinDraft(id: 'd1');
    when(() => auth.createPin('2580')).thenAnswer(
      (_) async => Either.right(draft),
    );
    when(() => auth.confirmPin(draft: draft, pin: '2580')).thenAnswer(
      (_) async => Either.right(unit),
    );

    await cubit.create('2580');
    expect(cubit.state, const PinCreated(draft));
    await cubit.confirm('2580');
    expect(cubit.state, const PinConfirmed());
  });

  test('confirm without a draft fails', () async {
    await cubit.confirm('2580');
    expect(cubit.state, isA<PinFailure>());
    expect((cubit.state as PinFailure).failure, isA<AuthFailure>());
  });
}
