import 'package:appmobile/models/job.dart';
import 'package:appmobile/models/job_distance_info.dart';
import 'package:appmobile/models/job_status.dart';
import 'package:appmobile/services/job_distance_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = JobDistanceService();

  Job buildJob({
    double? latitude,
    double? longitude,
  }) {
    return Job(
      id: '1',
      titulo: 'Vistoria teste',
      endereco: 'Rua A, 100',
      nomeCliente: 'Cliente',
      status: JobStatus.aceito,
      latitude: latitude,
      longitude: longitude,
    );
  }

  test('returns pending when coordinates are unavailable', () {
    final result = service.buildDistanceInfo(
      job: buildJob(),
      currentLatitude: null,
      currentLongitude: null,
      useDistanceMetrics: true,
    );

    expect(result.label, JobDistanceInfo.pending().label);
    expect(result.rangeLabel, JobDistanceInfo.pending().rangeLabel);
    expect(result.withinRange, isFalse);
  });

  test('returns on-site when distance is under threshold', () {
    final result = service.buildDistanceInfo(
      job: buildJob(latitude: -23.0, longitude: -46.0),
      currentLatitude: -23.0,
      currentLongitude: -46.0,
      useDistanceMetrics: true,
    );

    expect(result.label, JobDistanceInfo.onSite().label);
    expect(result.rangeLabel, JobDistanceInfo.onSite().rangeLabel);
    expect(result.withinRange, isTrue);
  });

  test('returns km label when distance is larger', () {
    final result = service.buildDistanceInfo(
      job: buildJob(latitude: -23.05, longitude: -46.05),
      currentLatitude: -23.0,
      currentLongitude: -46.0,
      useDistanceMetrics: true,
    );

    expect(result.label.contains('km de distância'), isTrue);
    expect(result.rangeLabel, 'Fora do raio');
    expect(result.withinRange, isFalse);
  });
}
