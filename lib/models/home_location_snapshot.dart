class HomeLocationSnapshot {
  const HomeLocationSnapshot({
    required this.loading,
    required this.latitude,
    required this.longitude,
    required this.lastSyncAt,
    required this.errorMessage,
  });

  factory HomeLocationSnapshot.initial() {
    return const HomeLocationSnapshot(
      loading: false,
      latitude: null,
      longitude: null,
      lastSyncAt: null,
      errorMessage: null,
    );
  }

  final bool loading;
  final double? latitude;
  final double? longitude;
  final DateTime? lastSyncAt;
  final String? errorMessage;

  HomeLocationSnapshot copyWith({
    bool? loading,
    double? latitude,
    double? longitude,
    DateTime? lastSyncAt,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return HomeLocationSnapshot(
      loading: loading ?? this.loading,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
