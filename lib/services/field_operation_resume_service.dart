import '../models/field_inspection_resume_state.dart';
import '../models/field_operation_cache_policy.dart';
import 'field_operation_local_store.dart';

class FieldOperationResumeService {
  static const _storagePrefix = 'field_resume_state_';

  final FieldOperationLocalStore localStore;
  final FieldOperationCachePolicy cachePolicy;

  const FieldOperationResumeService({
    this.localStore = const FieldOperationLocalStore(),
    this.cachePolicy = const FieldOperationCachePolicy(),
  });

  String _key(String jobId) => '$_storagePrefix$jobId';

  Future<void> saveState(FieldInspectionResumeState state) async {
    await localStore.saveMap(_key(state.jobId), state.toJson());
  }

  Future<FieldInspectionResumeState?> loadState(String jobId) async {
    final raw = await localStore.loadMap(_key(jobId));
    if (raw == null) return null;

    final state = FieldInspectionResumeState.fromJson(raw);
    final age = DateTime.now().difference(state.savedAt);
    if (age > cachePolicy.staleResumeAfter) {
      await clearState(jobId);
      return null;
    }
    return state;
  }

  Future<void> clearState(String jobId) async {
    await localStore.remove(_key(jobId));
  }
}
