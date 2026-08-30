import '../../domain/entities/profile.dart';

final class ProfileLocalDataSource {
  const ProfileLocalDataSource();

  ProfileOverview overview() {
    return const ProfileOverview(
      greeting: 'Hello',
      loyaltyTier: 'Platinum',
      isPrivate: false,
    );
  }

  List<String> rewards() => const ['Rewards Hub', 'Refer a friend'];

  List<ProfileShortcut> shortcuts() {
    return const [
      ProfileShortcut(id: 'credit', label: 'Credit'),
      ProfileShortcut(id: 'savings', label: 'Savings'),
      ProfileShortcut(id: 'futures', label: 'Futures'),
      ProfileShortcut(id: 'card', label: 'Card'),
      ProfileShortcut(id: 'security', label: 'Security & Settings'),
      ProfileShortcut(id: 'products', label: 'Products'),
    ];
  }

  String version() => '7.9.1';

  Map<String, String> legalLinks() {
    return const {
      'terms': 'https://example.invalid/terms',
      'about': 'https://example.invalid/about',
    };
  }
}
