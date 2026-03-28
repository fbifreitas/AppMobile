class HomeBootstrapResult {
  const HomeBootstrapResult({
    required this.shouldLoadJobs,
    required this.shouldRefreshLocation,
  });

  final bool shouldLoadJobs;
  final bool shouldRefreshLocation;
}
