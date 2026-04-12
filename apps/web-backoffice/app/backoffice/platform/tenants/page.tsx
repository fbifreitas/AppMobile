'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';

type TenantApplication = {
  tenantId: string;
  appCode: string;
  brandName: string;
  displayName: string;
  applicationId: string;
  bundleId: string;
  firebaseAppId?: string;
  distributionChannel?: string;
  distributionGroup?: string;
  status: string;
};

type TenantLicense = {
  tenantId: string;
  licenseModel: string;
  contractedSeats: number;
  warningSeats: number;
  hardLimitEnforced: boolean;
  consumedSeats: number;
  availableSeats: number;
  overLimit: boolean;
};

type TenantSummary = {
  tenantId: string;
  slug: string;
  displayName: string;
  tenantStatus: string;
  application: TenantApplication | null;
  license: TenantLicense;
};

type TenantAdmin = {
  id: number;
  email: string;
  nome: string;
  tipo: string;
  status: string;
  role: string;
};

type TenantAdminHandoff = {
  tenantId: string;
  adminUser: TenantAdmin | null;
  credentialProvisioned: boolean;
  credentialUpdatedAt?: string | null;
  temporaryPassword?: string | null;
};

type TenantListResponse = {
  total: number;
  items: TenantSummary[];
};

type CreateTenantForm = {
  tenantId: string;
  slug: string;
  displayName: string;
  status: string;
};

function normalizeAppToken(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '.')
    .replace(/^\.+|\.+$/g, '')
    .replace(/\.{2,}/g, '.');
}

function buildDefaultApplicationId(seed: string): string {
  const normalized = normalizeAppToken(seed);
  return normalized ? `br.com.${normalized}` : '';
}

const applicationTemplate: TenantApplication = {
  tenantId: '',
  appCode: '',
  brandName: '',
  displayName: '',
  applicationId: '',
  bundleId: '',
  firebaseAppId: '',
  distributionChannel: 'firebase',
  distributionGroup: '',
  status: 'DRAFT',
};

const licenseTemplate: TenantLicense = {
  tenantId: '',
  licenseModel: 'PER_USER',
  contractedSeats: 0,
  warningSeats: 0,
  hardLimitEnforced: true,
  consumedSeats: 0,
  availableSeats: 0,
  overLimit: false,
};

const adminHandoffTemplate: TenantAdminHandoff = {
  tenantId: '',
  adminUser: null,
  credentialProvisioned: false,
  credentialUpdatedAt: null,
  temporaryPassword: null,
};

export default function PlatformTenantsPage() {
  const [items, setItems] = useState<TenantSummary[]>([]);
  const [createTenantForm, setCreateTenantForm] = useState<CreateTenantForm>({
    tenantId: 'tenant-compass',
    slug: 'compass',
    displayName: 'Compass',
    status: 'ACTIVE',
  });
  const [selectedTenantId, setSelectedTenantId] = useState('');
  const [application, setApplication] = useState<TenantApplication>(applicationTemplate);
  const [license, setLicense] = useState<TenantLicense>(licenseTemplate);
  const [adminHandoff, setAdminHandoff] = useState<TenantAdminHandoff>(adminHandoffTemplate);
  const [adminForm, setAdminForm] = useState({
    email: '',
    nome: '',
    tipo: 'PJ',
    cpf: '',
    cnpj: '',
    externalId: '',
    temporaryPassword: '',
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const loadAdminHandoff = useCallback(async (tenantId: string, displayName?: string) => {
    const response = await fetch(`/api/platform/tenants/${tenantId}/admin-handoff`);
    const payload = (await response.json()) as TenantAdminHandoff & { error?: string; message?: string };
    if (!response.ok) {
      throw new Error(payload.error || payload.message || 'Falha ao carregar handoff do admin');
    }

    setAdminHandoff(payload);
    setAdminForm({
      email: payload.adminUser?.email || '',
      nome: payload.adminUser?.nome || `${displayName || 'Tenant'} Admin`,
      tipo: payload.adminUser?.tipo || 'PJ',
      cpf: '',
      cnpj: '',
      externalId: '',
      temporaryPassword: '',
    });
  }, []);

  const applyTenantSelection = useCallback(async (item: TenantSummary) => {
    const applicationSeed = item.application?.appCode || item.slug || item.tenantId;
    setSelectedTenantId(item.tenantId);
    setApplication({
      ...applicationTemplate,
      tenantId: item.tenantId,
      appCode: item.application?.appCode || item.slug,
      brandName: item.application?.brandName || item.displayName,
      displayName: item.application?.displayName || item.displayName,
      applicationId: item.application?.applicationId || buildDefaultApplicationId(applicationSeed),
      bundleId: item.application?.bundleId || buildDefaultApplicationId(applicationSeed),
      firebaseAppId: item.application?.firebaseAppId || '',
      distributionChannel: item.application?.distributionChannel || 'firebase',
      distributionGroup: item.application?.distributionGroup || '',
      status: item.application?.status || 'DRAFT',
    });
    setLicense({
      ...licenseTemplate,
      tenantId: item.tenantId,
      licenseModel: item.license?.licenseModel || 'PER_USER',
      contractedSeats: item.license?.contractedSeats || 0,
      warningSeats: item.license?.warningSeats || 0,
      hardLimitEnforced: item.license?.hardLimitEnforced ?? true,
      consumedSeats: item.license?.consumedSeats || 0,
      availableSeats: item.license?.availableSeats || 0,
      overLimit: item.license?.overLimit || false,
    });
    await loadAdminHandoff(item.tenantId, item.displayName);
    setMessage(null);
    setError(null);
  }, [loadAdminHandoff]);

  const loadTenants = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch('/api/platform/tenants');
      const payload = (await response.json()) as TenantListResponse;
      if (!response.ok) {
        throw new Error((payload as { error?: string }).error || 'Falha ao carregar tenants');
      }

      setItems(payload.items);
      if (payload.items.length === 0) {
        setSelectedTenantId('');
        setApplication(applicationTemplate);
        setLicense(licenseTemplate);
        setAdminHandoff(adminHandoffTemplate);
      } else if (selectedTenantId) {
        const selected = payload.items.find((item) => item.tenantId === selectedTenantId);
        if (selected) {
          await applyTenantSelection(selected);
        }
      } else {
        await applyTenantSelection(payload.items[0]);
      }
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Falha ao carregar tenants');
    } finally {
      setLoading(false);
    }
  }, [applyTenantSelection, selectedTenantId]);

  useEffect(() => {
    void loadTenants();
  }, [loadTenants]);

  const selectedTenant = useMemo(
    () => items.find((item) => item.tenantId === selectedTenantId) || null,
    [items, selectedTenantId]
  );

  async function saveApplication() {
    if (!selectedTenantId) return;
    const payload = {
      ...application,
      appCode: application.appCode.trim(),
      brandName: application.brandName.trim(),
      displayName: application.displayName.trim(),
      applicationId: application.applicationId.trim(),
      bundleId: application.bundleId.trim(),
      firebaseAppId: application.firebaseAppId?.trim() || '',
      distributionChannel: application.distributionChannel?.trim() || '',
      distributionGroup: application.distributionGroup?.trim() || '',
      status: application.status.trim(),
    };

    if (!payload.appCode || !payload.brandName || !payload.displayName || !payload.applicationId || !payload.bundleId || !payload.status) {
      setError('Preencha App code, Brand, Display name, Application ID, Bundle ID e Status antes de salvar.');
      setMessage(null);
      return;
    }

    setSaving(true);
    setError(null);
    setMessage(null);
    try {
      const response: Response = await fetch(`/api/platform/tenants/${selectedTenantId}/application`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const responseBody = await response.json();
      if (!response.ok) {
        throw new Error(responseBody.error || responseBody.message || 'Falha ao salvar app/marca');
      }
      setApplication((current) => ({
        ...current,
        ...responseBody,
      }));
      setMessage('Aplicativo/marca atualizado.');
      await loadTenants();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Falha ao salvar app/marca');
    } finally {
      setSaving(false);
    }
  }

  async function createTenant() {
    setSaving(true);
    setError(null);
    setMessage(null);
    try {
      const response = await fetch('/api/platform/tenants', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(createTenantForm),
      });
      const payload = await response.json();
      if (!response.ok) {
        throw new Error(payload.error || payload.message || 'Falha ao criar tenant');
      }
      setSelectedTenantId(createTenantForm.tenantId);
      setMessage('Tenant criado para iniciar o onboarding da empresa.');
      await loadTenants();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Falha ao criar tenant');
    } finally {
      setSaving(false);
    }
  }

  async function saveLicense() {
    if (!selectedTenantId) return;
    setSaving(true);
    setError(null);
    setMessage(null);
    try {
      const response = await fetch(`/api/platform/tenants/${selectedTenantId}/license`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          licenseModel: license.licenseModel,
          contractedSeats: Number(license.contractedSeats),
          warningSeats: Number(license.warningSeats),
          hardLimitEnforced: license.hardLimitEnforced,
        }),
      });
      const payload = await response.json();
      if (!response.ok) {
        throw new Error(payload.error || payload.message || 'Falha ao salvar licenciamento');
      }
      setMessage('Licenciamento por usuario atualizado.');
      await loadTenants();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Falha ao salvar licenciamento');
    } finally {
      setSaving(false);
    }
  }

  async function saveAdminHandoff() {
    if (!selectedTenantId) return;
    setSaving(true);
    setError(null);
    setMessage(null);
    try {
      const response = await fetch(`/api/platform/tenants/${selectedTenantId}/admin-handoff`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(adminForm),
      });
      const payload = (await response.json()) as TenantAdminHandoff & { error?: string; message?: string };
      if (!response.ok) {
        throw new Error(payload.error || payload.message || 'Falha ao provisionar admin inicial');
      }
      setAdminHandoff(payload);
      setAdminForm((current) => ({ ...current, temporaryPassword: '' }));
      setMessage('Admin inicial provisionado para handoff controlado.');
      await loadTenants();
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Falha ao provisionar admin inicial');
    } finally {
      setSaving(false);
    }
  }

  return (
    <main style={{ padding: 24, display: 'grid', gap: 24 }}>
      <section>
        <p style={{ margin: 0, fontSize: 12, letterSpacing: 1.2, textTransform: 'uppercase', color: '#6b7280' }}>
          Homolog Compass
        </p>
        <h1 style={{ margin: '8px 0 12px' }}>Tenant SaaS, app por marca e seats por usuario</h1>
        <p style={{ maxWidth: 840, color: '#374151' }}>
          Superficie minima para operar a Compass em homolog sem depender de billing automatico.
          Aqui a plataforma governa tenant, aplicativo por marca e licenciamento SaaS por usuario.
        </p>
      </section>

      {error ? <p style={{ color: '#b91c1c' }}>{error}</p> : null}
      {message ? <p style={{ color: '#047857' }}>{message}</p> : null}

      <section style={{ display: 'grid', gridTemplateColumns: '1.1fr 1.4fr', gap: 24 }}>
        <div style={{ border: '1px solid #e5e7eb', borderRadius: 12, padding: 16, background: '#fff' }}>
          <div style={{ border: '1px solid #d1d5db', borderRadius: 10, padding: 12, marginBottom: 16 }}>
            <h2 style={{ marginTop: 0 }}>Criar tenant</h2>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: 10 }}>
              <label>Tenant ID<input value={createTenantForm.tenantId} onChange={(e) => setCreateTenantForm({ ...createTenantForm, tenantId: e.target.value })} /></label>
              <label>Slug<input value={createTenantForm.slug} onChange={(e) => setCreateTenantForm({ ...createTenantForm, slug: e.target.value })} /></label>
              <label>Display name<input value={createTenantForm.displayName} onChange={(e) => setCreateTenantForm({ ...createTenantForm, displayName: e.target.value })} /></label>
              <label>Status
                <select value={createTenantForm.status} onChange={(e) => setCreateTenantForm({ ...createTenantForm, status: e.target.value })}>
                  <option value="ACTIVE">ACTIVE</option>
                  <option value="INACTIVE">INACTIVE</option>
                </select>
              </label>
            </div>
            <button onClick={() => void createTenant()} disabled={saving} style={{ marginTop: 12 }}>
              Criar tenant
            </button>
          </div>

          <h2 style={{ marginTop: 0 }}>Tenants</h2>
          {loading ? <p>Carregando...</p> : null}
          <div style={{ display: 'grid', gap: 12 }}>
            {items.map((item) => (
              <button
                key={item.tenantId}
                onClick={() => applyTenantSelection(item)}
                style={{
                  textAlign: 'left',
                  border: selectedTenantId === item.tenantId ? '2px solid #0f766e' : '1px solid #d1d5db',
                  borderRadius: 10,
                  padding: 12,
                  background: selectedTenantId === item.tenantId ? '#f0fdfa' : '#fff',
                  cursor: 'pointer',
                }}
              >
                <strong>{item.displayName}</strong>
                <div style={{ fontSize: 13, color: '#4b5563', marginTop: 6 }}>
                  <div>tenantId: {item.tenantId}</div>
                  <div>slug: {item.slug}</div>
                  <div>status: {item.tenantStatus}</div>
                  <div>seats: {item.license.consumedSeats}/{item.license.contractedSeats}</div>
                </div>
              </button>
            ))}
          </div>
        </div>

        <div style={{ display: 'grid', gap: 24 }}>
          <section style={{ border: '1px solid #e5e7eb', borderRadius: 12, padding: 16, background: '#fff' }}>
            <h2 style={{ marginTop: 0 }}>Aplicativo por marca</h2>
            <p style={{ color: '#4b5563' }}>
              Tenant selecionado: <strong>{selectedTenant?.displayName || 'nenhum'}</strong>
            </p>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <label>App code<input value={application.appCode} onChange={(e) => setApplication({ ...application, appCode: e.target.value })} /></label>
              <label>Brand<input value={application.brandName} onChange={(e) => setApplication({ ...application, brandName: e.target.value })} /></label>
              <label>Display name<input value={application.displayName} onChange={(e) => setApplication({ ...application, displayName: e.target.value })} /></label>
              <label>Application ID<input value={application.applicationId} onChange={(e) => setApplication({ ...application, applicationId: e.target.value })} placeholder="br.com.compass" /></label>
              <label>Bundle ID<input value={application.bundleId} onChange={(e) => setApplication({ ...application, bundleId: e.target.value })} placeholder="br.com.compass" /></label>
              <label>Firebase app<input value={application.firebaseAppId || ''} onChange={(e) => setApplication({ ...application, firebaseAppId: e.target.value })} /></label>
              <label>Canal<input value={application.distributionChannel || ''} onChange={(e) => setApplication({ ...application, distributionChannel: e.target.value })} /></label>
              <label>Grupo<input value={application.distributionGroup || ''} onChange={(e) => setApplication({ ...application, distributionGroup: e.target.value })} /></label>
              <label>Status
                <select value={application.status} onChange={(e) => setApplication({ ...application, status: e.target.value })}>
                  <option value="DRAFT">DRAFT</option>
                  <option value="READY">READY</option>
                  <option value="ACTIVE">ACTIVE</option>
                </select>
              </label>
            </div>
            <button onClick={() => void saveApplication()} disabled={saving || !selectedTenantId} style={{ marginTop: 16 }}>
              Salvar app/marca
            </button>
          </section>

          <section style={{ border: '1px solid #e5e7eb', borderRadius: 12, padding: 16, background: '#fff' }}>
            <h2 style={{ marginTop: 0 }}>Licenciamento SaaS por usuario</h2>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <label>Modelo
                <select value={license.licenseModel} onChange={(e) => setLicense({ ...license, licenseModel: e.target.value })}>
                  <option value="PER_USER">PER_USER</option>
                </select>
              </label>
              <label>Seats contratados<input type="number" value={license.contractedSeats} onChange={(e) => setLicense({ ...license, contractedSeats: Number(e.target.value) })} /></label>
              <label>Warning threshold<input type="number" value={license.warningSeats} onChange={(e) => setLicense({ ...license, warningSeats: Number(e.target.value) })} /></label>
              <label style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <input type="checkbox" checked={license.hardLimitEnforced} onChange={(e) => setLicense({ ...license, hardLimitEnforced: e.target.checked })} />
                hard limit enforced
              </label>
            </div>
            <div style={{ marginTop: 12, color: '#4b5563' }}>
              <div>Consumidos: {license.consumedSeats}</div>
              <div>Disponiveis: {license.availableSeats}</div>
              <div>Over limit: {license.overLimit ? 'sim' : 'nao'}</div>
            </div>
            <button onClick={() => void saveLicense()} disabled={saving || !selectedTenantId} style={{ marginTop: 16 }}>
              Salvar licenciamento
            </button>
          </section>

          <section style={{ border: '1px solid #e5e7eb', borderRadius: 12, padding: 16, background: '#fff' }}>
            <h2 style={{ marginTop: 0 }}>Admin inicial e handoff</h2>
            <p style={{ color: '#4b5563' }}>
              Provisiona o primeiro <strong>TENANT_ADMIN</strong> com credencial interna para liberar o login web real do tenant.
            </p>
            <div style={{ marginBottom: 12, color: '#4b5563' }}>
              <div>Admin atual: {adminHandoff.adminUser?.email || 'nao provisionado'}</div>
              <div>Credencial ativa: {adminHandoff.credentialProvisioned ? 'sim' : 'nao'}</div>
              <div>
                Ultima provisao: {adminHandoff.credentialUpdatedAt ? new Date(adminHandoff.credentialUpdatedAt).toLocaleString('pt-BR') : 'n/a'}
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <label>E-mail<input value={adminForm.email} onChange={(e) => setAdminForm({ ...adminForm, email: e.target.value })} /></label>
              <label>Nome<input value={adminForm.nome} onChange={(e) => setAdminForm({ ...adminForm, nome: e.target.value })} /></label>
              <label>Tipo
                <select value={adminForm.tipo} onChange={(e) => setAdminForm({ ...adminForm, tipo: e.target.value })}>
                  <option value="PJ">PJ</option>
                  <option value="CLT">CLT</option>
                </select>
              </label>
              <label>Senha temporaria<input value={adminForm.temporaryPassword} onChange={(e) => setAdminForm({ ...adminForm, temporaryPassword: e.target.value })} /></label>
              <label>CPF<input value={adminForm.cpf} onChange={(e) => setAdminForm({ ...adminForm, cpf: e.target.value })} /></label>
              <label>CNPJ<input value={adminForm.cnpj} onChange={(e) => setAdminForm({ ...adminForm, cnpj: e.target.value })} /></label>
              <label style={{ gridColumn: '1 / -1' }}>External ID<input value={adminForm.externalId} onChange={(e) => setAdminForm({ ...adminForm, externalId: e.target.value })} /></label>
            </div>
            {adminHandoff.temporaryPassword ? (
              <p style={{ marginTop: 12, color: '#92400e' }}>
                Senha temporaria atual para handoff: <strong>{adminHandoff.temporaryPassword}</strong>
              </p>
            ) : null}
            <button onClick={() => void saveAdminHandoff()} disabled={saving || !selectedTenantId} style={{ marginTop: 16 }}>
              Provisionar admin inicial
            </button>
          </section>
        </div>
      </section>
    </main>
  );
}
