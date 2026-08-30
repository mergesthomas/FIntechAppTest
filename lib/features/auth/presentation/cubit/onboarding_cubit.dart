import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/onboarding_slide.dart';
import '../../domain/usecases/onboarding_usecases.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

final class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

final class OnboardingEmpty extends OnboardingState {
  const OnboardingEmpty();
}

final class OnboardingSuccess extends OnboardingState {
  const OnboardingSuccess({
    required this.slides,
    required this.index,
    required this.locale,
  });

  final List<OnboardingSlide> slides;
  final int index;
  final String locale;

  OnboardingSlide get current => slides[index];

  OnboardingSuccess copyWith({int? index, String? locale}) {
    return OnboardingSuccess(
      slides: slides,
      index: index ?? this.index,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [slides, index, locale];
}

final class OnboardingFailure extends OnboardingState {
  const OnboardingFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required GetOnboardingSlides getSlides,
    required GetPreferredLocale getLocale,
    required SetPreferredLocale setLocale,
  })  : _getSlides = getSlides,
        _getLocale = getLocale,
        _setLocale = setLocale,
        super(const OnboardingLoading());

  final GetOnboardingSlides _getSlides;
  final GetPreferredLocale _getLocale;
  final SetPreferredLocale _setLocale;

  Future<void> load() async {
    emit(const OnboardingLoading());
    final slides = await _getSlides(const NoParams());
    final locale = await _getLocale(const NoParams());
    slides.fold(
      (failure) => emit(OnboardingFailure(failure)),
      (items) {
        if (items.isEmpty) {
          emit(const OnboardingEmpty());
          return;
        }
        final language = locale.getRight().toNullable() ?? 'en';
        emit(OnboardingSuccess(slides: items, index: 0, locale: language));
      },
    );
  }

  void pageChanged(int index) {
    final current = state;
    if (current is OnboardingSuccess) {
      emit(current.copyWith(index: index));
    }
  }

  Future<void> setLocale(String locale) async {
    final current = state;
    if (current is! OnboardingSuccess) {
      return;
    }
    final result = await _setLocale(locale);
    result.fold(
      (failure) => emit(OnboardingFailure(failure)),
      (_) => emit(current.copyWith(locale: locale)),
    );
  }
}
