import 'package:appmobile/services/home_bootstrap_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = HomeBootstrapService();

  test('loads jobs and refreshes location when home starts empty', () {
    final result = service.evaluate(
      hasJobs: false,
      isLoadingJobs: false,
    );

    expect(result.shouldLoadJobs, isTrue);
    expect(result.shouldRefreshLocation, isTrue);
  });

  test('does not load jobs when jobs are already present', () {
    final result = service.evaluate(
      hasJobs: true,
      isLoadingJobs: false,
    );

    expect(result.shouldLoadJobs, isFalse);
    expect(result.shouldRefreshLocation, isTrue);
  });

  test('does not load jobs when loading is already in progress', () {
    final result = service.evaluate(
      hasJobs: false,
      isLoadingJobs: true,
    );

    expect(result.shouldLoadJobs, isFalse);
    expect(result.shouldRefreshLocation, isTrue);
  });
}
