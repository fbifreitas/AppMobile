'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';

type Overview = {
  totalRequests24h: number;
  errorRequests24h: number;
  retryOrDuplicateCount24h: number;
  operationalBacklog: number;
  pendingIntake: number;
  reportsReadyForSign: number;
  pendingConfigApprovals: number;
  alertCount: number;
};

type EndpointMetric = {
  endpointKey: string;
  totalRequests: number;
  successCount: number;
  warningCount: number;
  errorCount: number;
  retryCount: number;
  p95LatencyMs: number;
  lastHttpStatus: number | null;
  lastSeenAt: string | null;
};

type AlertItem = {
  code: string;
  severity: string;
  title: string;
  description: string;
  endpointKey: string;
  metricValue: number;
  triggeredAt: string | null;
};

type RecentEventItem = {
  occurredAt: string;
  channel: string;
  eventType: string;
  endpointKey: string | null;
  outcome: string;
  httpStatus: number | null;
  latencyMs: number | null;
  summary: string | null;
  correlationId: string | null;
  traceId: string | null;
  protocolId: string | null;
  jobId: number | null;
  processId: number | null;
  reportId: number | null;
};

type RetentionSummary = {
  retentionDays: number;
  trackedEvents: number;
  expiringEvents: number;
  oldestRetainedEventAt: string | null;
  lastCleanupAt: string | null;
  lastCleanupDeletedCount: number;
};

type ContinuitySummary = {
  status: string;
  checklist: Array<{
    code: string;
    status: string;
    title: string;
    action: string;
  }>;
};

type ControlTowerResponse = {
  generatedAt: string;
  overview: Overview;
  intelligence: IntelligenceAnalyticsReadinessResponse;
  endpointMetrics: EndpointMetric[];
  alerts: AlertItem[];
  recentEvents: RecentEventItem[];
  retention: RetentionSummary;
  continuity: ContinuitySummary;
};

type AuthSessionResponse = {
  tenantId: string;
  userId: number;
  email: string;
  membershipRole: string;
  membershipStatus: string;
};

type ManualResolutionQueueItem = {
  caseId: number;
  caseNumber: string;
  caseStatus: string;
  propertyAddress: string;
  latestRunId: number;
  latestRunStatus: string;
  retryable: boolean;
  attemptCount: number;
  confidenceScore: number | null;
  latestErrorCode: string | null;
  latestErrorMessage: string | null;
  executionPlanSnapshotId: number | null;
  executionPlanStatus: string | null;
  jobId: number | null;
  jobStatus: string | null;
  pendingReasons: string[];
  queuedAt: string;
};

type ManualResolutionQueueResponse = {
  total: number;
  items: ManualResolutionQueueItem[];
};

type IntelligenceAnalyticsReadinessResponse = {
  enrichmentRuns: number;
  reviewRequiredRuns: number;
  failedRuns: number;
  executionPlans: number;
  publishedExecutionPlans: number;
  reviewRequiredExecutionPlans: number;
  inspectionReturnArtifacts: number;
  fieldEvidenceRecords: number;
  manualResolutionCases: number;
  reportBasisCases: number;
};

type OperationalReferenceProfileItem = {
  id: number;
  tenantId: string | null;
  scopeType: string;
  sourceType: string;
  activeFlag: boolean;
  assetType: string;
  assetSubtype: string;
  refinedAssetSubtype: string | null;
  propertyStandard: string | null;
  regionState: string | null;
  regionCity: string | null;
  regionDistrict: string | null;
  priorityWeight: number;
  confidenceScore: number | null;
  feedbackCount: number;
  editable: boolean;
  candidateSubtypes: string[];
  photoLocations: string[];
  compositionProfileCount: number;
  createdAt: string | null;
  updatedAt: string | null;
};

type OperationalReferenceProfilesResponse = {
  total: number;
  items: OperationalReferenceProfileItem[];
};

type OperationalReferenceRebuildResponse = {
  tenantId: string;
  rebuiltHistoricalProfiles: number;
  rebuiltRegionalProfiles: number;
  totalProfilesAfterRebuild: number;
  generatedAt: string;
};

type CaptureGatePolicyResponse = {
  tenantId: string;
  policyVersion: string;
  gates: Array<{
    code: string;
    title: string;
    description: string;
    blockingCapture: boolean;
    source: string;
  }>;
};

type NormativeMatrixResponse = {
  tenantId: string;
  matrixVersion: string;
  profiles: Array<{
    assetType: string;
    assetSubtype: string;
    refinedAssetSubtype: string | null;
    rules: Array<{
      dimension: string;
      title: string;
      required: boolean;
      minPhotos: number;
      maxPhotos: number | null;
      blockingStage: string;
      justificationAllowed: boolean;
      acceptedAlternatives: string[];
    }>;
  }>;
};

type ResolvePreviewResponse = {
  caseId: number;
  caseNumber: string;
  propertyAddress: string;
  classification: {
    assetType: string;
    assetSubtype: string;
    candidateAssetSubtypes: string[];
    context: string | null;
  };
  captureGatePolicy: CaptureGatePolicyResponse;
  normativeProfile: NormativeMatrixResponse['profiles'][number] | null;
  previewNotes: string[];
};

type ManualSubtypeResolutionResponse = {
  snapshotId: number;
  caseId: number;
  status: string;
  createdAt: string;
  publishedAt: string | null;
  plan: {
    assetType?: string;
    assetSubtype?: string | null;
    reviewReasons?: string[];
  };
};

type ReferenceProfileFormState = {
  profileId: number | null;
  scopeType: string;
  activeFlag: boolean;
  assetType: string;
  assetSubtype: string;
  refinedAssetSubtype: string;
  propertyStandard: string;
  regionState: string;
  regionCity: string;
  regionDistrict: string;
  priorityWeight: string;
  confidenceScore: string;
  candidateSubtypes: string;
  photoLocations: string;
};

type ReportBasisResponse = {
  caseId: number;
  caseNumber: string;
  caseStatus: string;
  propertyAddress: string;
  latestRun: {
    id: number;
    status: string;
    retryable: boolean;
    attemptCount: number;
    confidenceScore: number | null;
    createdAt: string;
    completedAt: string | null;
    facts: unknown;
    qualityFlags: unknown;
    errorCode: string | null;
    errorMessage: string | null;
  } | null;
  latestExecutionPlan: {
    snapshotId: number;
    status: string;
    createdAt: string;
    publishedAt: string | null;
    plan: {
      planVersion?: string;
      providerName?: string;
      confidenceScore?: number;
      requiresManualReview?: boolean;
      propertyProfile?: {
        address?: string;
        taxonomy?: string;
        inspectionType?: string;
      };
      step1Config?: {
        enabled?: boolean;
        initialAssetType?: string;
        initialAssetSubtype?: string | null;
        candidateAssetSubtypes?: string[];
        initialContext?: string;
      };
      step2Config?: {
        enabled?: boolean;
        mandatory?: boolean;
        requiredEvidence?: string[];
      };
      cameraConfig?: {
        mode?: string;
        macroLocation?: string;
        capturePlan?: Array<{
          macroLocal?: string;
          environment?: string;
          element?: string;
          material?: string;
          condition?: string;
          required?: boolean;
          minPhotos?: number;
        }>;
      };
      fieldAlerts?: string[];
      traceability?: {
        sourceRunId?: number;
        requestStorageKey?: string;
        responseNormalizedStorageKey?: string;
        researchLinks?: string[];
      };
    };
  } | null;
  latestJob: {
    id: number;
    status: string;
    assignedTo: number | null;
    deadlineAt: string | null;
    createdAt: string;
  } | null;
  latestReturnArtifact: {
    inspectionId: number;
    submissionId: number | null;
    jobId: number;
    executionPlanSnapshotId: number | null;
    rawStorageKey: string;
    normalizedStorageKey: string;
    summary: unknown;
    createdAt: string;
  } | null;
  fieldEvidence: Array<{
    inspectionId: number;
    jobId: number;
    sourceSection: string;
    macroLocation: string | null;
    environmentName: string | null;
    elementName: string | null;
    required: boolean;
    minPhotos: number | null;
    capturedPhotos: number | null;
    status: string;
    evidence: unknown;
    createdAt: string;
  }>;
};

function formatReason(reason: string): string {
  return reason
    .toLowerCase()
    .split('_')
    .map((token) => token.charAt(0).toUpperCase() + token.slice(1))
    .join(' ');
}

function formatScalar(value: unknown): string {
  if (value == null) {
    return '-';
  }
  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  return JSON.stringify(value);
}

function toRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

function formatRoute(parts: Array<string | null | undefined>): string {
  const resolved = parts.filter((part): part is string => Boolean(part && part.trim()));
  return resolved.length > 0 ? resolved.join(' > ') : '-';
}

function formatTimestamp(value: string | null | undefined): string {
  if (!value) {
    return '-';
  }
  return new Date(value).toLocaleString('pt-BR');
}

function parseCsv(value: string): string[] {
  return value
    .split(',')
    .map((item) => item.trim())
    .filter((item) => item.length > 0);
}

function emptyReferenceProfileForm(): ReferenceProfileFormState {
  return {
    profileId: null,
    scopeType: 'REGIONAL_REFERENCE',
    activeFlag: true,
    assetType: 'Urbano',
    assetSubtype: '',
    refinedAssetSubtype: '',
    propertyStandard: '',
    regionState: '',
    regionCity: '',
    regionDistrict: '',
    priorityWeight: '140',
    confidenceScore: '0.92',
    candidateSubtypes: '',
    photoLocations: ''
  };
}

export default function BackofficeOperationsPage() {
  const [session, setSession] = useState<AuthSessionResponse | null>(null);
  const [sessionLoading, setSessionLoading] = useState(true);
  const [dashboard, setDashboard] = useState<ControlTowerResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [intelligenceLoading, setIntelligenceLoading] = useState(true);
  const [reportBasisLoading, setReportBasisLoading] = useState(false);
  const [runningRetention, setRunningRetention] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [manualResolutionQueue, setManualResolutionQueue] = useState<ManualResolutionQueueItem[]>([]);
  const [manualResolutionTotal, setManualResolutionTotal] = useState(0);
  const [selectedCaseId, setSelectedCaseId] = useState<number | null>(null);
  const [reportBasis, setReportBasis] = useState<ReportBasisResponse | null>(null);
  const [triggeringCaseId, setTriggeringCaseId] = useState<number | null>(null);
  const [reasonFilter, setReasonFilter] = useState<string>('ALL');
  const [runStatusFilter, setRunStatusFilter] = useState<string>('ALL');
  const [sortMode, setSortMode] = useState<'RECENT' | 'LOWEST_CONFIDENCE' | 'MOST_PENDING_REASONS'>('RECENT');
  const [dashboardLoadedAt, setDashboardLoadedAt] = useState<string | null>(null);
  const [workspaceLoadedAt, setWorkspaceLoadedAt] = useState<string | null>(null);
  const [referenceProfiles, setReferenceProfiles] = useState<OperationalReferenceProfileItem[]>([]);
  const [loadingReferenceProfiles, setLoadingReferenceProfiles] = useState(true);
  const [rebuildingReferenceProfiles, setRebuildingReferenceProfiles] = useState(false);
  const [referenceProfilesLoadedAt, setReferenceProfilesLoadedAt] = useState<string | null>(null);
  const [referenceProfilesMessage, setReferenceProfilesMessage] = useState<string | null>(null);
  const [referenceProfileForm, setReferenceProfileForm] = useState<ReferenceProfileFormState>(emptyReferenceProfileForm);
  const [savingReferenceProfile, setSavingReferenceProfile] = useState(false);
  const [togglingReferenceProfileId, setTogglingReferenceProfileId] = useState<number | null>(null);
  const [captureGatePolicy, setCaptureGatePolicy] = useState<CaptureGatePolicyResponse | null>(null);
  const [normativeMatrix, setNormativeMatrix] = useState<NormativeMatrixResponse | null>(null);
  const [resolvePreview, setResolvePreview] = useState<ResolvePreviewResponse | null>(null);
  const [captureGatePolicyLoading, setCaptureGatePolicyLoading] = useState(true);
  const [normativeMatrixLoading, setNormativeMatrixLoading] = useState(true);
  const [resolvePreviewLoading, setResolvePreviewLoading] = useState(false);
  const [manualSubtypeOverride, setManualSubtypeOverride] = useState("");
  const [manualSubtypeNote, setManualSubtypeNote] = useState("");
  const [resolvingSubtypeCaseId, setResolvingSubtypeCaseId] = useState<number | null>(null);

  const loadSession = useCallback(async () => {
    setSessionLoading(true);
    try {
      const response = await fetch('/api/auth/me');
      if (!response.ok) {
        throw new Error(`Failed to load session (${response.status})`);
      }
      const payload: AuthSessionResponse = await response.json();
      setSession(payload);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while loading session');
    } finally {
      setSessionLoading(false);
    }
  }, []);

  const loadDashboard = useCallback(async () => {
    if (!session?.tenantId) {
      return;
    }
    setLoading(true);
    setError(null);

    try {
      const response = await fetch('/api/operations/control-tower');
      if (!response.ok) {
        throw new Error(`Failed to load control tower (${response.status})`);
      }

      const payload: ControlTowerResponse = await response.json();
      setDashboard(payload);
      setDashboardLoadedAt(new Date().toISOString());
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while loading control tower');
    } finally {
      setLoading(false);
    }
  }, [session?.tenantId]);

  useEffect(() => {
    void loadSession();
  }, [loadSession]);

  useEffect(() => {
    if (!session) {
      return;
    }
    void loadDashboard();
  }, [loadDashboard, session]);

  const loadReportBasis = useCallback(async (caseId: number) => {
    if (!session?.tenantId) {
      return;
    }
    setReportBasisLoading(true);
    setError(null);

    try {
      const response = await fetch(`/api/intelligence/cases/${caseId}/report-basis`);
      if (!response.ok) {
        throw new Error(`Failed to load report basis (${response.status})`);
      }

      const payload: ReportBasisResponse = await response.json();
      setReportBasis(payload);
      setSelectedCaseId(caseId);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while loading report basis');
    } finally {
      setReportBasisLoading(false);
    }
  }, [session?.tenantId]);

  const loadCaptureGatePolicy = useCallback(async () => {
    if (!session?.tenantId) {
      return;
    }
    setCaptureGatePolicyLoading(true);
    setError(null);

    try {
      const response = await fetch('/api/intelligence/capture-gates');
      if (!response.ok) {
        throw new Error(`Failed to load capture gate policy (${response.status})`);
      }
      const payload: CaptureGatePolicyResponse = await response.json();
      setCaptureGatePolicy(payload);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while loading capture gate policy');
    } finally {
      setCaptureGatePolicyLoading(false);
    }
  }, [session?.tenantId]);

  const loadNormativeMatrix = useCallback(async () => {
    if (!session?.tenantId) {
      return;
    }
    setNormativeMatrixLoading(true);
    setError(null);

    try {
      const response = await fetch('/api/intelligence/normative-matrix');
      if (!response.ok) {
        throw new Error(`Failed to load normative matrix (${response.status})`);
      }
      const payload: NormativeMatrixResponse = await response.json();
      setNormativeMatrix(payload);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while loading normative matrix');
    } finally {
      setNormativeMatrixLoading(false);
    }
  }, [session?.tenantId]);

  const loadResolvePreview = useCallback(async (caseId: number) => {
    if (!session?.tenantId) {
      return;
    }
    setResolvePreviewLoading(true);
    setError(null);

    try {
      const response = await fetch(`/api/intelligence/cases/${caseId}/resolve-preview`);
      if (!response.ok) {
        throw new Error(`Failed to load resolve preview (${response.status})`);
      }
      const payload: ResolvePreviewResponse = await response.json();
      setResolvePreview(payload);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while loading resolve preview');
    } finally {
      setResolvePreviewLoading(false);
    }
  }, [session?.tenantId]);

  const loadIntelligenceWorkspace = useCallback(async () => {
    if (!session?.tenantId) {
      return;
    }
    setIntelligenceLoading(true);
    setError(null);

    try {
      const response = await fetch('/api/intelligence/manual-resolution-queue?limit=12');
      if (!response.ok) {
        throw new Error(`Failed to load manual resolution queue (${response.status})`);
      }
      const payload: ManualResolutionQueueResponse = await response.json();
      const items = payload.items ?? [];

      setManualResolutionQueue(items);
      setManualResolutionTotal(payload.total ?? 0);

      if (items.length === 0) {
        setSelectedCaseId(null);
        setReportBasis(null);
        setResolvePreview(null);
        return;
      }

      const nextCaseId = items.some((item) => item.caseId === selectedCaseId)
        ? selectedCaseId
        : items[0].caseId;

      if (nextCaseId != null) {
        await loadReportBasis(nextCaseId);
        await loadResolvePreview(nextCaseId);
      }
      setWorkspaceLoadedAt(new Date().toISOString());
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while loading intelligence workspace');
    } finally {
      setIntelligenceLoading(false);
    }
  }, [loadReportBasis, loadResolvePreview, selectedCaseId, session?.tenantId]);

  const loadReferenceProfiles = useCallback(async () => {
    if (!session?.tenantId) {
      return;
    }
    setLoadingReferenceProfiles(true);
    setError(null);

    try {
      const response = await fetch('/api/intelligence/reference-profiles');
      if (!response.ok) {
        throw new Error(`Failed to load reference profiles (${response.status})`);
      }
      const payload: OperationalReferenceProfilesResponse = await response.json();
      setReferenceProfiles(payload.items ?? []);
      setReferenceProfilesLoadedAt(new Date().toISOString());
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while loading reference profiles');
    } finally {
      setLoadingReferenceProfiles(false);
    }
  }, [session?.tenantId]);

  const rebuildReferenceProfiles = useCallback(async () => {
    if (!session?.tenantId) {
      return;
    }
    setRebuildingReferenceProfiles(true);
    setError(null);
    setReferenceProfilesMessage(null);

    try {
      const response = await fetch('/api/intelligence/reference-profiles/rebuild', {
        method: 'POST'
      });
      if (!response.ok) {
        throw new Error(`Failed to rebuild reference profiles (${response.status})`);
      }
      const payload: OperationalReferenceRebuildResponse = await response.json();
      setReferenceProfilesMessage(
        `Reference profiles rebuilt for ${payload.tenantId}. Historical: ${payload.rebuiltHistoricalProfiles}. Regional: ${payload.rebuiltRegionalProfiles}. Total: ${payload.totalProfilesAfterRebuild}.`
      );
      await loadReferenceProfiles();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while rebuilding reference profiles');
    } finally {
      setRebuildingReferenceProfiles(false);
    }
  }, [loadReferenceProfiles, session?.tenantId]);

  const startReferenceProfileCreate = useCallback(() => {
    setReferenceProfileForm(emptyReferenceProfileForm());
    setReferenceProfilesMessage(null);
  }, []);

  const startReferenceProfileEdit = useCallback((profile: OperationalReferenceProfileItem) => {
    setReferenceProfileForm({
      profileId: profile.id,
      scopeType: profile.scopeType,
      activeFlag: profile.activeFlag,
      assetType: profile.assetType,
      assetSubtype: profile.assetSubtype,
      refinedAssetSubtype: profile.refinedAssetSubtype ?? '',
      propertyStandard: profile.propertyStandard ?? '',
      regionState: profile.regionState ?? '',
      regionCity: profile.regionCity ?? '',
      regionDistrict: profile.regionDistrict ?? '',
      priorityWeight: String(profile.priorityWeight),
      confidenceScore: profile.confidenceScore != null ? String(profile.confidenceScore) : '',
      candidateSubtypes: profile.candidateSubtypes.join(', '),
      photoLocations: profile.photoLocations.join(', ')
    });
    setReferenceProfilesMessage(`Editing profile ${profile.id} (${profile.assetType} > ${profile.assetSubtype}).`);
  }, []);

  const saveReferenceProfile = useCallback(async () => {
    if (!session?.tenantId) {
      return;
    }
    setSavingReferenceProfile(true);
    setError(null);
    setReferenceProfilesMessage(null);

    try {
      const payload = {
        scopeType: referenceProfileForm.scopeType,
        activeFlag: referenceProfileForm.activeFlag,
        assetType: referenceProfileForm.assetType,
        assetSubtype: referenceProfileForm.assetSubtype,
        refinedAssetSubtype: referenceProfileForm.refinedAssetSubtype || null,
        propertyStandard: referenceProfileForm.propertyStandard || null,
        regionState: referenceProfileForm.regionState || null,
        regionCity: referenceProfileForm.regionCity || null,
        regionDistrict: referenceProfileForm.regionDistrict || null,
        priorityWeight: referenceProfileForm.priorityWeight ? Number(referenceProfileForm.priorityWeight) : null,
        confidenceScore: referenceProfileForm.confidenceScore ? Number(referenceProfileForm.confidenceScore) : null,
        candidateSubtypes: parseCsv(referenceProfileForm.candidateSubtypes),
        photoLocations: parseCsv(referenceProfileForm.photoLocations)
      };

      const endpoint = referenceProfileForm.profileId == null
        ? '/api/intelligence/reference-profiles'
        : `/api/intelligence/reference-profiles/${referenceProfileForm.profileId}`;
      const method = referenceProfileForm.profileId == null ? 'POST' : 'PUT';

      const response = await fetch(endpoint, {
        method,
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });
      if (!response.ok) {
        throw new Error(`Failed to save reference profile (${response.status})`);
      }

      const saved: OperationalReferenceProfileItem = await response.json();
      setReferenceProfilesMessage(
        referenceProfileForm.profileId == null
          ? `Reference profile ${saved.id} created successfully.`
          : `Reference profile ${saved.id} updated successfully.`
      );
      await loadReferenceProfiles();
      startReferenceProfileEdit(saved);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while saving reference profile');
    } finally {
      setSavingReferenceProfile(false);
    }
  }, [loadReferenceProfiles, referenceProfileForm, session?.tenantId, startReferenceProfileEdit]);

  const toggleReferenceProfile = useCallback(async (profile: OperationalReferenceProfileItem, nextActive: boolean) => {
    setTogglingReferenceProfileId(profile.id);
    setError(null);
    setReferenceProfilesMessage(null);

    try {
      const response = await fetch(`/api/intelligence/reference-profiles/${profile.id}/${nextActive ? 'activate' : 'deactivate'}`, {
        method: 'POST'
      });
      if (!response.ok) {
        throw new Error(`Failed to ${nextActive ? 'activate' : 'deactivate'} reference profile (${response.status})`);
      }
      await loadReferenceProfiles();
      setReferenceProfilesMessage(`Reference profile ${profile.id} ${nextActive ? 'activated' : 'deactivated'} successfully.`);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while changing reference profile state');
    } finally {
      setTogglingReferenceProfileId(null);
    }
  }, [loadReferenceProfiles]);

  useEffect(() => {
    if (!session) {
      return;
    }
    void loadIntelligenceWorkspace();
  }, [loadIntelligenceWorkspace, session]);

  useEffect(() => {
    if (!session) {
      return;
    }
    void loadReferenceProfiles();
  }, [loadReferenceProfiles, session]);

  useEffect(() => {
    if (!session) {
      return;
    }
    void loadCaptureGatePolicy();
    void loadNormativeMatrix();
  }, [loadCaptureGatePolicy, loadNormativeMatrix, session]);

  const handleTriggerEnrichment = useCallback(async (caseId: number) => {
    if (!session?.tenantId) {
      return;
    }
    setTriggeringCaseId(caseId);
    setError(null);
    setMessage(null);

    try {
      const response = await fetch(`/api/intelligence/cases/${caseId}/enrichment/trigger`, {
        method: 'POST'
      });
      if (!response.ok) {
        throw new Error(`Failed to trigger enrichment (${response.status})`);
      }

      setMessage(`Automatic analysis queued again for case ${caseId}. Refreshing workspace...`);
      await loadIntelligenceWorkspace();
      await loadReportBasis(caseId);
      await loadResolvePreview(caseId);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while triggering enrichment');
    } finally {
      setTriggeringCaseId(null);
    }
  }, [loadIntelligenceWorkspace, loadReportBasis, loadResolvePreview, session?.tenantId]);

  const handleManualSubtypeResolution = useCallback(async (caseId: number) => {
    if (!session?.tenantId || !manualSubtypeOverride.trim()) {
      return;
    }
    setResolvingSubtypeCaseId(caseId);
    setError(null);
    setMessage(null);

    try {
      const response = await fetch(`/api/intelligence/cases/${caseId}/manual-resolution/subtype`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          assetSubtype: manualSubtypeOverride.trim(),
          note: manualSubtypeNote.trim() || null
        })
      });
      if (!response.ok) {
        throw new Error(`Failed to apply manual subtype resolution (${response.status})`);
      }

      const payload: ManualSubtypeResolutionResponse = await response.json();
      setMessage(
        `Manual subtype resolution applied for case ${caseId}. Plan republished as ${payload.plan.assetType ?? '-'} > ${payload.plan.assetSubtype ?? '-'}.`
      );
      await loadIntelligenceWorkspace();
      await loadReportBasis(caseId);
      await loadResolvePreview(caseId);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while applying manual subtype resolution');
    } finally {
      setResolvingSubtypeCaseId(null);
    }
  }, [loadIntelligenceWorkspace, loadReportBasis, loadResolvePreview, manualSubtypeNote, manualSubtypeOverride, session?.tenantId]);

  const manualResolutionSummary = useMemo(() => {
    return {
      reviewRequired: manualResolutionQueue.filter((item) => item.pendingReasons.includes('ENRICHMENT_REVIEW_REQUIRED')).length,
      temporarilyUnavailable: manualResolutionQueue.filter((item) => item.pendingReasons.includes('ENRICHMENT_TEMPORARILY_UNAVAILABLE')).length,
      planReviewRequired: manualResolutionQueue.filter((item) => item.pendingReasons.includes('EXECUTION_PLAN_REVIEW_REQUIRED')).length,
      enrichmentFailed: manualResolutionQueue.filter((item) => item.pendingReasons.includes('ENRICHMENT_FAILED')).length,
      planMissing: manualResolutionQueue.filter((item) => item.pendingReasons.includes('EXECUTION_PLAN_MISSING')).length
    };
  }, [manualResolutionQueue]);

  const pendingReasonOptions = useMemo(() => {
    return Array.from(new Set(manualResolutionQueue.flatMap((item) => item.pendingReasons)));
  }, [manualResolutionQueue]);

  const runStatusOptions = useMemo(() => {
    return Array.from(new Set(manualResolutionQueue.map((item) => item.latestRunStatus)));
  }, [manualResolutionQueue]);

  const filteredManualResolutionQueue = useMemo(() => {
    const filtered = manualResolutionQueue.filter((item) => {
      if (reasonFilter !== 'ALL' && !item.pendingReasons.includes(reasonFilter)) {
        return false;
      }
      if (runStatusFilter !== 'ALL' && item.latestRunStatus !== runStatusFilter) {
        return false;
      }
      return true;
    });

    const ranked = [...filtered];
    ranked.sort((left, right) => {
      if (sortMode === 'LOWEST_CONFIDENCE') {
        const leftConfidence = left.confidenceScore ?? Number.POSITIVE_INFINITY;
        const rightConfidence = right.confidenceScore ?? Number.POSITIVE_INFINITY;
        if (leftConfidence !== rightConfidence) {
          return leftConfidence - rightConfidence;
        }
      }

      if (sortMode === 'MOST_PENDING_REASONS') {
        if (left.pendingReasons.length !== right.pendingReasons.length) {
          return right.pendingReasons.length - left.pendingReasons.length;
        }
      }

      return new Date(right.queuedAt).getTime() - new Date(left.queuedAt).getTime();
    });

    return ranked;
  }, [manualResolutionQueue, reasonFilter, runStatusFilter, sortMode]);

  const handleRunRetention = useCallback(async () => {
    if (!session?.tenantId) {
      return;
    }
    setRunningRetention(true);
    setError(null);
    setMessage(null);

    try {
      const response = await fetch('/api/operations/control-tower/retention/run', { method: 'POST' });
      if (!response.ok) {
        throw new Error(`Failed to run retention cleanup (${response.status})`);
      }

      const payload = (await response.json()) as { deletedEvents: number };
      setMessage(`Retention cleanup executed. Deleted events: ${payload.deletedEvents}`);
      await loadDashboard();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while running retention cleanup');
    } finally {
      setRunningRetention(false);
    }
  }, [loadDashboard, session?.tenantId]);

  const cards = useMemo(() => {
    if (!dashboard) {
      return [];
    }
    return [
      ['Requests 24h', dashboard.overview.totalRequests24h],
      ['Errors 24h', dashboard.overview.errorRequests24h],
      ['Retries / duplicates', dashboard.overview.retryOrDuplicateCount24h],
      ['Operational backlog', dashboard.overview.operationalBacklog],
      ['Pending intake', dashboard.overview.pendingIntake],
      ['Ready for sign', dashboard.overview.reportsReadyForSign],
      ['Pending config approvals', dashboard.overview.pendingConfigApprovals],
      ['Active alerts', dashboard.overview.alertCount]
    ];
  }, [dashboard]);

  const normativeProfilePreview = useMemo(() => {
    if (resolvePreview?.normativeProfile) {
      return resolvePreview.normativeProfile;
    }
    return normativeMatrix?.profiles?.[0] ?? null;
  }, [normativeMatrix, resolvePreview]);

  const manualSubtypeCandidates = useMemo(() => {
    const values = [
      ...(resolvePreview?.classification.candidateAssetSubtypes ?? []),
      ...(reportBasis?.latestExecutionPlan?.plan?.step1Config?.candidateAssetSubtypes ?? [])
    ]
      .map((item) => item?.trim())
      .filter((item): item is string => Boolean(item));
    return Array.from(new Set(values));
  }, [reportBasis?.latestExecutionPlan?.plan?.step1Config?.candidateAssetSubtypes, resolvePreview?.classification.candidateAssetSubtypes]);

  useEffect(() => {
    if (manualSubtypeCandidates.length === 0) {
      setManualSubtypeOverride("");
      return;
    }
    setManualSubtypeOverride((current) => {
      if (current && manualSubtypeCandidates.includes(current)) {
        return current;
      }
      return manualSubtypeCandidates[0];
    });
  }, [manualSubtypeCandidates]);

  return (
    <main className="operations-shell">
      <section className="page-header">
        <div>
          <p className="eyebrow">FW-005 + BOW-150 + INT-009/010/018/019/020</p>
          <h1>Operational control tower</h1>
          <p className="subtitle">
            Unified operational visibility for config, finalized inspections, valuation and reports.
          </p>
          <p className="context-line">
            {sessionLoading
              ? 'Loading authenticated workspace...'
              : session
                ? `Tenant ${session.tenantId} · ${session.email} · ${session.membershipRole}`
                : 'Session unavailable'}
          </p>
        </div>
        <div className="hero-actions">
          <a className="ghost" href="/">Back to dashboard</a>
          <button type="button" disabled={runningRetention} onClick={() => void handleRunRetention()}>
            {runningRetention ? 'Running retention...' : 'Run retention cleanup'}
          </button>
          <button type="button" disabled={loading} onClick={() => void loadDashboard()}>
            Reload control tower
          </button>
          <button type="button" disabled={intelligenceLoading} onClick={() => void loadIntelligenceWorkspace()}>
            Reload intelligence workspace
          </button>
          <button type="button" disabled={rebuildingReferenceProfiles} onClick={() => void rebuildReferenceProfiles()}>
            {rebuildingReferenceProfiles ? 'Rebuilding references...' : 'Rebuild reference profiles'}
          </button>
        </div>
      </section>

      {error ? <div className="error-box">{error}</div> : null}
      {message ? <div className="message-box">{message}</div> : null}
      {referenceProfilesMessage ? <div className="message-box">{referenceProfilesMessage}</div> : null}

      <section className="stats-grid">
        {cards.map(([label, value]) => (
          <article className="stat-card" key={label}>
            <span>{label}</span>
            <strong>{value}</strong>
          </article>
        ))}
      </section>

      <section className="workspace-grid">
        <article className="panel feature-panel">
          <h2>Control tower overview</h2>
          <p>Monitors alerts, endpoint health, recent events and backlog for the authenticated tenant.</p>
          <dl className="summary-list">
            <div>
              <dt>Tenant</dt>
              <dd>{session?.tenantId ?? '-'}</dd>
            </div>
            <div>
              <dt>Last reload</dt>
              <dd>{formatTimestamp(dashboardLoadedAt)}</dd>
            </div>
            <div>
              <dt>Alerts</dt>
              <dd>{dashboard?.overview.alertCount ?? '-'}</dd>
            </div>
          </dl>
        </article>

        <article className="panel feature-panel">
          <h2>Retention cleanup</h2>
          <p>Runs controlled cleanup of control-tower observability records without affecting jobs, cases or reports.</p>
          <dl className="summary-list">
            <div>
              <dt>Retention days</dt>
              <dd>{dashboard?.retention.retentionDays ?? '-'}</dd>
            </div>
            <div>
              <dt>Last cleanup</dt>
              <dd>{formatTimestamp(dashboard?.retention.lastCleanupAt ?? null)}</dd>
            </div>
            <div>
              <dt>Deleted last run</dt>
              <dd>{dashboard?.retention.lastCleanupDeletedCount ?? '-'}</dd>
            </div>
          </dl>
        </article>

        <article className="panel feature-panel">
          <h2>Operational references</h2>
          <p>Persists the global, regional and historical profiles used to derive camera composition before the job reaches mobile.</p>
          <dl className="summary-list">
            <div>
              <dt>Total profiles</dt>
              <dd>{referenceProfiles.length}</dd>
            </div>
            <div>
              <dt>Last reload</dt>
              <dd>{formatTimestamp(referenceProfilesLoadedAt)}</dd>
            </div>
            <div>
              <dt>Current tenant</dt>
              <dd>{session?.tenantId ?? '-'}</dd>
            </div>
            <div>
              <dt>Tenant editable</dt>
              <dd>{referenceProfiles.filter((item) => item.editable).length}</dd>
            </div>
            <div>
              <dt>Field feedback</dt>
              <dd>{referenceProfiles.reduce((total, item) => total + item.feedbackCount, 0)}</dd>
            </div>
          </dl>
        </article>
      </section>

      {loading ? <p>Loading control tower...</p> : null}

      {!loading && dashboard ? (
        <>
          <section className="workspace-grid">
            <article className="panel table-panel">
              <h2>Reference profiles</h2>
              <p className="subtitle">
                Profiles used by the enrichment resolver to combine global defaults, historical learning and regional patterns.
              </p>
              {loadingReferenceProfiles ? <p>Loading reference profiles...</p> : null}
              <table>
                <thead>
                  <tr>
                    <th>Status</th>
                    <th>Scope</th>
                    <th>Type / subtype</th>
                    <th>Region</th>
                    <th>Candidates</th>
                    <th>Photo locations</th>
                    <th>Profiles</th>
                    <th>Priority</th>
                    <th>Feedback</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {referenceProfiles.slice(0, 12).map((item) => (
                    <tr key={item.id}>
                      <td>{item.activeFlag ? 'Active' : 'Inactive'}</td>
                      <td>
                        <strong>{item.scopeType}</strong>
                        <div>{item.sourceType}</div>
                      </td>
                      <td>
                        <strong>{item.assetType}</strong>
                        <div>{item.assetSubtype}</div>
                        <small>{item.refinedAssetSubtype ?? item.propertyStandard ?? '-'}</small>
                      </td>
                      <td>{formatRoute([item.regionState, item.regionCity, item.regionDistrict])}</td>
                      <td>{item.candidateSubtypes.join(', ') || '-'}</td>
                      <td>{item.photoLocations.join(', ') || '-'}</td>
                      <td>{item.compositionProfileCount}</td>
                      <td>{item.priorityWeight}</td>
                      <td>{item.feedbackCount}</td>
                      <td>
                        {item.editable ? (
                          <div className="inline-actions">
                            <button type="button" onClick={() => startReferenceProfileEdit(item)}>Edit</button>
                            <button
                              type="button"
                              disabled={togglingReferenceProfileId === item.id}
                              onClick={() => void toggleReferenceProfile(item, !item.activeFlag)}
                            >
                              {item.activeFlag ? 'Deactivate' : 'Activate'}
                            </button>
                          </div>
                        ) : (
                          <small>Seed / shared</small>
                        )}
                      </td>
                    </tr>
                  ))}
                  {!loadingReferenceProfiles && referenceProfiles.length === 0 ? (
                    <tr>
                      <td colSpan={10} className="empty-row">No operational reference profiles available for the current tenant.</td>
                    </tr>
                  ) : null}
                </tbody>
              </table>
            </article>

            <article className="panel">
              <h2>Reference governance</h2>
              <p className="subtitle">
                Create or adjust tenant-scoped reference overrides without changing code.
              </p>
              <div className="filters">
                <label>
                  Scope
                  <select
                    value={referenceProfileForm.scopeType}
                    onChange={(event) => setReferenceProfileForm((current) => ({ ...current, scopeType: event.target.value }))}
                  >
                    <option value="GLOBAL_REFERENCE">Global override</option>
                    <option value="REGIONAL_REFERENCE">Regional override</option>
                    <option value="HISTORICAL_REFERENCE">Historical override</option>
                  </select>
                </label>
                <label>
                  Asset type
                  <input
                    value={referenceProfileForm.assetType}
                    onChange={(event) => setReferenceProfileForm((current) => ({ ...current, assetType: event.target.value }))}
                  />
                </label>
                <label>
                  Asset subtype
                  <input
                    value={referenceProfileForm.assetSubtype}
                    onChange={(event) => setReferenceProfileForm((current) => ({ ...current, assetSubtype: event.target.value }))}
                  />
                </label>
                <label>
                  Refined subtype
                  <input
                    value={referenceProfileForm.refinedAssetSubtype}
                    onChange={(event) => setReferenceProfileForm((current) => ({ ...current, refinedAssetSubtype: event.target.value }))}
                  />
                </label>
                <label>
                  Property standard
                  <input
                    value={referenceProfileForm.propertyStandard}
                    onChange={(event) => setReferenceProfileForm((current) => ({ ...current, propertyStandard: event.target.value }))}
                  />
                </label>
                <label>
                  Priority weight
                  <input
                    value={referenceProfileForm.priorityWeight}
                    onChange={(event) => setReferenceProfileForm((current) => ({ ...current, priorityWeight: event.target.value }))}
                  />
                </label>
                <label>
                  Confidence
                  <input
                    value={referenceProfileForm.confidenceScore}
                    onChange={(event) => setReferenceProfileForm((current) => ({ ...current, confidenceScore: event.target.value }))}
                  />
                </label>
                <label>
                  Region state
                  <input
                    value={referenceProfileForm.regionState}
                    onChange={(event) => setReferenceProfileForm((current) => ({ ...current, regionState: event.target.value }))}
                  />
                </label>
                <label>
                  Region city
                  <input
                    value={referenceProfileForm.regionCity}
                    onChange={(event) => setReferenceProfileForm((current) => ({ ...current, regionCity: event.target.value }))}
                  />
                </label>
                <label>
                  Region district
                  <input
                    value={referenceProfileForm.regionDistrict}
                    onChange={(event) => setReferenceProfileForm((current) => ({ ...current, regionDistrict: event.target.value }))}
                  />
                </label>
              </div>
              <div className="list-stack" style={{ marginTop: '12px' }}>
                <label>
                  Candidate subtypes
                  <textarea
                    rows={3}
                    value={referenceProfileForm.candidateSubtypes}
                    onChange={(event) => setReferenceProfileForm((current) => ({ ...current, candidateSubtypes: event.target.value }))}
                    placeholder="Apartamento, Apartamento alto padrao, Duplex"
                  />
                </label>
                <label>
                  Photo locations
                  <textarea
                    rows={4}
                    value={referenceProfileForm.photoLocations}
                    onChange={(event) => setReferenceProfileForm((current) => ({ ...current, photoLocations: event.target.value }))}
                    placeholder="Fachada, Cozinha, Sala de estar, Dormitorio"
                  />
                </label>
                <label>
                  Active profile
                  <select
                    value={referenceProfileForm.activeFlag ? 'true' : 'false'}
                    onChange={(event) => setReferenceProfileForm((current) => ({ ...current, activeFlag: event.target.value === 'true' }))}
                  >
                    <option value="true">Active</option>
                    <option value="false">Inactive</option>
                  </select>
                </label>
              </div>
              <div className="inline-actions" style={{ marginTop: '12px' }}>
                <button type="button" onClick={startReferenceProfileCreate}>New tenant profile</button>
                <button type="button" disabled={savingReferenceProfile} onClick={() => void saveReferenceProfile()}>
                  {savingReferenceProfile
                    ? 'Saving reference profile...'
                    : referenceProfileForm.profileId == null
                      ? 'Create reference profile'
                      : `Update profile ${referenceProfileForm.profileId}`}
                </button>
              </div>
            </article>

            <article className="panel">
              <h2>Capture gate policy</h2>
              <p className="subtitle">
                Static operational gates enforced before the camera opens on mobile.
              </p>
              {captureGatePolicyLoading ? <p>Loading capture gates...</p> : null}
              {!captureGatePolicyLoading && captureGatePolicy ? (
                <div className="list-stack">
                  <p className="section-note">
                    Version {captureGatePolicy.policyVersion} · Tenant {captureGatePolicy.tenantId}
                  </p>
                  {captureGatePolicy.gates.map((gate) => (
                    <div className="status-row" key={gate.code}>
                      <strong>{gate.blockingCapture ? 'Gate' : 'Info'}</strong>
                      <div>
                        <p>{gate.title}</p>
                        <small>{gate.description} · {gate.source}</small>
                      </div>
                    </div>
                  ))}
                </div>
              ) : null}
            </article>

            <article className="panel table-panel">
              <h2>Normative matrix</h2>
              <p className="subtitle">
                Static finalization rules with predictable min/max evidence requirements for the operation.
              </p>
              {normativeMatrixLoading ? <p>Loading normative matrix...</p> : null}
              {!normativeMatrixLoading && normativeProfilePreview ? (
                <>
                  <p className="section-note">
                    Matrix {normativeMatrix?.matrixVersion ?? '-'} · Profile {formatRoute([
                      normativeProfilePreview.assetType,
                      normativeProfilePreview.assetSubtype,
                      normativeProfilePreview.refinedAssetSubtype
                    ])}
                  </p>
                  <table>
                    <thead>
                      <tr>
                        <th>Dimension</th>
                        <th>Rule</th>
                        <th>Photos</th>
                        <th>Alternatives</th>
                      </tr>
                    </thead>
                    <tbody>
                      {normativeProfilePreview.rules.map((rule) => (
                        <tr key={`${rule.dimension}-${rule.title}`}>
                          <td>{rule.dimension}</td>
                          <td>
                            <strong>{rule.title}</strong>
                            <div>{rule.required ? 'Required' : 'Optional'} · {rule.blockingStage}</div>
                            <small>{rule.justificationAllowed ? 'Justification allowed' : 'No justification'}</small>
                          </td>
                          <td>{rule.minPhotos} / {rule.maxPhotos ?? '-'}</td>
                          <td>{rule.acceptedAlternatives.join(', ') || '-'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </>
              ) : null}
            </article>

            <article className="panel">
              <h2>Active alerts</h2>
              <div className="list-stack">
                {dashboard.alerts.map((alert) => (
                  <div className="status-row" key={`${alert.code}-${alert.triggeredAt}`}>
                    <strong>{alert.severity}</strong>
                    <div>
                      <p>{alert.title}</p>
                      <small>{alert.endpointKey} • metric {alert.metricValue}</small>
                    </div>
                  </div>
                ))}
                {dashboard.alerts.length === 0 ? <p>No active alerts for the current tenant.</p> : null}
              </div>
            </article>

            <article className="panel">
              <h2>Retention and continuity</h2>
              <dl>
                <dt>Retention days</dt><dd>{dashboard.retention.retentionDays}</dd>
                <dt>Tracked events</dt><dd>{dashboard.retention.trackedEvents}</dd>
                <dt>Expiring events</dt><dd>{dashboard.retention.expiringEvents}</dd>
                <dt>Last cleanup</dt><dd>{dashboard.retention.lastCleanupAt ? new Date(dashboard.retention.lastCleanupAt).toLocaleString('en-US') : '-'}</dd>
                <dt>Deleted on last cleanup</dt><dd>{dashboard.retention.lastCleanupDeletedCount}</dd>
                <dt>Continuity status</dt><dd>{dashboard.continuity.status}</dd>
              </dl>
            </article>
          </section>

          <section className="panel table-panel">
            <h2>Endpoint metrics</h2>
            <table>
              <thead>
                <tr>
                  <th>Endpoint</th>
                  <th>Total</th>
                  <th>Success</th>
                  <th>Warning</th>
                  <th>Error</th>
                  <th>Retry</th>
                  <th>P95 ms</th>
                  <th>Last status</th>
                  <th>Last seen</th>
                </tr>
              </thead>
              <tbody>
                {dashboard.endpointMetrics.map((metric) => (
                  <tr key={metric.endpointKey}>
                    <td>{metric.endpointKey}</td>
                    <td>{metric.totalRequests}</td>
                    <td>{metric.successCount}</td>
                    <td>{metric.warningCount}</td>
                    <td>{metric.errorCount}</td>
                    <td>{metric.retryCount}</td>
                    <td>{metric.p95LatencyMs}</td>
                    <td>{metric.lastHttpStatus ?? '-'}</td>
                    <td>{metric.lastSeenAt ? new Date(metric.lastSeenAt).toLocaleString('en-US') : '-'}</td>
                  </tr>
                ))}
                {dashboard.endpointMetrics.length === 0 ? (
                  <tr>
                    <td colSpan={9} className="empty-row">No endpoint metrics found for the current tenant.</td>
                  </tr>
                ) : null}
              </tbody>
            </table>
          </section>

          <section className="content-grid">
            <article className="panel table-panel">
              <h2>Manual resolution queue</h2>
              <p className="subtitle">
                Cases waiting for human intervention before the smart workflow can be trusted end-to-end.
              </p>
              <p className="section-note">
                Last workspace reload: {formatTimestamp(workspaceLoadedAt)}
              </p>
              <p><strong>Total queued:</strong> {manualResolutionTotal}</p>
              <div className="stats-grid" style={{ marginBottom: '1rem' }}>
                <article className="stat-card"><span>Enrichment runs</span><strong>{dashboard.intelligence.enrichmentRuns}</strong></article>
                <article className="stat-card"><span>Execution plans</span><strong>{dashboard.intelligence.executionPlans}</strong></article>
                <article className="stat-card"><span>Return artifacts</span><strong>{dashboard.intelligence.inspectionReturnArtifacts}</strong></article>
                <article className="stat-card"><span>Field evidence</span><strong>{dashboard.intelligence.fieldEvidenceRecords}</strong></article>
              </div>
              <div className="stats-grid" style={{ marginBottom: '1rem' }}>
                <article className="stat-card"><span>Run review</span><strong>{manualResolutionSummary.reviewRequired}</strong></article>
                <article className="stat-card"><span>Temporary unavailable</span><strong>{manualResolutionSummary.temporarilyUnavailable}</strong></article>
                <article className="stat-card"><span>Plan review</span><strong>{manualResolutionSummary.planReviewRequired}</strong></article>
                <article className="stat-card"><span>Run failed</span><strong>{manualResolutionSummary.enrichmentFailed}</strong></article>
                <article className="stat-card"><span>Plan missing</span><strong>{manualResolutionSummary.planMissing}</strong></article>
              </div>
              <div className="filters" style={{ marginBottom: '1rem' }}>
                <label>
                  Pending reason
                  <select value={reasonFilter} onChange={(event) => setReasonFilter(event.target.value)}>
                    <option value="ALL">All</option>
                    {pendingReasonOptions.map((reason) => (
                      <option key={reason} value={reason}>{formatReason(reason)}</option>
                    ))}
                  </select>
                </label>
                <label>
                  Run status
                  <select value={runStatusFilter} onChange={(event) => setRunStatusFilter(event.target.value)}>
                    <option value="ALL">All</option>
                    {runStatusOptions.map((status) => (
                      <option key={status} value={status}>{status}</option>
                    ))}
                  </select>
                </label>
                <label>
                  Sort by
                  <select value={sortMode} onChange={(event) => setSortMode(event.target.value as typeof sortMode)}>
                    <option value="RECENT">Most recent</option>
                    <option value="LOWEST_CONFIDENCE">Lowest confidence</option>
                    <option value="MOST_PENDING_REASONS">Most pending reasons</option>
                  </select>
                </label>
              </div>
              {intelligenceLoading ? <p>Loading manual resolution queue...</p> : null}
              <table>
                <thead>
                  <tr>
                    <th>Case</th>
                    <th>Run</th>
                  <th>Plan</th>
                  <th>Confidence</th>
                  <th>Attempts</th>
                  <th>Pending reasons</th>
                  <th>Queued at</th>
                </tr>
                </thead>
                <tbody>
                  {filteredManualResolutionQueue.map((item) => (
                    <tr
                      key={item.caseId}
                      onClick={() => {
                        void loadReportBasis(item.caseId);
                        void loadResolvePreview(item.caseId);
                      }}
                      style={{ cursor: 'pointer', background: item.caseId === selectedCaseId ? 'rgba(15, 23, 42, 0.06)' : undefined }}
                    >
                      <td>
                        <strong>{item.caseNumber}</strong>
                        <div>{item.propertyAddress}</div>
                      </td>
                      <td>{item.latestRunStatus}</td>
                      <td>{item.executionPlanStatus ?? '-'}</td>
                      <td>{item.confidenceScore != null ? item.confidenceScore.toFixed(2) : '-'}</td>
                      <td>{item.attemptCount}</td>
                      <td>{item.pendingReasons.map(formatReason).join(', ')}</td>
                      <td>{new Date(item.queuedAt).toLocaleString('en-US')}</td>
                    </tr>
                  ))}
                  {!intelligenceLoading && filteredManualResolutionQueue.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="empty-row">No manual resolution cases for the current tenant.</td>
                    </tr>
                  ) : null}
                </tbody>
              </table>
            </article>

            <article className="panel">
              <h2>Report basis</h2>
              {reportBasisLoading ? <p>Loading report basis...</p> : null}
              {!reportBasisLoading && !reportBasis ? <p>Select a queued case to inspect the consolidated basis.</p> : null}
              {!reportBasisLoading && reportBasis ? (
                <div className="list-stack">
                  <div className="status-row">
                    <strong>Case</strong>
                    <div>
                      <p>{reportBasis.caseNumber}</p>
                      <small>{reportBasis.propertyAddress}</small>
                    </div>
                  </div>
                  <div>
                    <button
                      type="button"
                      disabled={triggeringCaseId === reportBasis.caseId}
                      onClick={() => void handleTriggerEnrichment(reportBasis.caseId)}
                    >
                      {triggeringCaseId === reportBasis.caseId
                        ? 'Retrying automatic analysis...'
                        : reportBasis.latestRun?.retryable
                          ? 'Retry automatic analysis'
                          : 'Trigger enrichment again'}
                    </button>
                  </div>
                  <div className="status-row">
                    <strong>Run</strong>
                    <div>
                      <p>{reportBasis.latestRun?.status ?? 'N/A'}</p>
                      <small>Confidence {reportBasis.latestRun?.confidenceScore != null ? reportBasis.latestRun.confidenceScore.toFixed(2) : '-'}</small>
                    </div>
                  </div>
                  <div className="status-row">
                    <strong>Retry</strong>
                    <div>
                      <p>{reportBasis.latestRun?.retryable ? 'Automatic retry available' : 'No retry required'}</p>
                      <small>Attempts {reportBasis.latestRun?.attemptCount ?? '-'}</small>
                    </div>
                  </div>
                  <div className="status-row">
                    <strong>Plan</strong>
                    <div>
                      <p>{reportBasis.latestExecutionPlan?.status ?? 'N/A'}</p>
                      <small>
                        Snapshot {reportBasis.latestExecutionPlan?.snapshotId ?? '-'}
                        {' • '}
                        Confidence {reportBasis.latestExecutionPlan?.plan?.confidenceScore != null
                          ? reportBasis.latestExecutionPlan.plan.confidenceScore.toFixed(2)
                          : '-'}
                      </small>
                    </div>
                  </div>
                  <div className="status-row">
                    <strong>Return</strong>
                    <div>
                      <p>{reportBasis.latestReturnArtifact ? 'Inspection return available' : 'No field return yet'}</p>
                      <small>Evidence items: {reportBasis.fieldEvidence.length}</small>
                    </div>
                  </div>
                  <div className="panel" style={{ padding: '1rem', background: 'rgba(15, 23, 42, 0.03)' }}>
                    <h3>Resolve preview</h3>
                    {resolvePreviewLoading ? <p>Loading resolve preview...</p> : null}
                    {!resolvePreviewLoading && resolvePreview ? (
                      <dl>
                        <div>
                          <dt>Classification</dt>
                          <dd>{formatRoute([resolvePreview.classification.assetType, resolvePreview.classification.assetSubtype])}</dd>
                        </div>
                        <div>
                          <dt>Candidates</dt>
                          <dd>{resolvePreview.classification.candidateAssetSubtypes.join(', ') || '-'}</dd>
                        </div>
                        <div>
                          <dt>Context</dt>
                          <dd>{resolvePreview.classification.context ?? '-'}</dd>
                        </div>
                        <div>
                          <dt>Capture gates</dt>
                          <dd>{resolvePreview.captureGatePolicy.gates.length}</dd>
                        </div>
                        <div>
                          <dt>Normative rules</dt>
                          <dd>{resolvePreview.normativeProfile?.rules.length ?? 0}</dd>
                        </div>
                        <div>
                          <dt>Notes</dt>
                          <dd>{resolvePreview.previewNotes.join(' | ') || '-'}</dd>
                        </div>
                      </dl>
                    ) : null}
                  </div>
                  <div className="panel" style={{ padding: '1rem', background: 'rgba(15, 23, 42, 0.03)' }}>
                    <h3>Manual subtype resolution</h3>
                    <p className="subtitle">
                      Use this only when the subtype impacts the camera tree and the automatic classification is not trustworthy.
                    </p>
                    <label>
                      Asset subtype
                      <select
                        value={manualSubtypeOverride}
                        onChange={(event) => setManualSubtypeOverride(event.target.value)}
                        disabled={manualSubtypeCandidates.length === 0}
                      >
                        {manualSubtypeCandidates.length === 0 ? <option value="">No candidates available</option> : null}
                        {manualSubtypeCandidates.map((candidate) => (
                          <option key={candidate} value={candidate}>{candidate}</option>
                        ))}
                      </select>
                    </label>
                    <label>
                      Note
                      <input
                        type="text"
                        value={manualSubtypeNote}
                        onChange={(event) => setManualSubtypeNote(event.target.value)}
                        placeholder="Explain what evidence justified the manual subtype"
                      />
                    </label>
                    <div style={{ marginTop: '0.75rem' }}>
                      <button
                        type="button"
                        disabled={
                          resolvingSubtypeCaseId === reportBasis.caseId ||
                          manualSubtypeCandidates.length === 0 ||
                          manualSubtypeOverride.trim().length === 0
                        }
                        onClick={() => void handleManualSubtypeResolution(reportBasis.caseId)}
                      >
                        {resolvingSubtypeCaseId === reportBasis.caseId
                          ? 'Applying manual subtype...'
                          : 'Apply manual subtype and republish plan'}
                      </button>
                    </div>
                  </div>
                  <div className="panel" style={{ padding: '1rem', background: 'rgba(15, 23, 42, 0.03)' }}>
                    <h3>Execution plan summary</h3>
                    <dl>
                      <div>
                        <dt>Plan version</dt>
                        <dd>{reportBasis.latestExecutionPlan?.plan?.planVersion ?? '-'}</dd>
                      </div>
                      <div>
                        <dt>Provider</dt>
                        <dd>{reportBasis.latestExecutionPlan?.plan?.providerName ?? '-'}</dd>
                      </div>
                      <div>
                        <dt>Taxonomy</dt>
                        <dd>{reportBasis.latestExecutionPlan?.plan?.propertyProfile?.taxonomy ?? '-'}</dd>
                      </div>
                      <div>
                        <dt>Inspection type</dt>
                        <dd>{reportBasis.latestExecutionPlan?.plan?.propertyProfile?.inspectionType ?? '-'}</dd>
                      </div>
                      <div>
                        <dt>Step 1 context</dt>
                        <dd>{reportBasis.latestExecutionPlan?.plan?.step1Config?.initialContext ?? '-'}</dd>
                      </div>
                      <div>
                        <dt>Step 1 subtype</dt>
                        <dd>{reportBasis.latestExecutionPlan?.plan?.step1Config?.initialAssetSubtype ?? '-'}</dd>
                      </div>
                      <div>
                        <dt>Subtype candidates</dt>
                        <dd>{reportBasis.latestExecutionPlan?.plan?.step1Config?.candidateAssetSubtypes?.join(', ') || '-'}</dd>
                      </div>
                      <div>
                        <dt>Camera mode</dt>
                        <dd>{reportBasis.latestExecutionPlan?.plan?.cameraConfig?.mode ?? '-'}</dd>
                      </div>
                      <div>
                        <dt>Required evidence</dt>
                        <dd>{reportBasis.latestExecutionPlan?.plan?.step2Config?.requiredEvidence?.join(', ') || '-'}</dd>
                      </div>
                      <div>
                        <dt>Field alerts</dt>
                        <dd>{reportBasis.latestExecutionPlan?.plan?.fieldAlerts?.join(', ') || '-'}</dd>
                      </div>
                    </dl>
                  </div>
                  <div className="panel" style={{ padding: '1rem', background: 'rgba(15, 23, 42, 0.03)' }}>
                    <h3>Automatic analysis status</h3>
                    <dl>
                      <div>
                        <dt>Error code</dt>
                        <dd>{reportBasis.latestRun?.errorCode ?? '-'}</dd>
                      </div>
                      <div>
                        <dt>User guidance</dt>
                        <dd>{reportBasis.latestRun?.errorMessage ?? 'No active guidance for the latest run.'}</dd>
                      </div>
                    </dl>
                  </div>
                  <div className="panel table-panel" style={{ padding: '1rem', background: 'rgba(15, 23, 42, 0.03)' }}>
                    <h3>Capture plan</h3>
                    <table>
                      <thead>
                        <tr>
                          <th>Route</th>
                          <th>Required</th>
                          <th>Min photos</th>
                        </tr>
                      </thead>
                      <tbody>
                        {reportBasis.latestExecutionPlan?.plan?.cameraConfig?.capturePlan?.map((item, index) => (
                          <tr key={`${item.environment}-${item.element}-${index}`}>
                            <td>{formatRoute([item.macroLocal, item.environment, item.element])}</td>
                            <td>{item.required ? 'Yes' : 'No'}</td>
                            <td>{item.minPhotos ?? 0}</td>
                          </tr>
                        )) ?? null}
                        {!(reportBasis.latestExecutionPlan?.plan?.cameraConfig?.capturePlan?.length) ? (
                          <tr>
                            <td colSpan={3} className="empty-row">No capture plan items stored on the latest plan.</td>
                          </tr>
                        ) : null}
                      </tbody>
                    </table>
                  </div>
                  <div className="panel" style={{ padding: '1rem', background: 'rgba(15, 23, 42, 0.03)' }}>
                    <h3>Traceability</h3>
                    <dl>
                      <div>
                        <dt>Source run</dt>
                        <dd>{reportBasis.latestExecutionPlan?.plan?.traceability?.sourceRunId ?? '-'}</dd>
                      </div>
                      <div>
                        <dt>Request storage</dt>
                        <dd>{reportBasis.latestExecutionPlan?.plan?.traceability?.requestStorageKey ?? '-'}</dd>
                      </div>
                      <div>
                        <dt>Normalized response</dt>
                        <dd>{reportBasis.latestExecutionPlan?.plan?.traceability?.responseNormalizedStorageKey ?? '-'}</dd>
                      </div>
                      <div>
                        <dt>Research links</dt>
                        <dd>{reportBasis.latestExecutionPlan?.plan?.traceability?.researchLinks?.join(', ') || '-'}</dd>
                      </div>
                    </dl>
                  </div>
                  <div className="panel" style={{ padding: '1rem', background: 'rgba(15, 23, 42, 0.03)' }}>
                    <h3>Field return summary</h3>
                    <dl>
                      {Object.entries(toRecord(reportBasis.latestReturnArtifact?.summary)).map(([key, value]) => (
                        <div key={key}>
                          <dt>{key}</dt>
                          <dd>{formatScalar(value)}</dd>
                        </div>
                      ))}
                      {Object.keys(toRecord(reportBasis.latestReturnArtifact?.summary)).length === 0 ? (
                        <div>
                          <dt>Summary</dt>
                          <dd>No structured return summary available.</dd>
                        </div>
                      ) : null}
                    </dl>
                  </div>
                  <div className="panel" style={{ padding: '1rem', background: 'rgba(15, 23, 42, 0.03)' }}>
                    <h3>Quality flags</h3>
                    <dl>
                      {Object.entries(toRecord(reportBasis.latestRun?.qualityFlags)).map(([key, value]) => (
                        <div key={key}>
                          <dt>{key}</dt>
                          <dd>{formatScalar(value)}</dd>
                        </div>
                      ))}
                      {Object.keys(toRecord(reportBasis.latestRun?.qualityFlags)).length === 0 ? (
                        <div>
                          <dt>Flags</dt>
                          <dd>No quality flags informed on the latest run.</dd>
                        </div>
                      ) : null}
                    </dl>
                  </div>
                  <div className="panel" style={{ padding: '1rem', background: 'rgba(15, 23, 42, 0.03)' }}>
                    <h3>Facts</h3>
                    <dl>
                      {Object.entries(toRecord(reportBasis.latestRun?.facts)).map(([key, value]) => (
                        <div key={key}>
                          <dt>{key}</dt>
                          <dd>{formatScalar(value)}</dd>
                        </div>
                      ))}
                      {Object.keys(toRecord(reportBasis.latestRun?.facts)).length === 0 ? (
                        <div>
                          <dt>Facts</dt>
                          <dd>No structured facts stored on the latest run.</dd>
                        </div>
                      ) : null}
                    </dl>
                  </div>
                  <div className="panel table-panel" style={{ padding: '1rem', background: 'rgba(15, 23, 42, 0.03)' }}>
                    <h3>Field evidence</h3>
                    <table>
                      <thead>
                        <tr>
                          <th>Section</th>
                          <th>Route</th>
                          <th>Status</th>
                          <th>Photos</th>
                        </tr>
                      </thead>
                      <tbody>
                        {reportBasis.fieldEvidence.map((item, index) => (
                          <tr key={`${item.inspectionId}-${item.jobId}-${item.sourceSection}-${index}`}>
                            <td>{item.sourceSection}</td>
                            <td>{formatRoute([item.macroLocation, item.environmentName, item.elementName])}</td>
                            <td>{item.status}</td>
                            <td>{item.capturedPhotos ?? 0}/{item.minPhotos ?? 0}</td>
                          </tr>
                        ))}
                        {reportBasis.fieldEvidence.length === 0 ? (
                          <tr>
                            <td colSpan={4} className="empty-row">No field evidence stored for this case yet.</td>
                          </tr>
                        ) : null}
                      </tbody>
                    </table>
                  </div>
                </div>
              ) : null}
            </article>
          </section>

          <section className="content-grid">
            <article className="panel table-panel">
              <h2>Recent events</h2>
              <table>
                <thead>
                  <tr>
                    <th>Occurred at</th>
                    <th>Type</th>
                    <th>Endpoint</th>
                    <th>Outcome</th>
                    <th>Protocol</th>
                    <th>Job</th>
                    <th>Process</th>
                    <th>Report</th>
                  </tr>
                </thead>
                <tbody>
                  {dashboard.recentEvents.map((event) => (
                    <tr key={`${event.occurredAt}-${event.eventType}-${event.traceId}`}>
                      <td>{new Date(event.occurredAt).toLocaleString('en-US')}</td>
                      <td>{event.eventType}</td>
                      <td>{event.endpointKey ?? '-'}</td>
                      <td>{event.outcome}</td>
                      <td>{event.protocolId ?? '-'}</td>
                      <td>{event.jobId ?? '-'}</td>
                      <td>{event.processId ?? '-'}</td>
                      <td>{event.reportId ?? '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </article>

            <article className="panel">
              <h2>Continuity checklist</h2>
              <div className="list-stack">
                {dashboard.continuity.checklist.map((item) => (
                  <div className="status-row" key={item.code}>
                    <strong>{item.status}</strong>
                    <div>
                      <p>{item.title}</p>
                      <small>{item.action}</small>
                    </div>
                  </div>
                ))}
              </div>
            </article>
          </section>
        </>
      ) : null}

      <style jsx>{`
        .operations-shell {
          max-width: 1280px;
          margin: 0 auto;
          padding: 28px 16px 56px;
        }
        .page-header {
          display: flex;
          justify-content: space-between;
          gap: 16px;
          align-items: end;
          background: #f7f6f1;
          border: 1px solid #d8deea;
          border-radius: 16px;
          padding: 18px;
        }
        .eyebrow {
          margin: 0;
          text-transform: uppercase;
          letter-spacing: 0.08em;
          color: #007ca0;
          font-size: 0.78rem;
          font-weight: 700;
        }
        h1, h2, h3 { margin: 0; color: #172033; }
        .subtitle { margin: 8px 0 0; color: #4f5d75; }
        .context-line {
          margin: 10px 0 0;
          color: #3e516f;
          font-size: 0.92rem;
          font-weight: 600;
        }
        .ghost {
          text-decoration: none;
          border: 1px solid #d8deea;
          border-radius: 10px;
          padding: 10px 14px;
          color: #172033;
          background: #fff;
          font-weight: 700;
        }
        .hero-actions button,
        .panel button {
          border: 1px solid #cdd6e6;
          border-radius: 10px;
          padding: 10px 12px;
          font: inherit;
          cursor: pointer;
        }
        .hero-actions button {
          background: #fff;
          color: #172033;
          font-weight: 700;
        }
        input, textarea {
          border: 1px solid #cdd6e6;
          border-radius: 10px;
          padding: 10px;
          font: inherit;
          background: #fff;
          color: #172033;
        }
        .stats-grid {
          margin-top: 14px;
          display: grid;
          gap: 12px;
          grid-template-columns: repeat(3, minmax(0, 1fr));
        }
        .stat-card, .panel {
          border: 1px solid #d8deea;
          border-radius: 14px;
          background: #fff;
          padding: 14px;
          color: #172033;
        }
        .stat-card span { display: block; color: #4f5d75; }
        .stat-card strong { font-size: 1.5rem; color: #172033; }
        .workspace-grid, .content-grid {
          display: grid;
          gap: 12px;
          margin-top: 14px;
        }
        .workspace-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        .content-grid { grid-template-columns: 1.2fr 1fr; }
        .feature-panel p {
          margin: 8px 0 0;
        }
        .summary-list {
          display: grid;
          grid-template-columns: 140px 1fr;
          gap: 8px 10px;
          margin-top: 12px;
        }
        .summary-list dt { color: #4f5d75; }
        .summary-list dd {
          margin: 0;
          color: #172033;
          font-weight: 700;
        }
        .filters {
          display: grid;
          gap: 10px;
          grid-template-columns: repeat(3, minmax(0, 1fr));
        }
        .section-note {
          margin: 8px 0 0;
          color: #3e516f;
          font-size: 0.9rem;
        }
        label {
          display: flex;
          flex-direction: column;
          gap: 6px;
          color: #2a3550;
          font-weight: 600;
        }
        select, button {
          border: 1px solid #cdd6e6;
          border-radius: 10px;
          padding: 10px;
          font: inherit;
          background: #fff;
        }
        .panel > div > button,
        .panel .status-row + div > button {
          background: linear-gradient(90deg, #007ca0, #ff9f1c);
          color: #fff;
          border: none;
          font-weight: 700;
        }
        .inline-actions {
          display: flex;
          flex-wrap: wrap;
          gap: 8px;
        }
        .error-box, .message-box {
          margin-top: 14px;
          border-radius: 10px;
          padding: 10px 12px;
        }
        .error-box {
          background: #fff1f0;
          border: 1px solid #ffc6c2;
          color: #8f1913;
        }
        .message-box {
          background: #eef9f1;
          border: 1px solid #bfe6ca;
          color: #175b2f;
        }
        .table-panel { overflow: auto; }
        table {
          width: 100%;
          border-collapse: collapse;
          margin-top: 12px;
        }
        th, td {
          border-bottom: 1px solid #edf1f7;
          text-align: left;
          padding: 10px 8px;
          font-size: 0.92rem;
          color: #172033;
          vertical-align: top;
        }
        th { background: #f5f8ff; color: #2a3550; }
        .empty-row { text-align: center; color: #5d6b84; }
        dl {
          display: grid;
          grid-template-columns: 150px 1fr;
          gap: 6px 10px;
          margin-top: 12px;
        }
        dt { color: #4f5d75; }
        dd { margin: 0; font-weight: 600; color: #172033; }
        .status-row {
          display: flex;
          gap: 12px;
          align-items: flex-start;
          margin-top: 12px;
        }
        .status-row strong { color: #172033; min-width: 72px; }
        .status-row p { margin: 0; color: #172033; }
        .status-row small { color: #4f5d75; }
        .list-stack {
          display: flex;
          flex-direction: column;
          gap: 10px;
        }
        p { color: #4f5d75; }
        small { color: #4f5d75; }
        @media (max-width: 1080px) {
          .workspace-grid, .content-grid, .stats-grid, .filters {
            grid-template-columns: 1fr;
          }
          .page-header {
            display: grid;
            align-items: start;
          }
        }
      `}</style>
    </main>
  );
}
