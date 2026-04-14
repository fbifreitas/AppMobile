export type TargetScope =
  | "global"
  | "tenant"
  | "unit"
  | "role"
  | "user"
  | "device";

export type TargetSelector = {
  tenantId?: string;
  unitId?: string;
  roleId?: string;
  userId?: string;
  deviceId?: string;
};

export type ConfigRules = {
  requireBiometric?: boolean;
  cameraMinPhotos?: number;
  cameraMaxPhotos?: number;
  enableVoiceCommands?: boolean;
  theme?: "tenant-default" | "light" | "dark";
  appUpdateChannel?: "stable" | "pilot" | "hotfix";
  step1?: Record<string, unknown>;
  step2?: Record<string, unknown>;
  camera?: Record<string, unknown>;
  checkinSections?: Array<{
    sectionKey: string;
    sectionLabel: string;
    mandatory: boolean;
    photoMin: number;
    photoMax: number;
    desiredItems?: string[];
    assetType?: string;
    tipoImovel?: string;
    sortOrder?: number;
  }>;
};

export type NormalizedCheckinSectionRule = NonNullable<
  ConfigRules["checkinSections"]
>[number] & {
  assetType?: string;
};

export type RolloutPolicy = {
  activation: "immediate" | "scheduled";
  startsAt?: string;
  endsAt?: string;
  batchUserIds?: string[];
};

export type ConfigPackage = {
  id: string;
  scope: TargetScope;
  tenantId: string;
  selector?: TargetSelector;
  updatedAt: string;
  status?: "pending_approval" | "active" | "rolled_back";
  rollout?: RolloutPolicy;
  rules: ConfigRules;
};

export type ResolveInput = {
  tenantId: string;
  unitId?: string;
  roleId?: string;
  userId?: string;
  deviceId?: string;
};

export type ResolveOutput = {
  effective: ConfigRules;
  appliedPackages: ConfigPackage[];
  skippedPackages: ConfigPackage[];
};

const scopeRank: Record<TargetScope, number> = {
  global: 1,
  tenant: 2,
  unit: 3,
  role: 4,
  user: 5,
  device: 6
};

function parseDateValue(value: string): number {
  const parsed = Date.parse(value);
  return Number.isNaN(parsed) ? 0 : parsed;
}

function isSelectorMatch(pkg: ConfigPackage, input: ResolveInput): boolean {
  if (pkg.tenantId !== input.tenantId) {
    return false;
  }

  const selector = pkg.selector;

  if (!selector) {
    return true;
  }

  if (selector.unitId && selector.unitId !== input.unitId) {
    return false;
  }

  if (selector.roleId && selector.roleId !== input.roleId) {
    return false;
  }

  if (selector.userId && selector.userId !== input.userId) {
    return false;
  }

  if (selector.deviceId && selector.deviceId !== input.deviceId) {
    return false;
  }

  return true;
}

function isRolloutActive(pkg: ConfigPackage, input: ResolveInput): boolean {
  const rollout = pkg.rollout;

  if (!rollout) {
    return true;
  }

  const now = Date.now();

  if (rollout.activation === "scheduled") {
    const startMs = rollout.startsAt ? parseDateValue(rollout.startsAt) : 0;
    const endMs = rollout.endsAt ? parseDateValue(rollout.endsAt) : Number.POSITIVE_INFINITY;

    if (startMs > now || now > endMs) {
      return false;
    }
  }

  if (rollout.batchUserIds && rollout.batchUserIds.length > 0) {
    if (!input.userId) {
      return false;
    }

    return rollout.batchUserIds.includes(input.userId);
  }

  return true;
}

function byPriorityThenTime(a: ConfigPackage, b: ConfigPackage): number {
  const rankDiff = scopeRank[a.scope] - scopeRank[b.scope];

  if (rankDiff !== 0) {
    return rankDiff;
  }

  return parseDateValue(a.updatedAt) - parseDateValue(b.updatedAt);
}

export function resolveEffectiveConfig(packages: ConfigPackage[], input: ResolveInput): ResolveOutput {
  const matching = packages
    .filter((pkg) => (pkg.status ?? "active") === "active")
    .filter((pkg) => isSelectorMatch(pkg, input))
    .filter((pkg) => isRolloutActive(pkg, input))
    .sort(byPriorityThenTime);

  const appliedIds = new Set(matching.map((pkg) => pkg.id));
  const skipped = packages.filter((pkg) => !appliedIds.has(pkg.id));

  const effective = matching.reduce<ConfigRules>((acc, pkg) => {
    return {
      ...acc,
      ...pkg.rules
    };
  }, {});

  return {
    effective,
    appliedPackages: matching,
    skippedPackages: skipped
  };
}

export const mockConfigPackages: ConfigPackage[] = [
  {
    id: "cfg-global-001",
    scope: "global",
    tenantId: "tenant-alpha",
    updatedAt: "2026-04-02T10:00:00.000Z",
    rollout: {
      activation: "immediate"
    },
    rules: {
      requireBiometric: true,
      cameraMinPhotos: 1,
      cameraMaxPhotos: 6,
      enableVoiceCommands: true,
      theme: "tenant-default",
      appUpdateChannel: "stable"
    }
  },
  {
    id: "cfg-tenant-010",
    scope: "tenant",
    tenantId: "tenant-alpha",
    updatedAt: "2026-04-02T10:05:00.000Z",
    rollout: {
      activation: "immediate"
    },
    rules: {
      cameraMaxPhotos: 8,
      appUpdateChannel: "pilot"
    }
  },
  {
    id: "cfg-role-120",
    scope: "role",
    tenantId: "tenant-alpha",
    selector: {
      roleId: "vistoriador"
    },
    updatedAt: "2026-04-02T10:15:00.000Z",
    rollout: {
      activation: "immediate"
    },
    rules: {
      cameraMinPhotos: 2
    }
  },
  {
    id: "cfg-user-991",
    scope: "user",
    tenantId: "tenant-alpha",
    selector: {
      userId: "user-42"
    },
    updatedAt: "2026-04-02T10:20:00.000Z",
    rollout: {
      activation: "immediate",
      batchUserIds: ["user-42", "user-77"]
    },
    rules: {
      enableVoiceCommands: false,
      appUpdateChannel: "hotfix"
    }
  },
  {
    id: "cfg-device-333",
    scope: "device",
    tenantId: "tenant-alpha",
    selector: {
      deviceId: "device-x7"
    },
    updatedAt: "2026-04-02T10:25:00.000Z",
    rollout: {
      activation: "immediate"
    },
    rules: {
      theme: "dark"
    }
  }
];
