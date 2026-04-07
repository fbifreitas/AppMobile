import 'data_retention_policy_service.dart';

class LocalDataCleanupService {
  final DataRetentionPolicyService policyService;

  const LocalDataCleanupService({
    this.policyService = const DataRetentionPolicyService(),
  });

  List<String> buildCleanupPlan() {
    final policies = policyService.defaultPolicies();

    return policies.map((policy) {
      return 'Escopo ${policy.scope.name}: manter até ${policy.maxEntries} item(ns) por ${policy.maxAgeDays} dia(s).';
    }).toList();
  }
}
