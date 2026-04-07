import '../models/home_bootstrap_result.dart';

class HomeBootstrapService {
  const HomeBootstrapService();

  HomeBootstrapResult evaluate({
    required bool hasJobs,
    required bool isLoadingJobs,
  }) {
    return HomeBootstrapResult(
      shouldLoadJobs: !hasJobs && !isLoadingJobs,
      shouldRefreshLocation: true,
    );
  }
}
