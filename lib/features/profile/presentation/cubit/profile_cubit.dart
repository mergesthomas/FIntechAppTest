import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/profile_usecases.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileEmpty extends ProfileState {
  const ProfileEmpty();
}

final class ProfileFailure extends ProfileState {
  const ProfileFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class ProfileSuccess extends ProfileState {
  const ProfileSuccess({
    required this.overview,
    required this.rewards,
    required this.shortcuts,
    required this.version,
    required this.legalLinks,
  });

  final ProfileOverview overview;
  final List<String> rewards;
  final List<ProfileShortcut> shortcuts;
  final String version;
  final Map<String, String> legalLinks;

  @override
  List<Object?> get props => [overview, rewards, shortcuts, version, legalLinks];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required GetProfileOverview getOverview,
    required GetRewardsTeasers getRewards,
    required GetProfileProductShortcuts getShortcuts,
    required GetAppVersionInfo getVersion,
    required GetLegalLinks getLegalLinks,
  })  : _getOverview = getOverview,
        _getRewards = getRewards,
        _getShortcuts = getShortcuts,
        _getVersion = getVersion,
        _getLegalLinks = getLegalLinks,
        super(const ProfileLoading());

  final GetProfileOverview _getOverview;
  final GetRewardsTeasers _getRewards;
  final GetProfileProductShortcuts _getShortcuts;
  final GetAppVersionInfo _getVersion;
  final GetLegalLinks _getLegalLinks;

  Future<void> load() async {
    emit(const ProfileLoading());
    final overview = await _getOverview(const NoParams());
    await overview.fold((failure) async => emit(ProfileFailure(failure)), (
      o,
    ) async {
      final rewards = await _getRewards(const NoParams());
      final shortcuts = await _getShortcuts(const NoParams());
      final version = await _getVersion(const NoParams());
      final legal = await _getLegalLinks(const NoParams());
      if ([rewards, shortcuts, version, legal].any((e) => e.isLeft())) {
        emit(const ProfileFailure(ServerFailure('profile_partial_failure')));
        return;
      }
      final shortcutList = shortcuts.getRight().toNullable()!;
      if (shortcutList.isEmpty) {
        emit(const ProfileEmpty());
        return;
      }
      emit(
        ProfileSuccess(
          overview: o,
          rewards: rewards.getRight().toNullable()!,
          shortcuts: shortcutList,
          version: version.getRight().toNullable()!,
          legalLinks: legal.getRight().toNullable()!,
        ),
      );
    });
  }
}
