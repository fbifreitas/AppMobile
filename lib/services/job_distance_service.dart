import '../models/job.dart';
import '../models/job_distance_info.dart';
import 'location_service.dart';

class JobDistanceService {
  JobDistanceService({
    LocationService? locationService,
  }) : locationService = locationService ?? LocationService();

  final LocationService locationService;

  JobDistanceInfo buildDistanceInfo({
    required Job job,
    required double? currentLatitude,
    required double? currentLongitude,
    required bool useDistanceMetrics,
  }) {
    if (!useDistanceMetrics ||
        currentLatitude == null ||
        currentLongitude == null ||
        job.latitude == null ||
        job.longitude == null) {
      return JobDistanceInfo.pending();
    }

    final distanceMeters = locationService.calcularDistancia(
      lat1: currentLatitude,
      lon1: currentLongitude,
      lat2: job.latitude!,
      lon2: job.longitude!,
    );

    if (distanceMeters <= 80) {
      return JobDistanceInfo.onSite();
    }

    final withinRange = distanceMeters <= 100;
    final rangeLabel = withinRange ? 'Dentro do raio' : 'Fora do raio';

    if (distanceMeters < 1000) {
      return JobDistanceInfo(
        label: '${distanceMeters.toStringAsFixed(0)} m de distância',
        rangeLabel: rangeLabel,
        withinRange: withinRange,
      );
    }

    return JobDistanceInfo(
      label: '${(distanceMeters / 1000).toStringAsFixed(1)} km de distância',
      rangeLabel: rangeLabel,
      withinRange: withinRange,
    );
  }
}
