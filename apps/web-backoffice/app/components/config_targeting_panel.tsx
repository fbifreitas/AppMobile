"use client";

import React from "react";
import { useCallback, useEffect, useMemo, useState } from "react";
import type { ActorRole } from "../lib/config_policy";
import { resolveUiLanguage, t } from "../lib/ui_strings";

type ResolveResponse = {
  input: {
    tenantId: string;
    unitId?: string;
    roleId?: string;
    userId?: string;
    deviceId?: string;
  };
  result: {
    effective: Record<string, unknown>;
    appliedPackages: Array<{
      id: string;
      scope: string;
      updatedAt: string;
      status?: "pending_approval" | "active" | "rolled_back";
      rollout?: {
        activation: "immediate" | "scheduled";
        startsAt?: string;
        endsAt?: string;
        batchUserIds?: string[];
      };
      selector?: Record<string, string>;
    }>;
  };
  metadata: {
    model: string;
    generatedAt: string;
  };
};

type PackagesResponse = {
  items: Array<{
    id: string;
    scope: string;
    status?: "pending_approval" | "active" | "rolled_back";
    updatedAt: string;
    rollout?: {
      activation: "immediate" | "scheduled";
      startsAt?: string;
      endsAt?: string;
      batchUserIds?: string[];
    };
  }>;
};

type AuditResponse = {
  items: Array<{
    id: string;
    packageId: string;
    actorId: string;
    scope: string;
    createdAt: string;
  }>;
};

type AuthMeResponse = {
  tenantId: string;
  membershipRole: string;
};

type SectionDraft = {
  sectionKey: string;
  sectionLabel: string;
  mandatory: boolean;
  photoMin: string;
  photoMax: string;
  desiredItemsCsv: string;
  assetType?: string;
  tipoImovel: string;
  sortOrder: string;
};

type Step1SubtypeDraft = {
  tipo: string;
  subtiposCsv: string;
};

type Step1LevelDraft = {
  id: string;
  label: string;
  required: boolean;
  dependsOn: string;
  optionsCsv: string;
};

type Step2PhotoFieldDraft = {
  id: string;
  titulo: string;
  icon: string;
  obrigatorio: boolean;
  cameraMacroLocal: string;
  cameraAmbiente: string;
  cameraElementoInicial: string;
};

type Step2OptionDraft = {
  id: string;
  label: string;
};

type Step2OptionGroupDraft = {
  id: string;
  titulo: string;
  visivel: boolean;
  obrigatorio: boolean;
  multiplaEscolha: boolean;
  permiteObservacao: boolean;
  opcoes: Step2OptionDraft[];
};

type Step2TypeDraft = {
  propertyType: string;
  screenLabel: string;
  subtitleLabel: string;
  photoSectionLabel: string;
  photoSectionVisible: boolean;
  photoSectionRequired: boolean;
  optionSectionLabel: string;
  optionSectionVisible: boolean;
  optionSectionRequired: boolean;
  confirmButtonLabel: string;
  visivel: boolean;
  obrigatoria: boolean;
  bloqueiaCaptura: boolean;
  minFotos: string;
  maxFotos: string;
  photoFields: Step2PhotoFieldDraft[];
  optionGroups: Step2OptionGroupDraft[];
};

type CameraLevelDraft = {
  id: string;
  label: string;
  required: boolean;
  dependsOn: string;
  optionsCsv: string;
};

type CameraMacroLocalDraft = {
  macroLocal: string;
  ambientesCsv: string;
  elementosCsv: string;
  materiaisCsv: string;
  estadosCsv: string;
};

type CameraSubtypeDraft = {
  subtype: string;
  macroLocals: CameraMacroLocalDraft[];
};

type CameraTypeDraft = {
  propertyType: string;
  levels: CameraLevelDraft[];
  subtypes: CameraSubtypeDraft[];
};

type Step1UiDraft = {
  dadosObjetoClienteVisible: boolean;
  dadosObjetoClienteRequired: boolean;
  gpsVisible: boolean;
  gpsRequired: boolean;
  whatsappVisible: boolean;
  whatsappRequired: boolean;
  ligarVisible: boolean;
  ligarRequired: boolean;
  clientePresenteLabel: string;
  clientePresenteVisible: boolean;
  clientePresenteRequired: boolean;
  menuTipoLabel: string;
  menuTipoVisible: boolean;
  menuTipoRequired: boolean;
  menuSubtipoLabel: string;
  menuSubtipoVisible: boolean;
  menuSubtipoRequired: boolean;
  menuContextoLabel: string;
  menuContextoVisible: boolean;
  menuContextoRequired: boolean;
  botaoEtapa2Label: string;
  botaoEtapa2Visible: boolean;
  botaoConfirmarCameraLabel: string;
  botaoConfirmarCameraVisible: boolean;
  botaoConfirmarCameraRequired: boolean;
};

type CameraTreeStateNode = {
  label: string;
  baseScore?: number;
};

type CameraTreeMaterialNode = CameraTreeStateNode;
type CameraTreeStatusNode = CameraTreeStateNode;

type CameraTreeElementNode = CameraTreeStateNode & {
  materials?: CameraTreeMaterialNode[];
  states?: CameraTreeStatusNode[];
};

type CameraTreeAmbienteNode = CameraTreeStateNode & {
  elements?: CameraTreeElementNode[];
};

type CameraTreeMacroLocalNode = CameraTreeStateNode & {
  ambientes?: CameraTreeAmbienteNode[];
};

type CameraTreePropertyType = {
  subtypes?: Array<{
    subtype: string;
    macroLocals?: CameraTreeMacroLocalNode[];
  }>;
};

type CanonicalLevelId =
  | "tipoImovel"
  | "subtipo"
  | "areaFoto"
  | "ambiente"
  | "elemento"
  | "material"
  | "estado";

type CanonicalLevelMeta = {
  id: CanonicalLevelId;
  label: string;
};

type CanonicalTreeNode = {
  id: string;
  label: string;
  level: CanonicalLevelId | "root";
  path: Partial<Record<CanonicalLevelId, string>>;
  children?: CanonicalTreeNode[];
};

const CANONICAL_LEVELS: CanonicalLevelMeta[] = [
  { id: "tipoImovel", label: "Tipo" },
  { id: "subtipo", label: "Subtipo" },
  { id: "ambiente", label: "Ambiente" },
  { id: "elemento", label: "Elemento" },
  { id: "material", label: "Material" },
  { id: "estado", label: "Estado" }
];

function splitCsv(value: string): string[] {
  return value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function parseInteger(value: string, fallback: number): number {
  const parsed = Number.parseInt(value.trim(), 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function normalizeKey(value: string): string {
  return value.trim().toLowerCase();
}

function uniqueLabels(values: string[]): string[] {
  return Array.from(new Set(values.map((item) => item.trim()).filter(Boolean)));
}

function joinCsv(items: string[]): string {
  return uniqueLabels(items).join(", ");
}

function buildDefaultCameraLevels(template?: CameraTypeDraft | null): CameraLevelDraft[] {
  if (template && template.levels.length > 0) {
    return template.levels.map((level) => ({
      id: level.id,
      label: level.label,
      required: level.required,
      dependsOn: level.dependsOn,
      optionsCsv: ""
    }));
  }

  return [
    { id: "ambiente", label: "Ambiente", required: true, dependsOn: "", optionsCsv: "" },
    { id: "elemento", label: "Elemento", required: true, dependsOn: "ambiente", optionsCsv: "" },
    { id: "material", label: "Material", required: false, dependsOn: "elemento", optionsCsv: "" },
    { id: "estado", label: "Estado", required: false, dependsOn: "elemento", optionsCsv: "" }
  ];
}

function buildDefaultMacroLocals(contexts: string[]): CameraMacroLocalDraft[] {
  return uniqueLabels(contexts).map((context) => ({
    macroLocal: context,
    ambientesCsv: "",
    elementosCsv: "",
    materiaisCsv: "",
    estadosCsv: ""
  }));
}

function buildDefaultSubtypeDrafts(subtypes: string[], contexts: string[]): CameraSubtypeDraft[] {
  return uniqueLabels(subtypes).map((subtype) => ({
    subtype,
    macroLocals: buildDefaultMacroLocals(contexts)
  }));
}

function buildSectionsPayload(sections: SectionDraft[]) {
  return sections
    .map((section) => {
      const key = section.sectionKey.trim();
      const label = section.sectionLabel.trim();
      if (!key || !label) {
        return null;
      }

      const assetType = section.assetType?.trim() || section.tipoImovel.trim() || undefined;

      return {
        sectionKey: key,
        sectionLabel: label,
        mandatory: section.mandatory,
        photoMin: parseInteger(section.photoMin, 1),
        photoMax: parseInteger(section.photoMax, 5),
        desiredItems: splitCsv(section.desiredItemsCsv),
        assetType,
        tipoImovel: assetType,
        sortOrder: parseInteger(section.sortOrder, 1)
      };
    })
    .filter(Boolean);
}

function buildStep1Payload(
  tiposCsv: string,
  contextosCsv: string,
  subtypeRows: Step1SubtypeDraft[],
  levelRows: Step1LevelDraft[]
) {
  const tipos = splitCsv(tiposCsv);
  const contextos = splitCsv(contextosCsv);
  const subtiposPorTipo = subtypeRows.reduce<Record<string, string[]>>((acc, row) => {
    const tipo = row.tipo.trim();
    if (!tipo) {
      return acc;
    }
    acc[tipo] = splitCsv(row.subtiposCsv);
    return acc;
  }, {});
  const levels = levelRows
    .map((level) => {
      const id = level.id.trim();
      const label = level.label.trim();
      if (!id || !label) {
        return null;
      }
      return {
        id,
        label,
        required: level.required,
        dependsOn: level.dependsOn.trim() || undefined,
        options:
          normalizeKey(id) === "contexto" || normalizeKey(id) === "macrolocal"
            ? contextos
            : splitCsv(level.optionsCsv)
      };
    })
    .filter(Boolean);

  return {
    tipos,
    subtiposPorTipo,
    contextos,
    levels
  };
}

function buildStep2Payload(typeRows: Step2TypeDraft[]) {
  const byTipo = typeRows.reduce<Record<string, unknown>>((acc, row) => {
    const propertyType = row.propertyType.trim().toLowerCase();
    if (!propertyType) {
      return acc;
    }

    acc[propertyType] = {
      ui: {
        screenLabel: row.screenLabel.trim() || undefined,
        subtitleLabel: row.subtitleLabel.trim() || undefined,
        photoSectionLabel: row.photoSectionLabel.trim() || undefined,
        photoSectionVisible: row.photoSectionVisible,
        photoSectionRequired: row.photoSectionRequired,
        optionSectionLabel: row.optionSectionLabel.trim() || undefined,
        optionSectionVisible: row.optionSectionVisible,
        optionSectionRequired: row.optionSectionRequired,
        confirmButtonLabel: row.confirmButtonLabel.trim() || undefined
      },
      visivel: row.visivel,
      obrigatoriaParaEntrega: row.obrigatoria,
      obrigatoria: row.obrigatoria,
      bloqueiaCaptura: row.bloqueiaCaptura,
      minFotos: parseInteger(row.minFotos, 0),
      maxFotos: row.maxFotos.trim() ? parseInteger(row.maxFotos, 0) : undefined,
      camposFotos: row.photoFields
        .map((field) => {
          const id = field.id.trim();
          const titulo = field.titulo.trim();
          const cameraMacroLocal = field.cameraMacroLocal.trim();
          const cameraAmbiente = field.cameraAmbiente.trim();
          if (!id || !titulo || !cameraMacroLocal || !cameraAmbiente) {
            return null;
          }
          return {
            id,
            titulo,
            icon: field.icon.trim() || "photo_camera_outlined",
            obrigatorio: field.obrigatorio,
            cameraMacroLocal,
            cameraAmbiente,
            cameraElementoInicial: field.cameraElementoInicial.trim() || undefined
          };
        })
        .filter(Boolean),
      gruposOpcoes: row.optionGroups
        .map((group) => {
          const id = group.id.trim();
          const titulo = group.titulo.trim();
          if (!id || !titulo) {
            return null;
          }
          return {
            id,
            titulo,
            visivel: group.visivel,
            obrigatorio: group.obrigatorio,
            multiplaEscolha: group.multiplaEscolha,
            permiteObservacao: group.permiteObservacao,
            opcoes: group.opcoes
              .map((option) => {
                const id = option.id.trim();
                const label = option.label.trim();
                if (!id || !label) {
                  return null;
                }
                return { id, label };
              })
              .filter(Boolean)
          };
        })
        .filter(Boolean)
    };

    return acc;
  }, {});

  return { byTipo };
}

function buildCameraPayload(
  typeRows: CameraTypeDraft[],
  step1ContextosCsv: string,
  step2TypeRows: Step2TypeDraft[]
) {
  const buildHierarchicalMacroLocals = (row: CameraTypeDraft) => {
    const contexts = splitCsv(step1ContextosCsv);
    const step2Row = step2TypeRows.find(
      (candidate) => candidate.propertyType.trim().toLowerCase() === row.propertyType.trim().toLowerCase()
    );
    const subtypeRows = row.subtypes.length > 0 ? row.subtypes : buildDefaultSubtypeDrafts([], contexts);

    return subtypeRows.map((subtypeRow) => {
      const macros = new Map<
        string,
        {
          ambientes: Set<string>;
          elementos: Set<string>;
          materiais: Set<string>;
          estados: Set<string>;
        }
      >();

      const macroDrafts = new Map(
        subtypeRow.macroLocals.map((macro) => [
          normalizeKey(macro.macroLocal),
          macro
        ])
      );

      for (const context of contexts) {
        const draft = macroDrafts.get(normalizeKey(context));
        macros.set(context, {
          ambientes: new Set(splitCsv(draft?.ambientesCsv ?? "")),
          elementos: new Set(splitCsv(draft?.elementosCsv ?? "")),
          materiais: new Set(splitCsv(draft?.materiaisCsv ?? "")),
          estados: new Set(splitCsv(draft?.estadosCsv ?? ""))
        });
      }

      for (const field of step2Row?.photoFields ?? []) {
        const macro = field.cameraMacroLocal.trim();
        const ambiente = field.cameraAmbiente.trim();
        const elemento = field.cameraElementoInicial.trim();
        if (!macro || !ambiente) {
          continue;
        }

        const current = macros.get(macro) ?? {
          ambientes: new Set<string>(),
          elementos: new Set<string>(),
          materiais: new Set<string>(),
          estados: new Set<string>()
        };
        current.ambientes.add(ambiente);
        if (elemento) {
          current.elementos.add(elemento);
        }
        macros.set(macro, current);
      }

      return {
        subtype: subtypeRow.subtype,
        macroLocals: Array.from(macros.entries()).map(([macroLabel, details]) => ({
          label: macroLabel,
          baseScore: 100,
          ambientes: Array.from(details.ambientes).map((ambienteLabel) => ({
            label: ambienteLabel,
            baseScore: 100,
            elements: Array.from(details.elementos).map((label) => ({
              label,
              baseScore: 100,
              materials: Array.from(details.materiais).map((material) => ({
                label: material,
                baseScore: 100
              })),
              states: Array.from(details.estados).map((estado) => ({
                label: estado,
                baseScore: 100
              }))
            }))
          }))
        }))
      };
    });
  };

  const propertyTypes = typeRows.reduce<Record<string, unknown>>((acc, row) => {
    const propertyType = row.propertyType.trim().toLowerCase();
    if (!propertyType) {
      return acc;
    }

    acc[propertyType] = {
      subtypes: buildHierarchicalMacroLocals(row),
      levels: row.levels
        .map((level) => {
          const id = level.id.trim();
          const label = level.label.trim();
          if (!id || !label) {
            return null;
          }
          return {
            id,
            label,
            required: level.required,
            dependsOn: level.dependsOn.trim() || undefined,
            options: splitCsv(level.optionsCsv)
          };
        })
        .filter(Boolean)
    };

    return acc;
  }, {});

  return { propertyTypes };
}

async function fetchPackages(tenantId: string, actorRole: ActorRole): Promise<PackagesResponse> {
  const uiLanguage = resolveUiLanguage();
  const response = await fetch(
    `/api/config/packages?tenantId=${encodeURIComponent(tenantId)}&actorRole=${encodeURIComponent(actorRole)}`,
    {
      cache: "no-store"
    }
  );

  if (!response.ok) {
    throw new Error(`${t(uiLanguage, "listPackagesFailed")}: ${response.status}`);
  }

  return (await response.json()) as PackagesResponse;
}

async function fetchAuditByRole(tenantId: string, actorRole: ActorRole): Promise<AuditResponse> {
  const uiLanguage = resolveUiLanguage();
  const response = await fetch(
    `/api/config/audit?tenantId=${encodeURIComponent(tenantId)}&limit=10&actorRole=${encodeURIComponent(actorRole)}`,
    {
      cache: "no-store"
    }
  );

  if (!response.ok) {
    throw new Error(`${t(uiLanguage, "auditLoadFailed")}: ${response.status}`);
  }

  return (await response.json()) as AuditResponse;
}

async function fetchResolveByRole(query: URLSearchParams): Promise<ResolveResponse> {
  const uiLanguage = resolveUiLanguage();
  const response = await fetch(`/api/config/resolve?${query.toString()}`, {
    cache: "no-store"
  });

  if (!response.ok) {
    throw new Error(`${t(uiLanguage, "resolveLoadFailed")}: ${response.status}`);
  }

  return (await response.json()) as ResolveResponse;
}

function toPretty(value: unknown): string {
  if (typeof value === "boolean") {
    return value ? "true" : "false";
  }

  if (value === undefined || value === null) {
    return "-";
  }

  if (typeof value === "object") {
    return JSON.stringify(value, null, 2);
  }

  return String(value);
}

export default function ConfigTargetingPanel() {
  const uiLanguage = useMemo(() => resolveUiLanguage(), []);
  const [tenantId, setTenantId] = useState("");
  const [roleId, setRoleId] = useState("vistoriador");
  const [userId, setUserId] = useState("user-42");
  const [deviceId, setDeviceId] = useState("device-x7");
  const [loading, setLoading] = useState(false);
  const [publishing, setPublishing] = useState(false);
  const [rollingBackId, setRollingBackId] = useState<string | null>(null);
  const [approvingId, setApprovingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [payload, setPayload] = useState<ResolveResponse | null>(null);
  const [audit, setAudit] = useState<AuditResponse["items"]>([]);
  const [packages, setPackages] = useState<PackagesResponse["items"]>([]);
  const [publishScope, setPublishScope] = useState<"tenant" | "role" | "user" | "device">("user");
  const [publishChannel, setPublishChannel] = useState<"stable" | "pilot" | "hotfix">("pilot");
  const [publishVoice, setPublishVoice] = useState(true);
  const [actorRole, setActorRole] = useState<ActorRole>("tenant_admin");
  const [publishActivation, setPublishActivation] = useState<"immediate" | "scheduled">("immediate");
  const [publishStartsAt, setPublishStartsAt] = useState("");
  const [publishEndsAt, setPublishEndsAt] = useState("");
  const [publishBatchUsers, setPublishBatchUsers] = useState("");
  const [step1UiDraft, setStep1UiDraft] = useState<Step1UiDraft>({
    dadosObjetoClienteVisible: true,
    dadosObjetoClienteRequired: true,
    gpsVisible: true,
    gpsRequired: true,
    whatsappVisible: true,
    whatsappRequired: false,
    ligarVisible: true,
    ligarRequired: false,
    clientePresenteLabel: "Cliente esta presente",
    clientePresenteVisible: true,
    clientePresenteRequired: true,
    menuTipoLabel: "Tipo",
    menuTipoVisible: true,
    menuTipoRequired: true,
    menuSubtipoLabel: "Subtipo",
    menuSubtipoVisible: true,
    menuSubtipoRequired: true,
    menuContextoLabel: "Por onde deseja comecar",
    menuContextoVisible: true,
    menuContextoRequired: true,
    botaoEtapa2Label: "Ir para etapa 2 do check-in",
    botaoEtapa2Visible: true,
    botaoConfirmarCameraLabel: "Confirmar e abrir a camera",
    botaoConfirmarCameraVisible: true,
    botaoConfirmarCameraRequired: true
  });
  const [sectionDrafts, setSectionDrafts] = useState<SectionDraft[]>([
    {
      sectionKey: "fachada",
      sectionLabel: "Fachada",
      mandatory: true,
      photoMin: "1",
      photoMax: "5",
      desiredItemsCsv: "orientacao, material",
      tipoImovel: "Urbano",
      sortOrder: "1"
    }
  ]);
  const [step1TiposCsv, setStep1TiposCsv] = useState("Urbano");
  const [step1ContextosCsv, setStep1ContextosCsv] = useState("Rua, Area externa, Area interna");
  const [step1SubtypeDrafts, setStep1SubtypeDrafts] = useState<Step1SubtypeDraft[]>([
    { tipo: "Urbano", subtiposCsv: "Apartamento, Casa" }
  ]);
  const [step1LevelDrafts, setStep1LevelDrafts] = useState<Step1LevelDraft[]>([
    {
      id: "contexto",
      label: "Por onde deseja comecar?",
      required: true,
      dependsOn: "",
      optionsCsv: "Rua, Area externa, Area interna"
    }
  ]);
  const [step2TypeDrafts, setStep2TypeDrafts] = useState<Step2TypeDraft[]>([
    {
      propertyType: "urbano",
      screenLabel: "Etapa 2 Vistoria",
      subtitleLabel: "Pre-vistoria externa urbano",
      photoSectionLabel: "Registro Fotografico",
      photoSectionVisible: true,
      photoSectionRequired: true,
      optionSectionLabel: "Infraestrutura e Servicos",
      optionSectionVisible: true,
      optionSectionRequired: false,
      confirmButtonLabel: "Confirmar e abrir a camera",
      visivel: true,
      obrigatoria: false,
      bloqueiaCaptura: false,
      minFotos: "1",
      maxFotos: "5",
      photoFields: [
        {
          id: "fachada",
          titulo: "Fachada",
          icon: "home_work_outlined",
          obrigatorio: true,
          cameraMacroLocal: "Rua",
          cameraAmbiente: "Fachada",
          cameraElementoInicial: ""
        }
      ],
      optionGroups: []
    }
  ]);
  const [cameraTypeDrafts, setCameraTypeDrafts] = useState<CameraTypeDraft[]>([
    {
      propertyType: "urbano",
      subtypes: [
        {
          subtype: "Apartamento",
          macroLocals: [
            {
              macroLocal: "Rua",
              ambientesCsv: "Fachada",
              elementosCsv: "Porta, Portao",
              materiaisCsv: "",
              estadosCsv: ""
            },
            {
              macroLocal: "Area externa",
              ambientesCsv: "",
              elementosCsv: "",
              materiaisCsv: "",
              estadosCsv: ""
            },
            {
              macroLocal: "Area interna",
              ambientesCsv: "",
              elementosCsv: "",
              materiaisCsv: "",
              estadosCsv: ""
            }
          ]
        },
        {
          subtype: "Casa",
          macroLocals: [
            {
              macroLocal: "Rua",
              ambientesCsv: "Fachada",
              elementosCsv: "Porta, Portao",
              materiaisCsv: "",
              estadosCsv: ""
            },
            {
              macroLocal: "Area externa",
              ambientesCsv: "",
              elementosCsv: "",
              materiaisCsv: "",
              estadosCsv: ""
            },
            {
              macroLocal: "Area interna",
              ambientesCsv: "",
              elementosCsv: "",
              materiaisCsv: "",
              estadosCsv: ""
            }
          ]
        }
      ],
      levels: [
        {
          id: "ambiente",
          label: "Ambiente",
          required: true,
          dependsOn: "",
          optionsCsv: "Fachada"
        },
        {
          id: "elemento",
          label: "Elemento",
          required: true,
          dependsOn: "ambiente",
          optionsCsv: "Porta, Portao"
        }
      ]
    }
  ]);
  const [selectedCanonicalLevel, setSelectedCanonicalLevel] = useState<CanonicalLevelId>("tipoImovel");
  const [selectedTipoImovel, setSelectedTipoImovel] = useState("Urbano");
  const [selectedSubtipo, setSelectedSubtipo] = useState("Apartamento");
  const [selectedAreaFoto, setSelectedAreaFoto] = useState("Rua");
  const [selectedAmbiente, setSelectedAmbiente] = useState("");
  const [selectedElemento, setSelectedElemento] = useState("");
  const [selectedMaterial, setSelectedMaterial] = useState("");
  const [selectedEstado, setSelectedEstado] = useState("");
  const [inactiveCanonicalItems, setInactiveCanonicalItems] = useState<Record<string, string[]>>({});
  const [selectedTreeNodeId, setSelectedTreeNodeId] = useState("");
  const [selectedAreaFilter, setSelectedAreaFilter] = useState<"all" | string>("all");
  const [selectedNodeLabelDraft, setSelectedNodeLabelDraft] = useState("");
  const [expandedTreeNodeIds, setExpandedTreeNodeIds] = useState<string[]>([]);

  useEffect(() => {
    let active = true;

    const run = async () => {
      try {
        const response = await fetch("/api/auth/me", { cache: "no-store" });
        if (!response.ok) {
          throw new Error(`Falha ao carregar sessao: ${response.status}`);
        }
        const session = (await response.json()) as AuthMeResponse;
        if (active) {
          setTenantId(session.tenantId);
          setActorRole(
            session.membershipRole === "TENANT_ADMIN" || session.membershipRole === "PLATFORM_ADMIN"
              ? "tenant_admin"
              : session.membershipRole === "AUDITOR"
                ? "viewer"
                : "operator"
          );
        }
      } catch (err) {
        if (active) {
          setError(err instanceof Error ? err.message : t(uiLanguage, "authenticatedSessionLoadFailed"));
        }
      }
    };

    run();

    return () => {
      active = false;
    };
  }, [uiLanguage]);

  const query = useMemo(() => {
    const params = new URLSearchParams();
    params.set("tenantId", tenantId);
    params.set("actorRole", actorRole);

    if (roleId.trim()) {
      params.set("roleId", roleId.trim());
    }

    if (userId.trim()) {
      params.set("userId", userId.trim());
    }

    if (deviceId.trim()) {
      params.set("deviceId", deviceId.trim());
    }

    return params;
  }, [tenantId, roleId, userId, deviceId, actorRole]);

  useEffect(() => {
    let active = true;

    const run = async () => {
      if (!tenantId.trim()) {
        return;
      }

      setLoading(true);
      setError(null);

      try {
        const resolved = await fetchResolveByRole(query);
        const auditResult = await fetchAuditByRole(tenantId, actorRole);
        const packagesResult = await fetchPackages(tenantId, actorRole);

        if (!active) {
          return;
        }

        setPayload(resolved);
        setAudit(auditResult.items);
        setPackages(packagesResult.items);
      } catch (err) {
        if (!active) {
          return;
        }

        setError(err instanceof Error ? err.message : t(uiLanguage, "unidentifiedError"));
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    };

    run();

    return () => {
      active = false;
    };
  }, [query, tenantId, actorRole, uiLanguage]);

  const getInactiveKey = (levelId: CanonicalLevelId, parentKey = "") =>
    parentKey ? `${levelId}:${normalizeKey(parentKey)}` : levelId;

  const filterActiveItems = useCallback(
    (items: string[], inactiveKey: string) => {
      const blocked = new Set((inactiveCanonicalItems[inactiveKey] ?? []).map((item) => item.trim()));
      return uniqueLabels(items).filter((item) => !blocked.has(item));
    },
    [inactiveCanonicalItems]
  );

  const effectiveStep1TiposCsv = useMemo(
    () => joinCsv(filterActiveItems(splitCsv(step1TiposCsv), getInactiveKey("tipoImovel"))),
    [step1TiposCsv, filterActiveItems]
  );

  const effectiveStep1ContextosCsv = useMemo(
    () => joinCsv(filterActiveItems(splitCsv(step1ContextosCsv), getInactiveKey("areaFoto"))),
    [step1ContextosCsv, filterActiveItems]
  );

  const effectiveStep1SubtypeDrafts = useMemo(
    () =>
      step1SubtypeDrafts.map((row) => ({
        ...row,
        subtiposCsv: joinCsv(filterActiveItems(splitCsv(row.subtiposCsv), getInactiveKey("subtipo", row.tipo)))
      })),
    [step1SubtypeDrafts, filterActiveItems]
  );

  const effectiveCameraTypeDrafts = useMemo(
    () =>
      cameraTypeDrafts.map((typeRow) => ({
        ...typeRow,
        subtypes: typeRow.subtypes.map((subtypeRow) => ({
          ...subtypeRow,
          macroLocals: subtypeRow.macroLocals.map((macroLocal) => ({
            ...macroLocal,
            ambientesCsv: joinCsv(
              filterActiveItems(
                splitCsv(macroLocal.ambientesCsv),
                getInactiveKey("ambiente", `${typeRow.propertyType}:${subtypeRow.subtype}:${macroLocal.macroLocal}`)
              )
            ),
            elementosCsv: joinCsv(
              filterActiveItems(
                splitCsv(macroLocal.elementosCsv),
                getInactiveKey("elemento", `${typeRow.propertyType}:${subtypeRow.subtype}:${macroLocal.macroLocal}`)
              )
            ),
            materiaisCsv: joinCsv(
              filterActiveItems(
                splitCsv(macroLocal.materiaisCsv),
                getInactiveKey("material", `${typeRow.propertyType}:${subtypeRow.subtype}:${macroLocal.macroLocal}`)
              )
            ),
            estadosCsv: joinCsv(
              filterActiveItems(
                splitCsv(macroLocal.estadosCsv),
                getInactiveKey("estado", `${typeRow.propertyType}:${subtypeRow.subtype}:${macroLocal.macroLocal}`)
              )
            )
          }))
        })),
        levels: typeRow.levels.map((level) => ({
          ...level,
          optionsCsv: joinCsv(
            filterActiveItems(
              splitCsv(level.optionsCsv),
              getInactiveKey(level.id as CanonicalLevelId, typeRow.propertyType)
            )
          )
        }))
      })),
    [cameraTypeDrafts, filterActiveItems]
  );

  const builtSections = useMemo(() => buildSectionsPayload(sectionDrafts), [sectionDrafts]);
  const builtStep1 = useMemo(
    () => buildStep1Payload(effectiveStep1TiposCsv, effectiveStep1ContextosCsv, effectiveStep1SubtypeDrafts, step1LevelDrafts),
    [effectiveStep1TiposCsv, effectiveStep1ContextosCsv, effectiveStep1SubtypeDrafts, step1LevelDrafts]
  );
  const builtStep2 = useMemo(() => buildStep2Payload(step2TypeDrafts), [step2TypeDrafts]);
  const builtCamera = useMemo(
    () => buildCameraPayload(effectiveCameraTypeDrafts, effectiveStep1ContextosCsv, step2TypeDrafts),
    [effectiveCameraTypeDrafts, effectiveStep1ContextosCsv, step2TypeDrafts]
  );
  const previewSectionsJson = useMemo(() => JSON.stringify(builtSections, null, 2), [builtSections]);
  const previewStep1Json = useMemo(() => JSON.stringify(builtStep1, null, 2), [builtStep1]);
  const previewStep2Json = useMemo(() => JSON.stringify(builtStep2, null, 2), [builtStep2]);
  const previewCameraJson = useMemo(() => JSON.stringify(builtCamera, null, 2), [builtCamera]);

  const publishPackage = async () => {
    if (!tenantId.trim()) {
      setError(t(uiLanguage, "authenticatedTenantNotLoaded"));
      return;
    }

    setPublishing(true);
    setError(null);

    const selector: Record<string, string> = {};

    if (publishScope === "role" && roleId.trim()) {
      selector.roleId = roleId.trim();
    }

    if (publishScope === "user" && userId.trim()) {
      selector.userId = userId.trim();
    }

    if (publishScope === "device" && deviceId.trim()) {
      selector.deviceId = deviceId.trim();
    }

    const response = await fetch("/api/config/packages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        actorId: "operator-web",
        actorRole,
        scope: publishScope,
        tenantId,
        selector,
        rollout: {
          activation: publishActivation,
          startsAt: publishStartsAt ? new Date(publishStartsAt).toISOString() : undefined,
          endsAt: publishEndsAt ? new Date(publishEndsAt).toISOString() : undefined,
          batchUserIds: publishBatchUsers
            .split(",")
            .map((value) => value.trim())
            .filter(Boolean)
        },
        rules: {
          appUpdateChannel: publishChannel,
          enableVoiceCommands: publishVoice,
          step1Ui: step1UiDraft,
          checkinSections: builtSections,
          step1: builtStep1,
          step2: builtStep2,
          camera: builtCamera
        }
      })
    });

    if (!response.ok) {
      setPublishing(false);
      setError(`${t(uiLanguage, "publishPackageFailed")}: HTTP ${response.status}`);
      return;
    }

    const [resolved, auditResult, packagesResult] = await Promise.all([
      fetchResolveByRole(query),
      fetchAuditByRole(tenantId, actorRole),
      fetchPackages(tenantId, actorRole)
    ]);
    setPayload(resolved);
    setAudit(auditResult.items);
    setPackages(packagesResult.items);
    setPublishing(false);
  };

  const rollbackPackage = async (packageId: string) => {
    if (!tenantId.trim()) {
      setError(t(uiLanguage, "authenticatedTenantNotLoaded"));
      return;
    }

    setRollingBackId(packageId);
    setError(null);

    const response = await fetch("/api/config/packages/rollback", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        packageId,
        tenantId,
        actorId: "operator-web",
        actorRole
      })
    });

    if (!response.ok) {
      setRollingBackId(null);
      setError(`${t(uiLanguage, "rollbackPackageFailed")}: HTTP ${response.status}`);
      return;
    }

    const [resolved, auditResult, packagesResult] = await Promise.all([
      fetchResolveByRole(query),
      fetchAuditByRole(tenantId, actorRole),
      fetchPackages(tenantId, actorRole)
    ]);
    setPayload(resolved);
    setAudit(auditResult.items);
    setPackages(packagesResult.items);
    setRollingBackId(null);
  };

  const approvePackage = async (packageId: string) => {
    if (!tenantId.trim()) {
      setError(t(uiLanguage, "authenticatedTenantNotLoaded"));
      return;
    }

    setApprovingId(packageId);
    setError(null);

    const response = await fetch("/api/config/packages/approve", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        packageId,
        tenantId,
        actorId: "approver-web",
        actorRole
      })
    });

    if (!response.ok) {
      setApprovingId(null);
      setError(`${t(uiLanguage, "approvePackageFailed")}: HTTP ${response.status}`);
      return;
    }

    const [resolved, auditResult, packagesResult] = await Promise.all([
      fetchResolveByRole(query),
      fetchAuditByRole(tenantId, actorRole),
      fetchPackages(tenantId, actorRole)
    ]);
    setPayload(resolved);
    setAudit(auditResult.items);
    setPackages(packagesResult.items);
    setApprovingId(null);
  };

  const updateSectionDraft = (index: number, patch: Partial<SectionDraft>) => {
    setSectionDrafts((current) => current.map((item, itemIndex) => (itemIndex === index ? { ...item, ...patch } : item)));
  };

  const updateSubtypeDraft = (index: number, patch: Partial<Step1SubtypeDraft>) => {
    setStep1SubtypeDrafts((current) => current.map((item, itemIndex) => (itemIndex === index ? { ...item, ...patch } : item)));
  };

  const updateStep1LevelDraft = (index: number, patch: Partial<Step1LevelDraft>) => {
    setStep1LevelDrafts((current) => current.map((item, itemIndex) => (itemIndex === index ? { ...item, ...patch } : item)));
  };

  const updateStep2TypeDraft = (index: number, patch: Partial<Step2TypeDraft>) => {
    setStep2TypeDrafts((current) => current.map((item, itemIndex) => (itemIndex === index ? { ...item, ...patch } : item)));
  };

  const updateStep2PhotoField = (typeIndex: number, fieldIndex: number, patch: Partial<Step2PhotoFieldDraft>) => {
    setStep2TypeDrafts((current) =>
      current.map((typeItem, currentTypeIndex) =>
        currentTypeIndex === typeIndex
          ? {
              ...typeItem,
              photoFields: typeItem.photoFields.map((field, currentFieldIndex) =>
                currentFieldIndex === fieldIndex ? { ...field, ...patch } : field
              )
            }
          : typeItem
      )
    );
  };

  const updateStep2OptionGroup = (typeIndex: number, groupIndex: number, patch: Partial<Step2OptionGroupDraft>) => {
    setStep2TypeDrafts((current) =>
      current.map((typeItem, currentTypeIndex) =>
        currentTypeIndex === typeIndex
          ? {
              ...typeItem,
              optionGroups: typeItem.optionGroups.map((group, currentGroupIndex) =>
                currentGroupIndex === groupIndex ? { ...group, ...patch } : group
              )
            }
          : typeItem
      )
    );
  };

  const updateStep2Option = (
    typeIndex: number,
    groupIndex: number,
    optionIndex: number,
    patch: Partial<Step2OptionDraft>
  ) => {
    setStep2TypeDrafts((current) =>
      current.map((typeItem, currentTypeIndex) =>
        currentTypeIndex === typeIndex
          ? {
              ...typeItem,
              optionGroups: typeItem.optionGroups.map((group, currentGroupIndex) =>
                currentGroupIndex === groupIndex
                  ? {
                      ...group,
                      opcoes: group.opcoes.map((option, currentOptionIndex) =>
                        currentOptionIndex === optionIndex ? { ...option, ...patch } : option
                      )
                    }
                  : group
              )
            }
          : typeItem
      )
    );
  };

  const updateCameraTypeDraft = (index: number, patch: Partial<CameraTypeDraft>) => {
    setCameraTypeDrafts((current) => current.map((item, itemIndex) => (itemIndex === index ? { ...item, ...patch } : item)));
  };

  const updateCameraLevelDraft = (typeIndex: number, levelIndex: number, patch: Partial<CameraLevelDraft>) => {
    setCameraTypeDrafts((current) =>
      current.map((typeItem, currentTypeIndex) =>
        currentTypeIndex === typeIndex
          ? {
              ...typeItem,
              levels: typeItem.levels.map((level, currentLevelIndex) =>
                currentLevelIndex === levelIndex ? { ...level, ...patch } : level
              )
            }
          : typeItem
      )
    );
  };

  const removeSectionDraft = (index: number) => {
    setSectionDrafts((current) => current.filter((_, itemIndex) => itemIndex !== index));
  };

  const removeSubtypeDraft = (index: number) => {
    setStep1SubtypeDrafts((current) => current.filter((_, itemIndex) => itemIndex !== index));
  };

  const removeStep1LevelDraft = (index: number) => {
    setStep1LevelDrafts((current) => current.filter((_, itemIndex) => itemIndex !== index));
  };

  const removeStep2TypeDraft = (index: number) => {
    setStep2TypeDrafts((current) => current.filter((_, itemIndex) => itemIndex !== index));
  };

  const removeStep2PhotoField = (typeIndex: number, fieldIndex: number) => {
    setStep2TypeDrafts((current) =>
      current.map((typeItem, currentTypeIndex) =>
        currentTypeIndex === typeIndex
          ? {
              ...typeItem,
              photoFields: typeItem.photoFields.filter((_, currentFieldIndex) => currentFieldIndex !== fieldIndex)
            }
          : typeItem
      )
    );
  };

  const removeStep2OptionGroup = (typeIndex: number, groupIndex: number) => {
    setStep2TypeDrafts((current) =>
      current.map((typeItem, currentTypeIndex) =>
        currentTypeIndex === typeIndex
          ? {
              ...typeItem,
              optionGroups: typeItem.optionGroups.filter((_, currentGroupIndex) => currentGroupIndex !== groupIndex)
            }
          : typeItem
      )
    );
  };

  const removeStep2Option = (typeIndex: number, groupIndex: number, optionIndex: number) => {
    setStep2TypeDrafts((current) =>
      current.map((typeItem, currentTypeIndex) =>
        currentTypeIndex === typeIndex
          ? {
              ...typeItem,
              optionGroups: typeItem.optionGroups.map((group, currentGroupIndex) =>
                currentGroupIndex === groupIndex
                  ? {
                      ...group,
                      opcoes: group.opcoes.filter((_, currentOptionIndex) => currentOptionIndex !== optionIndex)
                    }
                  : group
              )
            }
          : typeItem
      )
    );
  };

  const removeCameraTypeDraft = (index: number) => {
    setCameraTypeDrafts((current) => current.filter((_, itemIndex) => itemIndex !== index));
  };

  const removeCameraLevelDraft = (typeIndex: number, levelIndex: number) => {
    setCameraTypeDrafts((current) =>
      current.map((typeItem, currentTypeIndex) =>
        currentTypeIndex === typeIndex
          ? {
              ...typeItem,
              levels: typeItem.levels.filter((_, currentLevelIndex) => currentLevelIndex !== levelIndex)
            }
          : typeItem
      )
    );
  };

  const tipoImovelItems = splitCsv(step1TiposCsv);
  const areaFotoItems = splitCsv(step1ContextosCsv);
  const currentTipoImovel = tipoImovelItems.includes(selectedTipoImovel) ? selectedTipoImovel : tipoImovelItems[0] ?? "";
  const currentTipoKey = normalizeKey(currentTipoImovel);
  const currentSubtypeRow = step1SubtypeDrafts.find((row) => normalizeKey(row.tipo) === currentTipoKey);
  const currentSubtipoItems = splitCsv(currentSubtypeRow?.subtiposCsv ?? "");
  const currentSubtipo = currentSubtipoItems.includes(selectedSubtipo) ? selectedSubtipo : currentSubtipoItems[0] ?? "";
  const currentAreaFoto = areaFotoItems.includes(selectedAreaFoto) ? selectedAreaFoto : areaFotoItems[0] ?? "";
  const currentCameraType =
    cameraTypeDrafts.find((row) => normalizeKey(row.propertyType) === currentTipoKey) ?? null;
  const currentSubtypeCameraDraft =
    currentCameraType?.subtypes.find((subtypeRow) => normalizeKey(subtypeRow.subtype) === normalizeKey(currentSubtipo)) ??
    null;
  const currentMacroLocalDraft =
    currentSubtypeCameraDraft?.macroLocals.find((macroLocal) => normalizeKey(macroLocal.macroLocal) === normalizeKey(currentAreaFoto)) ??
    null;
  const getCameraLevelDraftById = (levelId: string) =>
    currentCameraType?.levels.find((level) => normalizeKey(level.id) === normalizeKey(levelId)) ?? null;
  const macroInactiveParent = `${currentTipoImovel}:${currentSubtipo}:${currentAreaFoto}`;
  const ambienteItems = splitCsv(currentMacroLocalDraft?.ambientesCsv ?? "");
  const currentAmbiente = ambienteItems.includes(selectedAmbiente) ? selectedAmbiente : ambienteItems[0] ?? "";
  const elementoItems = splitCsv(currentMacroLocalDraft?.elementosCsv ?? "");
  const currentElemento = elementoItems.includes(selectedElemento) ? selectedElemento : elementoItems[0] ?? "";
  const materialItems = splitCsv(currentMacroLocalDraft?.materiaisCsv ?? "");
  const currentMaterial = materialItems.includes(selectedMaterial) ? selectedMaterial : materialItems[0] ?? "";
  const estadoItems = splitCsv(currentMacroLocalDraft?.estadosCsv ?? "");
  const currentEstado = estadoItems.includes(selectedEstado) ? selectedEstado : estadoItems[0] ?? "";

  const currentCameraPath = [currentTipoImovel, currentSubtipo, currentAreaFoto, currentAmbiente, currentElemento, currentMaterial, currentEstado]
    .filter(Boolean)
    .join(" / ");

  const canonicalTree = useMemo<CanonicalTreeNode[]>(() => {
    return tipoImovelItems.map((tipo) => {
      const subtipos = splitCsv(
        step1SubtypeDrafts.find((row) => normalizeKey(row.tipo) === normalizeKey(tipo))?.subtiposCsv ?? ""
      );
      const cameraType =
        effectiveCameraTypeDrafts.find((row) => normalizeKey(row.propertyType) === normalizeKey(tipo)) ?? null;

      return {
        id: `tipo:${tipo}`,
        label: tipo,
        level: "tipoImovel",
        path: { tipoImovel: tipo },
        children: subtipos.map((subtipo) => ({
          id: `tipo:${tipo}|subtipo:${subtipo}`,
          label: subtipo,
          level: "subtipo",
          path: { tipoImovel: tipo, subtipo },
          children: areaFotoItems.map((area) => {
            const subtypeBranch = cameraType?.subtypes.find(
              (branch) => normalizeKey(branch.subtype) === normalizeKey(subtipo)
            );
            const macroLocal = subtypeBranch?.macroLocals.find(
              (branch) => normalizeKey(branch.macroLocal) === normalizeKey(area)
            );
            const ambientes = splitCsv(macroLocal?.ambientesCsv ?? "");
            const elementos = splitCsv(macroLocal?.elementosCsv ?? "");
            const materiais = splitCsv(macroLocal?.materiaisCsv ?? "");
            const estados = splitCsv(macroLocal?.estadosCsv ?? "");

            return {
              id: `tipo:${tipo}|subtipo:${subtipo}|area:${area}`,
              label: area,
              level: "areaFoto",
              path: { tipoImovel: tipo, subtipo, areaFoto: area },
              children: ambientes.map((ambiente) => ({
                id: `tipo:${tipo}|subtipo:${subtipo}|area:${area}|ambiente:${ambiente}`,
                label: ambiente,
                level: "ambiente",
                path: { tipoImovel: tipo, subtipo, areaFoto: area, ambiente },
                children: elementos.map((elemento) => ({
                  id: `tipo:${tipo}|subtipo:${subtipo}|area:${area}|ambiente:${ambiente}|elemento:${elemento}`,
                  label: elemento,
                  level: "elemento",
                  path: { tipoImovel: tipo, subtipo, areaFoto: area, ambiente, elemento },
                  children: [
                    ...materiais.map((material) => ({
                      id: `tipo:${tipo}|subtipo:${subtipo}|area:${area}|ambiente:${ambiente}|elemento:${elemento}|material:${material}`,
                      label: material,
                      level: "material" as const,
                      path: { tipoImovel: tipo, subtipo, areaFoto: area, ambiente, elemento, material }
                    })),
                    ...estados.map((estado) => ({
                      id: `tipo:${tipo}|subtipo:${subtipo}|area:${area}|ambiente:${ambiente}|elemento:${elemento}|estado:${estado}`,
                      label: estado,
                      level: "estado" as const,
                      path: { tipoImovel: tipo, subtipo, areaFoto: area, ambiente, elemento, estado }
                    }))
                  ]
                }))
              }))
            };
          })
        }))
      };
    });
  }, [tipoImovelItems, step1SubtypeDrafts, effectiveCameraTypeDrafts, areaFotoItems]);

  const findTreeNodeById = useCallback((nodes: CanonicalTreeNode[], targetId: string): CanonicalTreeNode | null => {
    for (const node of nodes) {
      if (node.id === targetId) {
        return node;
      }
      const found = node.children ? findTreeNodeById(node.children, targetId) : null;
      if (found) {
        return found;
      }
    }
    return null;
  }, []);

  const selectedTreeNode =
    findTreeNodeById(canonicalTree, selectedTreeNodeId) ??
    canonicalTree[0] ??
    null;

  const collectExpandableNodeIds = useCallback((nodes: CanonicalTreeNode[]): string[] => {
    return nodes.flatMap((node) => [
      ...(node.children && node.children.length > 0 ? [node.id] : []),
      ...(node.children ? collectExpandableNodeIds(node.children) : [])
    ]);
  }, []);

  const filteredCanonicalTree = useMemo<CanonicalTreeNode[]>(() => {
    if (selectedAreaFilter === "all") {
      return canonicalTree;
    }

    const filterNodes = (nodes: CanonicalTreeNode[]): CanonicalTreeNode[] => {
      const mapped: Array<CanonicalTreeNode | null> = nodes.map((node) => {
        const nextChildren = node.children ? filterNodes(node.children) : [];
        const keepSelf = node.level !== "areaFoto" || node.label === selectedAreaFilter;
        if (keepSelf && (node.level === "areaFoto" || nextChildren.length > 0 || node.level === "tipoImovel" || node.level === "subtipo")) {
          return {
            ...node,
            children: nextChildren
          };
        }
        if (node.level !== "areaFoto" && nextChildren.length > 0) {
          return {
            ...node,
            children: nextChildren
          };
        }
        return keepSelf ? { ...node, children: nextChildren } : null;
      });

      return mapped.filter((node): node is CanonicalTreeNode => {
        if (node === null) {
          return false;
        }
        return node.level === "areaFoto" || (node.children ? node.children.length > 0 : true);
      });
    };

    return filterNodes(canonicalTree);
  }, [canonicalTree, selectedAreaFilter]);

  useEffect(() => {
    if (tipoImovelItems.length > 0 && !tipoImovelItems.includes(selectedTipoImovel)) {
      setSelectedTipoImovel(tipoImovelItems[0]);
    }
  }, [tipoImovelItems, selectedTipoImovel]);

  useEffect(() => {
    if (!currentTipoImovel) {
      return;
    }
    if (cameraTypeDrafts.some((row) => normalizeKey(row.propertyType) === currentTipoKey)) {
      return;
    }
    setCameraTypeDrafts((current) => [
      ...current,
      {
        propertyType: currentTipoImovel,
        subtypes: buildDefaultSubtypeDrafts(currentSubtipoItems, areaFotoItems),
        levels: buildDefaultCameraLevels(current[0] ?? null)
      }
    ]);
  }, [areaFotoItems, cameraTypeDrafts, currentTipoImovel, currentTipoKey, currentSubtipoItems]);

  useEffect(() => {
    if (areaFotoItems.length === 0 || currentSubtipoItems.length === 0) {
      return;
    }
    setCameraTypeDrafts((current) =>
      current.map((row) => {
        const existing = new Map(row.subtypes.map((subtypeRow) => [normalizeKey(subtypeRow.subtype), subtypeRow]));
        return {
          ...row,
          subtypes: currentSubtipoItems.map((subtype) => {
            const existingSubtype = existing.get(normalizeKey(subtype));
            const existingMacroLocals = new Map(
              (existingSubtype?.macroLocals ?? []).map((macroLocal) => [normalizeKey(macroLocal.macroLocal), macroLocal])
            );
            return {
              subtype,
              macroLocals: areaFotoItems.map(
                (context) =>
                  existingMacroLocals.get(normalizeKey(context)) ?? {
                    macroLocal: context,
                    ambientesCsv: "",
                    elementosCsv: "",
                    materiaisCsv: "",
                    estadosCsv: ""
                  }
              )
            };
          })
        };
      })
    );
  }, [areaFotoItems, currentSubtipoItems]);

  useEffect(() => {
    if (currentSubtipoItems.length > 0 && !currentSubtipoItems.includes(selectedSubtipo)) {
      setSelectedSubtipo(currentSubtipoItems[0]);
    }
  }, [currentSubtipoItems, selectedSubtipo]);

  useEffect(() => {
    if (areaFotoItems.length > 0 && !areaFotoItems.includes(selectedAreaFoto)) {
      setSelectedAreaFoto(areaFotoItems[0]);
    }
  }, [areaFotoItems, selectedAreaFoto]);

  useEffect(() => {
    if (ambienteItems.length > 0 && !ambienteItems.includes(selectedAmbiente)) {
      setSelectedAmbiente(ambienteItems[0]);
    }
  }, [ambienteItems, selectedAmbiente]);

  useEffect(() => {
    if (elementoItems.length > 0 && !elementoItems.includes(selectedElemento)) {
      setSelectedElemento(elementoItems[0]);
    }
  }, [elementoItems, selectedElemento]);

  useEffect(() => {
    if (materialItems.length > 0 && !materialItems.includes(selectedMaterial)) {
      setSelectedMaterial(materialItems[0]);
    }
  }, [materialItems, selectedMaterial]);

  useEffect(() => {
    if (estadoItems.length > 0 && !estadoItems.includes(selectedEstado)) {
      setSelectedEstado(estadoItems[0]);
    }
  }, [estadoItems, selectedEstado]);

  useEffect(() => {
    setSelectedSubtipo("");
    setSelectedAreaFoto("");
    setSelectedAmbiente("");
    setSelectedElemento("");
    setSelectedMaterial("");
    setSelectedEstado("");
  }, [currentTipoImovel]);

  useEffect(() => {
    setSelectedAreaFoto("");
    setSelectedAmbiente("");
    setSelectedElemento("");
    setSelectedMaterial("");
    setSelectedEstado("");
  }, [currentSubtipo]);

  useEffect(() => {
    setSelectedAmbiente("");
    setSelectedElemento("");
    setSelectedMaterial("");
    setSelectedEstado("");
  }, [currentAreaFoto]);

  useEffect(() => {
    setSelectedElemento("");
    setSelectedMaterial("");
    setSelectedEstado("");
  }, [currentAmbiente]);

  useEffect(() => {
    setSelectedMaterial("");
    setSelectedEstado("");
  }, [currentElemento]);

  useEffect(() => {
    if (!selectedTreeNodeId && canonicalTree.length > 0) {
      setSelectedTreeNodeId(canonicalTree[0].id);
    }
  }, [canonicalTree, selectedTreeNodeId]);

  useEffect(() => {
    if (selectedTreeNode) {
      setSelectedNodeLabelDraft(selectedTreeNode.label);
    }
  }, [selectedTreeNode]);

  useEffect(() => {
    if (expandedTreeNodeIds.length === 0 && canonicalTree.length > 0) {
      setExpandedTreeNodeIds(collectExpandableNodeIds(canonicalTree));
    }
  }, [canonicalTree, collectExpandableNodeIds, expandedTreeNodeIds.length]);

  const setInactiveForKey = (inactiveKey: string, items: string[]) => {
    setInactiveCanonicalItems((current) => ({
      ...current,
      [inactiveKey]: uniqueLabels(items)
    }));
  };

  const toggleCanonicalItem = (inactiveKey: string, item: string, nextActive: boolean) => {
    setInactiveCanonicalItems((current) => {
      const currentItems = new Set(current[inactiveKey] ?? []);
      if (nextActive) {
        currentItems.delete(item);
      } else {
        currentItems.add(item);
      }
      return {
        ...current,
        [inactiveKey]: Array.from(currentItems)
      };
    });
  };

  const updateSimpleCsvList = (value: string, setter: (next: string) => void, index: number, nextLabel: string, inactiveKey: string) => {
    const items = splitCsv(value);
    const previous = items[index] ?? "";
    items[index] = nextLabel;
    setter(joinCsv(items));
    if (previous && previous !== nextLabel) {
      const blocked = new Set(inactiveCanonicalItems[inactiveKey] ?? []);
      if (blocked.delete(previous)) {
        blocked.add(nextLabel);
        setInactiveForKey(inactiveKey, Array.from(blocked));
      }
    }
  };

  const removeSimpleCsvItem = (value: string, setter: (next: string) => void, index: number, inactiveKey: string) => {
    const items = splitCsv(value);
    const removed = items[index];
    setter(joinCsv(items.filter((_, itemIndex) => itemIndex !== index)));
    if (removed) {
      setInactiveForKey(
        inactiveKey,
        (inactiveCanonicalItems[inactiveKey] ?? []).filter((item) => item !== removed)
      );
    }
  };

  const updateSubtypeList = (tipo: string, index: number, nextLabel: string) => {
    const inactiveKey = getInactiveKey("subtipo", tipo);
    setStep1SubtypeDrafts((current) =>
      current.map((row) => {
        if (normalizeKey(row.tipo) !== normalizeKey(tipo)) {
          return row;
        }
        const items = splitCsv(row.subtiposCsv);
        const previous = items[index] ?? "";
        items[index] = nextLabel;
        if (previous && previous !== nextLabel) {
          const blocked = new Set(inactiveCanonicalItems[inactiveKey] ?? []);
          if (blocked.delete(previous)) {
            blocked.add(nextLabel);
            setInactiveForKey(inactiveKey, Array.from(blocked));
          }
        }
        return { ...row, subtiposCsv: joinCsv(items) };
      })
    );
  };

  const addSubtypeItem = (tipo: string) => {
    setStep1SubtypeDrafts((current) =>
      current.some((row) => normalizeKey(row.tipo) === normalizeKey(tipo))
        ? current.map((row) =>
            normalizeKey(row.tipo) === normalizeKey(tipo)
              ? { ...row, subtiposCsv: joinCsv([...splitCsv(row.subtiposCsv), "Novo subtipo"]) }
              : row
          )
        : [...current, { tipo, subtiposCsv: "Novo subtipo" }]
    );
  };

  const removeSubtypeItem = (tipo: string, index: number) => {
    const inactiveKey = getInactiveKey("subtipo", tipo);
    setStep1SubtypeDrafts((current) =>
      current.map((row) => {
        if (normalizeKey(row.tipo) !== normalizeKey(tipo)) {
          return row;
        }
        const items = splitCsv(row.subtiposCsv);
        const removed = items[index];
        if (removed) {
          setInactiveForKey(
            inactiveKey,
            (inactiveCanonicalItems[inactiveKey] ?? []).filter((item) => item !== removed)
          );
        }
        return { ...row, subtiposCsv: joinCsv(items.filter((_, itemIndex) => itemIndex !== index)) };
      })
    );
  };

  const removeTipoItem = (tipo: string) => {
    const tipoIndex = splitCsv(step1TiposCsv).findIndex((item) => normalizeKey(item) === normalizeKey(tipo));
    if (tipoIndex >= 0) {
      removeSimpleCsvItem(step1TiposCsv, setStep1TiposCsv, tipoIndex, getInactiveKey("tipoImovel"));
    }
    setStep1SubtypeDrafts((current) => current.filter((row) => normalizeKey(row.tipo) !== normalizeKey(tipo)));
    setCameraTypeDrafts((current) => current.filter((row) => normalizeKey(row.propertyType) !== normalizeKey(tipo)));
  };

  const updateCameraBranchCsv = (
    propertyType: string,
    subtype: string,
    macroLocal: string,
    propertyName: "ambientesCsv" | "elementosCsv" | "materiaisCsv" | "estadosCsv",
    updater: (currentValue: string) => string
  ) => {
    setCameraTypeDrafts((current) =>
      current.map((row) =>
        normalizeKey(row.propertyType) !== normalizeKey(propertyType)
          ? row
          : {
              ...row,
              subtypes: row.subtypes.map((subtypeRow) =>
                normalizeKey(subtypeRow.subtype) !== normalizeKey(subtype)
                  ? subtypeRow
                  : {
                      ...subtypeRow,
                      macroLocals: subtypeRow.macroLocals.map((branch) =>
                        normalizeKey(branch.macroLocal) !== normalizeKey(macroLocal)
                          ? branch
                          : {
                              ...branch,
                              [propertyName]: updater(branch[propertyName])
                            }
                      )
                    }
              )
            }
      )
    );
  };

  const ensureStep2TypeDraft = (propertyType: string) => {
    setStep2TypeDrafts((current) => {
      if (current.some((row) => normalizeKey(row.propertyType) === normalizeKey(propertyType))) {
        return current;
      }
      return [
        ...current,
        {
          propertyType,
          screenLabel: "Etapa 2 Vistoria",
          subtitleLabel: "",
          photoSectionLabel: "Registro Fotografico",
          photoSectionVisible: true,
          photoSectionRequired: false,
          optionSectionLabel: "Infraestrutura e Servicos",
          optionSectionVisible: true,
          optionSectionRequired: false,
          confirmButtonLabel: "Confirmar e abrir a camera",
          visivel: true,
          obrigatoria: false,
          bloqueiaCaptura: false,
          minFotos: "0",
          maxFotos: "",
          photoFields: [],
          optionGroups: []
        }
      ];
    });
  };

  const updateSelectedTypeOperationalConfig = (patch: Partial<Step2TypeDraft>) => {
    const propertyType = selectedTreeNode?.path.tipoImovel;
    if (!propertyType) {
      return;
    }
    ensureStep2TypeDraft(propertyType);
    setStep2TypeDrafts((current) =>
      current.map((row) =>
        normalizeKey(row.propertyType) === normalizeKey(propertyType) ? { ...row, ...patch } : row
      )
    );
  };

  const updateCameraLevelOptions = (
    propertyType: string,
    subtype: string,
    macroLocal: string,
    levelId: string,
    index: number,
    nextLabel: string
  ) => {
    const inactiveKey = getInactiveKey(levelId as CanonicalLevelId, `${propertyType}:${subtype}:${macroLocal}`);
    const propertyName =
      levelId === "ambiente"
        ? "ambientesCsv"
        : levelId === "elemento"
          ? "elementosCsv"
          : levelId === "material"
            ? "materiaisCsv"
            : "estadosCsv";
    setCameraTypeDrafts((current) =>
      current.map((row) => {
        if (normalizeKey(row.propertyType) !== normalizeKey(propertyType)) {
          return row;
        }
        return {
          ...row,
          subtypes: row.subtypes.map((subtypeRow) =>
            normalizeKey(subtypeRow.subtype) !== normalizeKey(subtype)
              ? subtypeRow
              : {
                  ...subtypeRow,
                  macroLocals: subtypeRow.macroLocals.map((branch) => {
                    if (normalizeKey(branch.macroLocal) !== normalizeKey(macroLocal)) {
                      return branch;
                    }
                    const items = splitCsv(branch[propertyName]);
                    const previous = items[index] ?? "";
                    items[index] = nextLabel;
                    if (previous && previous !== nextLabel) {
                      const blocked = new Set(inactiveCanonicalItems[inactiveKey] ?? []);
                      if (blocked.delete(previous)) {
                        blocked.add(nextLabel);
                        setInactiveForKey(inactiveKey, Array.from(blocked));
                      }
                    }
                    return { ...branch, [propertyName]: joinCsv(items) };
                  })
                }
          )
        };
      })
    );
  };

  const addCameraLevelOption = (propertyType: string, subtype: string, macroLocal: string, levelId: string) => {
    const propertyName =
      levelId === "ambiente"
        ? "ambientesCsv"
        : levelId === "elemento"
          ? "elementosCsv"
          : levelId === "material"
            ? "materiaisCsv"
            : "estadosCsv";
    setCameraTypeDrafts((current) =>
      current.some((row) => normalizeKey(row.propertyType) === normalizeKey(propertyType))
        ? current.map((row) => {
            if (normalizeKey(row.propertyType) !== normalizeKey(propertyType)) {
              return row;
            }
            return {
              ...row,
              subtypes: row.subtypes.map((subtypeRow) =>
                normalizeKey(subtypeRow.subtype) !== normalizeKey(subtype)
                  ? subtypeRow
                  : {
                      ...subtypeRow,
                      macroLocals: subtypeRow.macroLocals.map((branch) =>
                        normalizeKey(branch.macroLocal) === normalizeKey(macroLocal)
                          ? {
                              ...branch,
                              [propertyName]: joinCsv([
                                ...splitCsv(branch[propertyName]),
                                `Novo ${levelId}`
                              ])
                            }
                          : branch
                      )
                    }
              )
            };
          })
        : [
            ...current,
            {
              propertyType,
              subtypes: buildDefaultSubtypeDrafts([subtype], areaFotoItems).map((subtypeRow) =>
                normalizeKey(subtypeRow.subtype) !== normalizeKey(subtype)
                  ? subtypeRow
                  : {
                      ...subtypeRow,
                      macroLocals: subtypeRow.macroLocals.map((branch) =>
                        normalizeKey(branch.macroLocal) === normalizeKey(macroLocal)
                          ? { ...branch, [propertyName]: `Novo ${levelId}` }
                          : branch
                      )
                    }
              ),
              levels: buildDefaultCameraLevels(current[0] ?? null).map((level) =>
                normalizeKey(level.id) === normalizeKey(levelId)
                  ? { ...level, optionsCsv: `Novo ${level.label || levelId}` }
                  : level
              )
            }
          ]
    );
  };

  const removeCameraLevelOption = (propertyType: string, subtype: string, macroLocal: string, levelId: string, index: number) => {
    const inactiveKey = getInactiveKey(levelId as CanonicalLevelId, `${propertyType}:${subtype}:${macroLocal}`);
    const propertyName =
      levelId === "ambiente"
        ? "ambientesCsv"
        : levelId === "elemento"
          ? "elementosCsv"
          : levelId === "material"
            ? "materiaisCsv"
            : "estadosCsv";
    setCameraTypeDrafts((current) =>
      current.map((row) => {
        if (normalizeKey(row.propertyType) !== normalizeKey(propertyType)) {
          return row;
        }
        return {
          ...row,
          subtypes: row.subtypes.map((subtypeRow) =>
            normalizeKey(subtypeRow.subtype) !== normalizeKey(subtype)
              ? subtypeRow
              : {
                  ...subtypeRow,
                  macroLocals: subtypeRow.macroLocals.map((branch) => {
                    if (normalizeKey(branch.macroLocal) !== normalizeKey(macroLocal)) {
                      return branch;
                    }
                    const items = splitCsv(branch[propertyName]);
                    const removed = items[index];
                    if (removed) {
                      setInactiveForKey(
                        inactiveKey,
                        (inactiveCanonicalItems[inactiveKey] ?? []).filter((item) => item !== removed)
                      );
                    }
                    return { ...branch, [propertyName]: joinCsv(items.filter((_, itemIndex) => itemIndex !== index)) };
                  })
                }
          )
        };
      })
    );
  };

  const addCanonicalCameraLevel = () => {
    if (!currentCameraType) {
      return;
    }
    const ordered = ["ambiente", "elemento", "material", "estado"];
    const missing = ordered.find(
      (levelId) => !currentCameraType.levels.some((level) => normalizeKey(level.id) === levelId)
    );
    if (!missing) {
      return;
    }
    const dependsOn =
      missing === "ambiente"
        ? ""
        : missing === "elemento"
          ? "ambiente"
          : missing === "material"
            ? "elemento"
            : "material";
    const label = CANONICAL_LEVELS.find((level) => level.id === missing)?.label ?? missing;
    setCameraTypeDrafts((current) =>
      current.map((row) =>
        normalizeKey(row.propertyType) === normalizeKey(currentCameraType.propertyType)
          ? {
              ...row,
              levels: [...row.levels, { id: missing, label, required: true, dependsOn, optionsCsv: "" }]
            }
          : row
      )
    );
  };

  const removeCanonicalCameraLevel = () => {
    if (!currentCameraType || currentCameraType.levels.length <= 1) {
      return;
    }
    const removableOrder = ["estado", "material", "elemento"];
    const target = removableOrder.find((levelId) =>
      currentCameraType.levels.some((level) => normalizeKey(level.id) === levelId)
    );
    if (!target) {
      return;
    }
    setCameraTypeDrafts((current) =>
      current.map((row) =>
        normalizeKey(row.propertyType) === normalizeKey(currentCameraType.propertyType)
          ? {
              ...row,
              levels: row.levels.filter((level) => normalizeKey(level.id) !== target)
            }
          : row
      )
    );
  };

  const renderCanonicalItems = (
    title: string,
    levelId: CanonicalLevelId,
    items: string[],
    inactiveKey: string,
    handlers: {
      onSelect?: (item: string) => void;
      isSelected?: (item: string) => boolean;
      onChange: (index: number, nextLabel: string) => void;
      onAdd: () => void;
      onRemove: (index: number) => void;
    }
  ) => (
    <article className={`canonical-column${selectedCanonicalLevel === levelId ? " is-active" : ""}`}>
      <div className="canonical-column-head">
        <button type="button" className="canonical-level-chip" onClick={() => setSelectedCanonicalLevel(levelId)}>
          {title}
        </button>
        <button type="button" className="inline-action" onClick={handlers.onAdd}>
          + Item
        </button>
      </div>
      <div className="canonical-list">
        {items.length === 0 && <p className="canonical-empty">Nenhum item configurado neste nivel.</p>}
        {items.map((item, index) => {
          const active = !(inactiveCanonicalItems[inactiveKey] ?? []).includes(item);
          return (
            <div key={`${levelId}-${index}`} className={`canonical-row${handlers.isSelected?.(item) ? " is-selected" : ""}`}>
              <label className="canonical-toggle">
                <input
                  type="checkbox"
                  checked={active}
                  onChange={(event) => toggleCanonicalItem(inactiveKey, item, event.target.checked)}
                />
              </label>
              <input
                value={item}
                onClick={() => handlers.onSelect?.(item)}
                onFocus={() => handlers.onSelect?.(item)}
                onChange={(event) => handlers.onChange(index, event.target.value)}
              />
              <button type="button" className="inline-action" onClick={() => handlers.onRemove(index)}>
                -
              </button>
            </div>
          );
        })}
      </div>
    </article>
  );

  const handleTreeSelection = (node: CanonicalTreeNode) => {
    setSelectedTreeNodeId(node.id);
    if (node.path.tipoImovel) {
      setSelectedTipoImovel(node.path.tipoImovel);
    }
    if (node.path.subtipo) {
      setSelectedSubtipo(node.path.subtipo);
    }
    if (node.path.areaFoto) {
      setSelectedAreaFoto(node.path.areaFoto);
    }
    if (node.path.ambiente) {
      setSelectedAmbiente(node.path.ambiente);
    }
    if (node.path.elemento) {
      setSelectedElemento(node.path.elemento);
    }
    if (node.path.material) {
      setSelectedMaterial(node.path.material);
    }
    if (node.path.estado) {
      setSelectedEstado(node.path.estado);
    }
  };

  const renameSelectedTreeNode = (nextLabel: string) => {
    if (!selectedTreeNode || !nextLabel.trim()) {
      return;
    }
    const value = nextLabel.trim();
    if (selectedTreeNode.level === "tipoImovel" && selectedTreeNode.path.tipoImovel) {
      const index = splitCsv(step1TiposCsv).findIndex((item) => item === selectedTreeNode.path.tipoImovel);
      if (index >= 0) {
        updateSimpleCsvList(step1TiposCsv, setStep1TiposCsv, index, value, getInactiveKey("tipoImovel"));
      }
      setStep1SubtypeDrafts((current) =>
        current.map((row) =>
          row.tipo === selectedTreeNode.path.tipoImovel ? { ...row, tipo: value } : row
        )
      );
      setCameraTypeDrafts((current) =>
        current.map((row) =>
          row.propertyType === selectedTreeNode.path.tipoImovel ? { ...row, propertyType: value } : row
        )
      );
      setSelectedTipoImovel(value);
      return;
    }

    if (selectedTreeNode.level === "subtipo" && selectedTreeNode.path.tipoImovel && selectedTreeNode.path.subtipo) {
      const index = currentSubtipoItems.findIndex((item) => item === selectedTreeNode.path.subtipo);
      if (index >= 0) {
        updateSubtypeList(selectedTreeNode.path.tipoImovel, index, value);
      }
      setCameraTypeDrafts((current) =>
        current.map((row) =>
          normalizeKey(row.propertyType) !== normalizeKey(selectedTreeNode.path.tipoImovel ?? "")
            ? row
            : {
                ...row,
                subtypes: row.subtypes.map((subtypeRow) =>
                  subtypeRow.subtype === selectedTreeNode.path.subtipo ? { ...subtypeRow, subtype: value } : subtypeRow
                )
              }
        )
      );
      setSelectedSubtipo(value);
      return;
    }

    if (selectedTreeNode.level === "areaFoto" && selectedTreeNode.path.areaFoto) {
      const index = areaFotoItems.findIndex((item) => item === selectedTreeNode.path.areaFoto);
      if (index >= 0) {
        updateSimpleCsvList(step1ContextosCsv, setStep1ContextosCsv, index, value, getInactiveKey("areaFoto"));
      }
      setSelectedAreaFoto(value);
      return;
    }

    const branchProperty =
      selectedTreeNode.level === "ambiente"
        ? "ambientesCsv"
        : selectedTreeNode.level === "elemento"
          ? "elementosCsv"
          : selectedTreeNode.level === "material"
            ? "materiaisCsv"
            : selectedTreeNode.level === "estado"
              ? "estadosCsv"
              : null;

    if (
      branchProperty &&
      selectedTreeNode.path.tipoImovel &&
      selectedTreeNode.path.subtipo &&
      selectedTreeNode.path.areaFoto
    ) {
      const currentItems =
        branchProperty === "ambientesCsv"
          ? ambienteItems
          : branchProperty === "elementosCsv"
            ? elementoItems
            : branchProperty === "materiaisCsv"
              ? materialItems
              : estadoItems;
      const target =
        selectedTreeNode.level === "ambiente"
          ? selectedTreeNode.path.ambiente
          : selectedTreeNode.level === "elemento"
            ? selectedTreeNode.path.elemento
            : selectedTreeNode.level === "material"
              ? selectedTreeNode.path.material
              : selectedTreeNode.path.estado;
      const index = currentItems.findIndex((item) => item === target);
      if (index >= 0) {
        updateCameraBranchCsv(
          selectedTreeNode.path.tipoImovel,
          selectedTreeNode.path.subtipo,
          selectedTreeNode.path.areaFoto,
          branchProperty,
          (currentValue) => {
            const items = splitCsv(currentValue);
            items[index] = value;
            return joinCsv(items);
          }
        );
      }
    }
  };

  const addChildForSelectedNode = () => {
    if (!selectedTreeNode) {
      return;
    }
    if (selectedTreeNode.level === "tipoImovel" && selectedTreeNode.path.tipoImovel) {
      addSubtypeItem(selectedTreeNode.path.tipoImovel);
      return;
    }
    if (selectedTreeNode.level === "subtipo") {
      setStep1ContextosCsv(joinCsv([...areaFotoItems, "Novo contexto"]));
      return;
    }
    if (
      selectedTreeNode.level === "areaFoto" &&
      selectedTreeNode.path.tipoImovel &&
      selectedTreeNode.path.subtipo &&
      selectedTreeNode.path.areaFoto
    ) {
      addCameraLevelOption(selectedTreeNode.path.tipoImovel, selectedTreeNode.path.subtipo, selectedTreeNode.path.areaFoto, "ambiente");
      return;
    }
    if (
      selectedTreeNode.level === "ambiente" &&
      selectedTreeNode.path.tipoImovel &&
      selectedTreeNode.path.subtipo &&
      selectedTreeNode.path.areaFoto
    ) {
      addCameraLevelOption(selectedTreeNode.path.tipoImovel, selectedTreeNode.path.subtipo, selectedTreeNode.path.areaFoto, "elemento");
      return;
    }
    if (
      selectedTreeNode.level === "elemento" &&
      selectedTreeNode.path.tipoImovel &&
      selectedTreeNode.path.subtipo &&
      selectedTreeNode.path.areaFoto
    ) {
      addCameraLevelOption(selectedTreeNode.path.tipoImovel, selectedTreeNode.path.subtipo, selectedTreeNode.path.areaFoto, "material");
      return;
    }
  };

  const removeSelectedTreeNode = () => {
    if (!selectedTreeNode) {
      return;
    }
    if (selectedTreeNode.level === "tipoImovel" && selectedTreeNode.path.tipoImovel) {
      removeTipoItem(selectedTreeNode.path.tipoImovel);
      return;
    }
    if (selectedTreeNode.level === "subtipo" && selectedTreeNode.path.tipoImovel && selectedTreeNode.path.subtipo) {
      const index = currentSubtipoItems.findIndex((item) => item === selectedTreeNode.path.subtipo);
      if (index >= 0) {
        removeSubtypeItem(selectedTreeNode.path.tipoImovel, index);
      }
      setCameraTypeDrafts((current) =>
        current.map((row) =>
          normalizeKey(row.propertyType) !== normalizeKey(selectedTreeNode.path.tipoImovel ?? "")
            ? row
            : {
                ...row,
                subtypes: row.subtypes.filter((subtypeRow) => subtypeRow.subtype !== selectedTreeNode.path.subtipo)
              }
        )
      );
      return;
    }
    if (selectedTreeNode.level === "areaFoto" && selectedTreeNode.path.areaFoto) {
      const index = areaFotoItems.findIndex((item) => item === selectedTreeNode.path.areaFoto);
      if (index >= 0) {
        removeSimpleCsvItem(step1ContextosCsv, setStep1ContextosCsv, index, getInactiveKey("areaFoto"));
      }
      return;
    }
    const branchProperty =
      selectedTreeNode.level === "ambiente"
        ? "ambientesCsv"
        : selectedTreeNode.level === "elemento"
          ? "elementosCsv"
          : selectedTreeNode.level === "material"
            ? "materiaisCsv"
            : selectedTreeNode.level === "estado"
              ? "estadosCsv"
              : null;
    const target =
      selectedTreeNode.level === "ambiente"
        ? selectedTreeNode.path.ambiente
        : selectedTreeNode.level === "elemento"
          ? selectedTreeNode.path.elemento
          : selectedTreeNode.level === "material"
            ? selectedTreeNode.path.material
            : selectedTreeNode.level === "estado"
              ? selectedTreeNode.path.estado
              : null;

    if (branchProperty && target && selectedTreeNode.path.tipoImovel && selectedTreeNode.path.subtipo && selectedTreeNode.path.areaFoto) {
      updateCameraBranchCsv(
        selectedTreeNode.path.tipoImovel,
        selectedTreeNode.path.subtipo,
        selectedTreeNode.path.areaFoto,
        branchProperty,
        (currentValue) => joinCsv(splitCsv(currentValue).filter((item) => item !== target))
      );
    }
  };

  const selectedOperationalConfig = selectedTreeNode?.path.tipoImovel
    ? step2TypeDrafts.find((item) => normalizeKey(item.propertyType) === normalizeKey(selectedTreeNode.path.tipoImovel ?? ""))
    : null;
  const selectedContextLevel = step1LevelDrafts.find((level) => normalizeKey(level.id) === "contexto") ?? null;
  const currentSubtypeDraft =
    step1SubtypeDrafts.find((row) => normalizeKey(row.tipo) === normalizeKey(currentTipoImovel)) ?? null;
  const hasStep2Enabled = step2TypeDrafts.some((row) => row.visivel);

  const updateStep1UiDraft = (patch: Partial<Step1UiDraft>) => {
    setStep1UiDraft((current) => ({ ...current, ...patch }));
  };

  const toggleTreeNodeExpanded = (nodeId: string) => {
    setExpandedTreeNodeIds((current) =>
      current.includes(nodeId) ? current.filter((id) => id !== nodeId) : [...current, nodeId]
    );
  };

  const renderTree = (nodes: CanonicalTreeNode[], depth = 0): React.ReactNode => (
    <ul className={`canonical-tree depth-${depth}`}>
      {nodes.map((node) => (
        <li key={node.id}>
          <div className={`canonical-tree-node${selectedTreeNode?.id === node.id ? " is-selected" : ""}`}>
            {node.children && node.children.length > 0 ? (
              <button
                type="button"
                className="canonical-tree-toggle"
                onClick={() => toggleTreeNodeExpanded(node.id)}
              >
                {expandedTreeNodeIds.includes(node.id) ? "-" : "+"}
              </button>
            ) : (
              <span className="canonical-tree-toggle canonical-tree-toggle-placeholder" />
            )}
            <button
              type="button"
              className="canonical-tree-node-main"
              onClick={() => handleTreeSelection(node)}
            >
              <span className="canonical-tree-node-label">{node.label}</span>
              <span className="canonical-tree-node-level">{node.level}</span>
            </button>
          </div>
          {node.children && node.children.length > 0 && expandedTreeNodeIds.includes(node.id)
            ? renderTree(node.children, depth + 1)
            : null}
        </li>
      ))}
    </ul>
  );

  return (
    <section className="targeting-panel" aria-live="polite">
      <div className="targeting-header">
        <h2>{t(uiLanguage, "multiScopeResolution")}</h2>
        <p>{t(uiLanguage, "precedenceSimulation")}</p>
      </div>

      <div className="multi-scope-grid">
        <label className="multi-scope-card">
          <span className="multi-scope-label">{t(uiLanguage, "operationalProfile")}</span>
          <select value={actorRole} onChange={(event) => setActorRole(event.target.value as ActorRole)}>
            <option value="viewer">viewer</option>
            <option value="operator">operator</option>
            <option value="tenant_admin">tenant_admin</option>
            <option value="support">support</option>
          </select>
        </label>
        <label className="multi-scope-card">
          <span className="multi-scope-label">Tenant</span>
          <input value={tenantId} onChange={(event) => setTenantId(event.target.value)} />
        </label>
        <label className="multi-scope-card">
          <span className="multi-scope-label">Role</span>
          <input value={roleId} onChange={(event) => setRoleId(event.target.value)} />
        </label>
        <label className="multi-scope-card">
          <span className="multi-scope-label">{t(uiLanguage, "user")}</span>
          <input value={userId} onChange={(event) => setUserId(event.target.value)} />
        </label>
        <label className="multi-scope-card">
          <span className="multi-scope-label">{t(uiLanguage, "device")}</span>
          <input value={deviceId} onChange={(event) => setDeviceId(event.target.value)} />
        </label>
      </div>

      <div className="publish-box">
        <h3>{t(uiLanguage, "publishConfigPackage")}</h3>
        <div className="publish-layout-grid">
          <label className="publish-card">
            <span className="multi-scope-label">{t(uiLanguage, "scope")}</span>
            <select value={publishScope} onChange={(event) => setPublishScope(event.target.value as "tenant" | "role" | "user" | "device")}>
              <option value="tenant">tenant</option>
              <option value="role">role</option>
              <option value="user">user</option>
              <option value="device">device</option>
            </select>
          </label>
          <label className="publish-card">
            <span className="multi-scope-label">{t(uiLanguage, "updateChannel")}</span>
            <select
              value={publishChannel}
              onChange={(event) =>
                setPublishChannel(event.target.value as "stable" | "pilot" | "hotfix")
              }
            >
              <option value="stable">stable</option>
              <option value="pilot">pilot</option>
              <option value="hotfix">hotfix</option>
            </select>
          </label>
          <label className="publish-card">
            <span className="multi-scope-label">{t(uiLanguage, "activation")}</span>
            <select
              value={publishActivation}
              onChange={(event) =>
                setPublishActivation(event.target.value as "immediate" | "scheduled")
              }
            >
              <option value="immediate">immediate</option>
              <option value="scheduled">scheduled</option>
            </select>
          </label>
          <label className="publish-card">
            <span className="multi-scope-label">{t(uiLanguage, "start")}</span>
            <input
              type="datetime-local"
              value={publishStartsAt}
              onChange={(event) => setPublishStartsAt(event.target.value)}
            />
          </label>
          <label className="publish-card">
            <span className="multi-scope-label">{t(uiLanguage, "end")}</span>
            <input
              type="datetime-local"
              value={publishEndsAt}
              onChange={(event) => setPublishEndsAt(event.target.value)}
            />
          </label>
          <label className="publish-card publish-card-span">
            <span className="multi-scope-label">{t(uiLanguage, "batchUsers")}</span>
            <input
              placeholder="user-42,user-77"
              value={publishBatchUsers}
              onChange={(event) => setPublishBatchUsers(event.target.value)}
            />
          </label>
          <label className="publish-card publish-card-inline">
            <input
              type="checkbox"
              checked={publishVoice}
              onChange={(event) => setPublishVoice(event.target.checked)}
            />
            <span>{t(uiLanguage, "enableVoiceCommands")}</span>
          </label>
        </div>
        <div className="targeting-trace">
          <h4>{t(uiLanguage, "canonicalInspectionTree")}</h4>
          <p className="targeting-note">
            {t(uiLanguage, "canonicalTreeDescription")}
          </p>
          <div className="canonical-context-panel">
            <div className="canonical-context-head">
              <h5>{t(uiLanguage, "photoArea")}</h5>
              <div className="canonical-context-actions">
                <button
                  type="button"
                  className="inline-action"
                  onClick={() => setStep1ContextosCsv(joinCsv([...splitCsv(step1ContextosCsv), "Novo contexto"]))}
                >
                  + Item
                </button>
                <button
                  type="button"
                  className="inline-action"
                  onClick={() => {
                    const index = areaFotoItems.findIndex((item) => item === currentAreaFoto);
                    if (index >= 0) {
                      removeSimpleCsvItem(step1ContextosCsv, setStep1ContextosCsv, index, getInactiveKey("areaFoto"));
                    }
                  }}
                >
                  - Item
                </button>
              </div>
            </div>
            <div className="canonical-filter-group">
              <label>
                <input
                  type="radio"
                  name="area-filter"
                  checked={selectedAreaFilter === "all"}
                  onChange={() => setSelectedAreaFilter("all")}
                />
                {t(uiLanguage, "showAll")}
              </label>
              {areaFotoItems.map((item) => (
                <label key={`filter-${item}`}>
                  <input
                    type="radio"
                    name="area-filter"
                    checked={selectedAreaFilter === item}
                    onChange={() => setSelectedAreaFilter(item)}
                  />
                  {item}
                </label>
              ))}
            </div>
            <div className="canonical-context-list">
              {areaFotoItems.map((item, index) => {
                const active = !(inactiveCanonicalItems[getInactiveKey("areaFoto")] ?? []).includes(item);
                return (
                  <div key={`area-foto-${index}`} className={`canonical-context-row${item === currentAreaFoto ? " is-selected" : ""}`}>
                    <label className="canonical-toggle">
                      <input
                        type="checkbox"
                        checked={active}
                        onChange={(event) => toggleCanonicalItem(getInactiveKey("areaFoto"), item, event.target.checked)}
                      />
                    </label>
                    <input
                      value={item}
                      onClick={() => setSelectedAreaFoto(item)}
                      onFocus={() => setSelectedAreaFoto(item)}
                      onChange={(event) =>
                        updateSimpleCsvList(step1ContextosCsv, setStep1ContextosCsv, index, event.target.value, getInactiveKey("areaFoto"))
                      }
                    />
                    <button
                      type="button"
                      className="inline-action"
                      onClick={() => removeSimpleCsvItem(step1ContextosCsv, setStep1ContextosCsv, index, getInactiveKey("areaFoto"))}
                    >
                      - Item
                    </button>
                  </div>
                );
              })}
            </div>
          </div>
          <p className="canonical-path">
            {t(uiLanguage, "currentContext")}: <strong>{currentAreaFoto || "-"}</strong>
          </p>
          <p className="canonical-path">
            {t(uiLanguage, "currentTree")}: <strong>{[currentTipoImovel, currentSubtipo, currentAmbiente, currentElemento, currentMaterial, currentEstado].filter(Boolean).join(" / ") || "-"}</strong>
          </p>
          <div className="canonical-explorer">
            <article className="canonical-tree-panel">
              <div className="canonical-tree-head">
                <h5>{t(uiLanguage, "fullTree")}</h5>
                <p>{t(uiLanguage, "fullTreeDescription")}</p>
              </div>
              <div className="canonical-node-actions">
                <button
                  type="button"
                  className="inline-action"
                  onClick={() => setExpandedTreeNodeIds(collectExpandableNodeIds(canonicalTree))}
                >
                  Expand all
                </button>
                <button
                  type="button"
                  className="inline-action"
                  onClick={() => setExpandedTreeNodeIds([])}
                >
                  Collapse all
                </button>
              </div>
              {renderTree(filteredCanonicalTree)}
            </article>
            <article className="canonical-detail-panel">
              <div className="canonical-tree-head">
                <h5>{t(uiLanguage, "selectedItemProperties")}</h5>
                <p>{t(uiLanguage, "selectedItemDescription")}</p>
              </div>
              {selectedTreeNode ? (
                <>
                  <div className="canonical-node-actions">
                    <button type="button" className="inline-action" onClick={addChildForSelectedNode}>
                      + Item
                    </button>
                    <button type="button" className="inline-action" onClick={removeSelectedTreeNode}>
                      - Item
                    </button>
                  </div>
                  <label className="canonical-property-field">
                    {t(uiLanguage, "label")}
                    <input
                      value={selectedNodeLabelDraft}
                      onChange={(event) => setSelectedNodeLabelDraft(event.target.value)}
                    />
                  </label>
                  <div className="canonical-node-actions">
                    <button type="button" className="inline-action" onClick={() => renameSelectedTreeNode(selectedNodeLabelDraft)}>
                      {t(uiLanguage, "saveLabel")}
                    </button>
                  </div>
                  <dl className="canonical-detail-list">
                    <dt>{t(uiLanguage, "level")}</dt>
                    <dd>{selectedTreeNode.level}</dd>
                    <dt>{t(uiLanguage, "path")}</dt>
                    <dd>
                      {Object.values(selectedTreeNode.path).filter(Boolean).join(" / ")}
                    </dd>
                  </dl>
                  <div className="canonical-property-grid">
                    <label className="check-label">
                      <input
                        type="checkbox"
                        checked={selectedOperationalConfig?.visivel ?? true}
                        onChange={(event) => updateSelectedTypeOperationalConfig({ visivel: event.target.checked })}
                      />
                      {t(uiLanguage, "visible")}
                    </label>
                    <label className="check-label">
                      <input
                        type="checkbox"
                        checked={selectedOperationalConfig?.obrigatoria ?? false}
                        onChange={(event) => updateSelectedTypeOperationalConfig({ obrigatoria: event.target.checked })}
                      />
                      {t(uiLanguage, "required")}
                    </label>
                    <label>
                      {t(uiLanguage, "minPhotos")}
                      <input
                        value={selectedOperationalConfig?.minFotos ?? "0"}
                        onChange={(event) => updateSelectedTypeOperationalConfig({ minFotos: event.target.value })}
                      />
                    </label>
                    <label>
                      {t(uiLanguage, "maxPhotos")}
                      <input
                        value={selectedOperationalConfig?.maxFotos ?? ""}
                        onChange={(event) => updateSelectedTypeOperationalConfig({ maxFotos: event.target.value })}
                      />
                    </label>
                  </div>
                </>
              ) : (
                <p className="canonical-empty">{t(uiLanguage, "noSelectedItem")}</p>
              )}
            </article>
          </div>
        </div>
        <div className="targeting-trace">
          <h4>{t(uiLanguage, "checkInStep1")}</h4>
          <p className="targeting-note">
            {t(uiLanguage, "checkInStep1Description")}
          </p>
          <div className="step1-layout-grid">
            <article className="step1-layout-card">
              <h5>{t(uiLanguage, "initialInspectionData")}</h5>
              <div className="step1-config-row">
                <strong>{t(uiLanguage, "objectAndClientSection")}</strong>
                <div className="step1-config-controls">
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.dadosObjetoClienteVisible}
                      onChange={(event) => updateStep1UiDraft({ dadosObjetoClienteVisible: event.target.checked })}
                    />
                    {t(uiLanguage, "visible")}
                  </label>
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.dadosObjetoClienteRequired}
                      onChange={(event) => updateStep1UiDraft({ dadosObjetoClienteRequired: event.target.checked })}
                    />
                    {t(uiLanguage, "required")}
                  </label>
                </div>
              </div>
              <div className="step1-config-row">
                <strong>{t(uiLanguage, "gpsConfirmation")}</strong>
                <div className="step1-config-controls">
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.gpsVisible}
                      onChange={(event) => updateStep1UiDraft({ gpsVisible: event.target.checked })}
                    />
                    {t(uiLanguage, "visible")}
                  </label>
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.gpsRequired}
                      onChange={(event) => updateStep1UiDraft({ gpsRequired: event.target.checked })}
                    />
                    {t(uiLanguage, "required")}
                  </label>
                </div>
              </div>
              <div className="step1-config-row">
                <strong>{t(uiLanguage, "whatsappButton")}</strong>
                <div className="step1-config-controls">
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.whatsappVisible}
                      onChange={(event) => updateStep1UiDraft({ whatsappVisible: event.target.checked })}
                    />
                    {t(uiLanguage, "visible")}
                  </label>
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.whatsappRequired}
                      onChange={(event) => updateStep1UiDraft({ whatsappRequired: event.target.checked })}
                    />
                    {t(uiLanguage, "required")}
                  </label>
                </div>
              </div>
              <div className="step1-config-row">
                <strong>{t(uiLanguage, "callButton")}</strong>
                <div className="step1-config-controls">
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.ligarVisible}
                      onChange={(event) => updateStep1UiDraft({ ligarVisible: event.target.checked })}
                    />
                    {t(uiLanguage, "visible")}
                  </label>
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.ligarRequired}
                      onChange={(event) => updateStep1UiDraft({ ligarRequired: event.target.checked })}
                    />
                    {t(uiLanguage, "required")}
                  </label>
                </div>
              </div>
            </article>
            <article className="step1-layout-card">
              <h5>{t(uiLanguage, "checkInStep1Stage")}</h5>
              <div className="step1-config-row">
                <div className="step1-config-copy">
                  <strong>{t(uiLanguage, "customerPresent")}</strong>
                  <input
                    value={step1UiDraft.clientePresenteLabel}
                    onChange={(event) => updateStep1UiDraft({ clientePresenteLabel: event.target.value })}
                  />
                </div>
                <div className="step1-config-controls">
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.clientePresenteVisible}
                      onChange={(event) => updateStep1UiDraft({ clientePresenteVisible: event.target.checked })}
                    />
                    {t(uiLanguage, "visible")}
                  </label>
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.clientePresenteRequired}
                      onChange={(event) => updateStep1UiDraft({ clientePresenteRequired: event.target.checked })}
                    />
                    {t(uiLanguage, "required")}
                  </label>
                </div>
              </div>
              <div className="step1-config-row">
                <div className="step1-config-copy">
                    <strong>Menu Type</strong>
                  <input
                    value={step1UiDraft.menuTipoLabel}
                    onChange={(event) => updateStep1UiDraft({ menuTipoLabel: event.target.value })}
                  />
                  <small>Catalogo canonico atual: {step1TiposCsv || "-"}</small>
                </div>
                <div className="step1-config-controls">
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.menuTipoVisible}
                      onChange={(event) => updateStep1UiDraft({ menuTipoVisible: event.target.checked })}
                    />
                    {t(uiLanguage, "visible")}
                  </label>
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.menuTipoRequired}
                      onChange={(event) => updateStep1UiDraft({ menuTipoRequired: event.target.checked })}
                    />
                    {t(uiLanguage, "required")}
                  </label>
                </div>
              </div>
              <div className="step1-config-row">
                <div className="step1-config-copy">
                    <strong>Menu Subtype</strong>
                  <input
                    value={step1UiDraft.menuSubtipoLabel}
                    onChange={(event) => updateStep1UiDraft({ menuSubtipoLabel: event.target.value })}
                  />
                  <small>Catalogo do tipo atual: {currentSubtypeDraft?.subtiposCsv || "-"}</small>
                </div>
                <div className="step1-config-controls">
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.menuSubtipoVisible}
                      onChange={(event) => updateStep1UiDraft({ menuSubtipoVisible: event.target.checked })}
                    />
                    {t(uiLanguage, "visible")}
                  </label>
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.menuSubtipoRequired}
                      onChange={(event) => updateStep1UiDraft({ menuSubtipoRequired: event.target.checked })}
                    />
                    {t(uiLanguage, "required")}
                  </label>
                </div>
              </div>
              <div className="step1-config-row">
                <div className="step1-config-copy">
                    <strong>Entry Point Menu</strong>
                  <input
                    value={step1UiDraft.menuContextoLabel}
                    onChange={(event) => {
                      updateStep1UiDraft({ menuContextoLabel: event.target.value });
                      if (selectedContextLevel) {
                        updateStep1LevelDraft(
                          step1LevelDrafts.findIndex((level) => level === selectedContextLevel),
                          { label: event.target.value }
                        );
                      }
                    }}
                  />
                  <small>Contextos ativos: {step1ContextosCsv || "-"}</small>
                </div>
                <div className="step1-config-controls">
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.menuContextoVisible}
                      onChange={(event) => updateStep1UiDraft({ menuContextoVisible: event.target.checked })}
                    />
                    {t(uiLanguage, "visible")}
                  </label>
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.menuContextoRequired}
                      onChange={(event) => {
                        updateStep1UiDraft({ menuContextoRequired: event.target.checked });
                        if (selectedContextLevel) {
                          updateStep1LevelDraft(
                            step1LevelDrafts.findIndex((level) => level === selectedContextLevel),
                            { required: event.target.checked }
                          );
                        }
                      }}
                    />
                    {t(uiLanguage, "required")}
                  </label>
                </div>
              </div>
              <div className="step1-config-row">
                <div className="step1-config-copy">
                  <strong>Check-in step 2 button</strong>
                  <input
                    value={step1UiDraft.botaoEtapa2Label}
                    onChange={(event) => updateStep1UiDraft({ botaoEtapa2Label: event.target.value })}
                  />
                  <small>{hasStep2Enabled ? "Aparece quando a etapa 2 estiver habilitada." : "Hoje a etapa 2 nao esta visivel para nenhum tipo."}</small>
                </div>
                <div className="step1-config-controls">
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.botaoEtapa2Visible}
                      onChange={(event) => updateStep1UiDraft({ botaoEtapa2Visible: event.target.checked })}
                    />
                    {t(uiLanguage, "visible")}
                  </label>
                </div>
              </div>
              <div className="step1-config-row">
                <div className="step1-config-copy">
                  <strong>{t(uiLanguage, "confirmAndOpenCameraButton")}</strong>
                  <input
                    value={step1UiDraft.botaoConfirmarCameraLabel}
                    onChange={(event) => updateStep1UiDraft({ botaoConfirmarCameraLabel: event.target.value })}
                  />
                  <small>Esse botao habilita quando todos os obrigatorios da etapa 1 estiverem preenchidos.</small>
                </div>
                <div className="step1-config-controls">
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.botaoConfirmarCameraVisible}
                      onChange={(event) => updateStep1UiDraft({ botaoConfirmarCameraVisible: event.target.checked })}
                    />
                    {t(uiLanguage, "visible")}
                  </label>
                  <label className="check-label">
                    <input
                      type="checkbox"
                      checked={step1UiDraft.botaoConfirmarCameraRequired}
                      onChange={(event) => updateStep1UiDraft({ botaoConfirmarCameraRequired: event.target.checked })}
                    />
                    {t(uiLanguage, "required")}
                  </label>
                </div>
              </div>
            </article>
          </div>
        </div>

        <div className="targeting-trace">
          <h4>{t(uiLanguage, "checkInStep2")}</h4>
          <p className="targeting-note">
            {t(uiLanguage, "checkInStep2Description")}
          </p>
          <div className="step2-layout-grid">
            {step2TypeDrafts.map((typeRow, typeIndex) => (
              <article key={`step2-type-${typeIndex}`} className="step1-layout-card step2-app-card">
                <h5>{typeRow.propertyType || `Tipo ${typeIndex + 1}`}</h5>
                <div className="step1-config-row">
                  <div className="step1-config-copy">
                    <strong>{t(uiLanguage, "step2Inspection")}</strong>
                    <input
                      value={typeRow.screenLabel}
                      onChange={(event) => updateStep2TypeDraft(typeIndex, { screenLabel: event.target.value })}
                      placeholder="Label da tela"
                    />
                    <input
                      value={typeRow.subtitleLabel}
                      onChange={(event) => updateStep2TypeDraft(typeIndex, { subtitleLabel: event.target.value })}
                      placeholder="Label da pre-vistoria"
                    />
                  </div>
                  <div className="step1-config-controls">
                    <label className="check-label">
                      <input
                        type="checkbox"
                        checked={typeRow.visivel}
                        onChange={(event) => updateStep2TypeDraft(typeIndex, { visivel: event.target.checked })}
                      />
                      {t(uiLanguage, "visible")}
                    </label>
                    <label className="check-label">
                      <input
                        type="checkbox"
                        checked={typeRow.obrigatoria}
                        onChange={(event) => updateStep2TypeDraft(typeIndex, { obrigatoria: event.target.checked })}
                      />
                      {t(uiLanguage, "required")}
                    </label>
                  </div>
                </div>
                <div className="step1-config-row">
                  <div className="step1-config-copy">
                    <strong>{t(uiLanguage, "canonicalType")}</strong>
                    <input
                      value={typeRow.propertyType}
                      onChange={(event) => updateStep2TypeDraft(typeIndex, { propertyType: event.target.value })}
                      placeholder="Tipo canonico"
                    />
                  </div>
                  <div className="step1-config-controls">
                    <label className="check-label">
                      <input
                        type="checkbox"
                        checked={!typeRow.bloqueiaCaptura}
                        onChange={(event) => updateStep2TypeDraft(typeIndex, { bloqueiaCaptura: !event.target.checked })}
                      />
                      {t(uiLanguage, "allowsCapture")}
                    </label>
                  </div>
                </div>
                <div className="step1-config-row">
                  <div className="step1-config-copy">
                    <strong>{t(uiLanguage, "photoRecord")}</strong>
                    <input
                      value={typeRow.photoSectionLabel}
                      onChange={(event) => updateStep2TypeDraft(typeIndex, { photoSectionLabel: event.target.value })}
                      placeholder="Label do agrupamento"
                    />
                    <small>{t(uiLanguage, "photoRecordDescription")}</small>
                  </div>
                  <div className="step1-config-controls">
                    <label className="check-label">
                      <input
                        type="checkbox"
                        checked={typeRow.photoSectionVisible}
                        onChange={(event) => updateStep2TypeDraft(typeIndex, { photoSectionVisible: event.target.checked })}
                      />
                      {t(uiLanguage, "visible")}
                    </label>
                    <label className="check-label">
                      <input
                        type="checkbox"
                        checked={typeRow.photoSectionRequired}
                        onChange={(event) => updateStep2TypeDraft(typeIndex, { photoSectionRequired: event.target.checked })}
                      />
                      {t(uiLanguage, "required")}
                    </label>
                    <label>
                      {t(uiLanguage, "minPhotos")}
                      <input
                        value={typeRow.minFotos}
                        onChange={(event) => updateStep2TypeDraft(typeIndex, { minFotos: event.target.value })}
                      />
                    </label>
                    <label>
                      {t(uiLanguage, "maxPhotos")}
                      <input
                        value={typeRow.maxFotos}
                        onChange={(event) => updateStep2TypeDraft(typeIndex, { maxFotos: event.target.value })}
                      />
                    </label>
                  </div>
                </div>
                {typeRow.photoFields.map((field, fieldIndex) => (
                  <div key={`step2-photo-${typeIndex}-${fieldIndex}`} className="step1-config-row step2-domain-row">
                    <div className="step1-config-copy">
                      <strong>{field.titulo || `Registro ${fieldIndex + 1}`}</strong>
                      <input
                        value={field.titulo}
                        onChange={(event) => updateStep2PhotoField(typeIndex, fieldIndex, { titulo: event.target.value })}
                        placeholder="Label exibida no app"
                      />
                      <small>
                        {field.cameraMacroLocal || "-"} / {field.cameraAmbiente || "-"} / {field.cameraElementoInicial || "-"}
                      </small>
                    </div>
                    <div className="step1-config-controls">
                      <label className="check-label">
                        <input
                          type="checkbox"
                          checked={field.obrigatorio}
                          onChange={(event) => updateStep2PhotoField(typeIndex, fieldIndex, { obrigatorio: event.target.checked })}
                        />
                        {t(uiLanguage, "required")}
                      </label>
                      <button
                        type="button"
                        className="inline-action"
                        onClick={() => removeStep2PhotoField(typeIndex, fieldIndex)}
                      >
                        Remover
                      </button>
                    </div>
                  </div>
                ))}
                <div className="step1-config-row">
                  <div className="step1-config-copy">
                    <strong>{t(uiLanguage, "infrastructureServices")}</strong>
                    <input
                      value={typeRow.optionSectionLabel}
                      onChange={(event) => updateStep2TypeDraft(typeIndex, { optionSectionLabel: event.target.value })}
                      placeholder="Label do agrupamento"
                    />
                    <small>{t(uiLanguage, "infrastructureServicesDescription")}</small>
                  </div>
                  <div className="step1-config-controls">
                    <label className="check-label">
                      <input
                        type="checkbox"
                        checked={typeRow.optionSectionVisible}
                        onChange={(event) => updateStep2TypeDraft(typeIndex, { optionSectionVisible: event.target.checked })}
                      />
                      {t(uiLanguage, "visible")}
                    </label>
                    <label className="check-label">
                      <input
                        type="checkbox"
                        checked={typeRow.optionSectionRequired}
                        onChange={(event) => updateStep2TypeDraft(typeIndex, { optionSectionRequired: event.target.checked })}
                      />
                      {t(uiLanguage, "required")}
                    </label>
                    <button
                      type="button"
                      className="inline-action"
                      onClick={() =>
                        setStep2TypeDrafts((current) =>
                          current.map((typeItem, currentTypeIndex) =>
                            currentTypeIndex === typeIndex
                              ? {
                                  ...typeItem,
                                  optionGroups: [
                                    ...typeItem.optionGroups,
                                  {
                                    id: "",
                                    titulo: "",
                                    visivel: true,
                                    obrigatorio: false,
                                    multiplaEscolha: true,
                                    permiteObservacao: false,
                                    opcoes: []
                                    }
                                  ]
                                }
                              : typeItem
                          )
                        )
                      }
                    >
                      {t(uiLanguage, "addGroup")}
                    </button>
                    <button type="button" className="inline-action" onClick={() => removeStep2TypeDraft(typeIndex)}>
                      {t(uiLanguage, "removeType")}
                    </button>
                  </div>
                </div>
                {typeRow.optionGroups.map((group, groupIndex) => (
                  <div key={`step2-group-${typeIndex}-${groupIndex}`} className="step1-config-row step2-domain-row">
                    <div className="step1-config-copy">
                      <strong>{group.titulo || `Nivel ${groupIndex + 1}`}</strong>
                      <input
                        value={group.titulo}
                        onChange={(event) => updateStep2OptionGroup(typeIndex, groupIndex, { titulo: event.target.value })}
                        placeholder="Label do nivel"
                      />
                      <small>Dominios do nivel</small>
                      <div className="domain-chip-list">
                        {group.opcoes.length === 0 && <span className="domain-chip is-empty">Sem dominios configurados.</span>}
                        {group.opcoes.map((option, optionIndex) => (
                          <div key={`step2-domain-${typeIndex}-${groupIndex}-${optionIndex}`} className="domain-chip">
                            <input
                              value={option.label}
                              onChange={(event) =>
                                updateStep2Option(typeIndex, groupIndex, optionIndex, {
                                  label: event.target.value,
                                  id: normalizeKey(event.target.value).replace(/\s+/g, "-")
                                })
                              }
                              placeholder={`Dominio ${optionIndex + 1}`}
                            />
                            <button
                              type="button"
                              className="inline-action"
                              onClick={() => removeStep2Option(typeIndex, groupIndex, optionIndex)}
                            >
                              -
                            </button>
                          </div>
                        ))}
                      </div>
                    </div>
                    <div className="step1-config-controls">
                      <label className="check-label">
                        <input
                          type="checkbox"
                          checked={group.visivel}
                          onChange={(event) => updateStep2OptionGroup(typeIndex, groupIndex, { visivel: event.target.checked })}
                        />
                        {t(uiLanguage, "visible")}
                      </label>
                      <label className="check-label">
                        <input
                          type="checkbox"
                          checked={group.obrigatorio}
                          onChange={(event) => updateStep2OptionGroup(typeIndex, groupIndex, { obrigatorio: event.target.checked })}
                        />
                        {t(uiLanguage, "required")}
                      </label>
                      <label className="check-label">
                        <input
                          type="checkbox"
                          checked={group.multiplaEscolha}
                          onChange={(event) => updateStep2OptionGroup(typeIndex, groupIndex, { multiplaEscolha: event.target.checked })}
                        />
                        Multipla escolha
                      </label>
                      <label className="check-label">
                        <input
                          type="checkbox"
                          checked={group.permiteObservacao}
                          onChange={(event) => updateStep2OptionGroup(typeIndex, groupIndex, { permiteObservacao: event.target.checked })}
                        />
                        Observacao
                      </label>
                      <button
                        type="button"
                        className="inline-action"
                        onClick={() => removeStep2OptionGroup(typeIndex, groupIndex)}
                      >
                        Remover
                      </button>
                      <button
                        type="button"
                        className="inline-action"
                        onClick={() =>
                          setStep2TypeDrafts((current) =>
                            current.map((typeItem, currentTypeIndex) =>
                              currentTypeIndex === typeIndex
                                ? {
                                    ...typeItem,
                                    optionGroups: typeItem.optionGroups.map((item, currentGroupIndex) =>
                                      currentGroupIndex === groupIndex
                                        ? {
                                            ...item,
                                            opcoes: [
                                              ...item.opcoes,
                                              {
                                                id: `dominio-${item.opcoes.length + 1}`,
                                                label: `Dominio ${item.opcoes.length + 1}`
                                              }
                                            ]
                                          }
                                        : item
                                    )
                                  }
                                : typeItem
                            )
                          )
                        }
                      >
                        + Dominio
                      </button>
                    </div>
                  </div>
                ))}
                <div className="step1-config-row">
                  <div className="step1-config-copy">
                    <strong>{t(uiLanguage, "confirmAndOpenCameraButton")}</strong>
                    <input
                      value={typeRow.confirmButtonLabel}
                      onChange={(event) => updateStep2TypeDraft(typeIndex, { confirmButtonLabel: event.target.value })}
                      placeholder="Label do botao"
                    />
                  </div>
                  <div className="step1-config-controls">
                    <label className="check-label">
                      <input
                        type="checkbox"
                        checked={!typeRow.bloqueiaCaptura}
                        onChange={(event) => updateStep2TypeDraft(typeIndex, { bloqueiaCaptura: !event.target.checked })}
                      />
                      {t(uiLanguage, "enableCamera")}
                    </label>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </div>
        <button type="button" onClick={publishPackage} disabled={publishing}>
          {publishing ? t(uiLanguage, "publishing") : t(uiLanguage, "publishForApproval")}
        </button>
      </div>

      <div className="targeting-trace">
        <h3>{t(uiLanguage, "packageCatalog")}</h3>
        <ul>
          {packages.map((pkg) => (
            <li key={pkg.id}>
              <strong>{pkg.id}</strong> ({pkg.scope})
              <span className={`pkg-status state-${pkg.status ?? "active"}`}>
                {pkg.status ?? "active"}
              </span>
              {pkg.status === "pending_approval" && (
                <button
                  type="button"
                  className="inline-action inline-approve"
                  onClick={() => approvePackage(pkg.id)}
                  disabled={approvingId === pkg.id}
                >
                  {approvingId === pkg.id ? "Aprovando..." : "Aprovar"}
                </button>
              )}
              {pkg.status !== "rolled_back" && (
                <button
                  type="button"
                  className="inline-action"
                  onClick={() => rollbackPackage(pkg.id)}
                  disabled={rollingBackId === pkg.id}
                >
                  {rollingBackId === pkg.id ? "Revertendo..." : "Rollback"}
                </button>
              )}
            </li>
          ))}
        </ul>
      </div>

      {loading && <p className="targeting-note">Calculando configuracao efetiva...</p>}
      {error && <p className="targeting-error">{error}</p>}

      {payload && (
        <>
          <div className="targeting-grid">
            {Object.entries(payload.result.effective).map(([key, value]) => (
              <article className="targeting-item" key={key}>
                <h3>{key}</h3>
                <p>{toPretty(value)}</p>
              </article>
            ))}
          </div>

          <div className="targeting-trace">
            <h3>{t(uiLanguage, "appliedPackages")}</h3>
            <ul>
              {payload.result.appliedPackages.map((pkg) => (
                <li key={pkg.id}>
                  <strong>{pkg.id}</strong> ({pkg.scope})
                  <span className={`pkg-status state-${pkg.status ?? "active"}`}>
                    {pkg.status ?? "active"}
                  </span>
                  {pkg.rollout && (
                    <span className="pkg-rollout">
                      rollout: {pkg.rollout.activation}
                    </span>
                  )}
                </li>
              ))}
            </ul>
          </div>

          <div className="targeting-trace">
            <h3>{t(uiLanguage, "recentAudit")}</h3>
            <ul>
              {audit.map((entry) => (
                <li key={entry.id}>
                  <strong>{entry.packageId}</strong> | {entry.scope} | {entry.actorId}
                </li>
              ))}
            </ul>
          </div>
        </>
      )}
    </section>
  );
}
