"use client";

import { useEffect, useMemo, useState } from "react";

type EndpointState = "healthy" | "degraded" | "offline" | "loading";

type EndpointStatus = {
  label: string;
  url: string;
  state: EndpointState;
  detail: string;
};

const ENDPOINTS: Array<Pick<EndpointStatus, "label" | "url">> = [
  {
    label: "Web health",
    url: "/health"
  },
  {
    label: "API health",
    url: "/api/actuator/health"
  }
];

const POLL_INTERVAL_MS = 15000;

async function checkEndpoint(url: string): Promise<{ state: EndpointState; detail: string }> {
  try {
    const response = await fetch(url, { cache: "no-store" });

    if (response.ok) {
      return { state: "healthy", detail: `HTTP ${response.status}` };
    }

    if (response.status >= 500) {
      return { state: "offline", detail: `HTTP ${response.status}` };
    }

    return { state: "degraded", detail: `HTTP ${response.status}` };
  } catch {
    return { state: "offline", detail: "Sem resposta" };
  }
}

function nextSummary(states: EndpointState[]): string {
  if (states.every((state) => state === "healthy")) {
    return "Operacao estavel";
  }

  if (states.some((state) => state === "offline")) {
    return "Falha critica de conectividade";
  }

  if (states.some((state) => state === "degraded")) {
    return "Operacao com degradacao";
  }

  return "Coletando status";
}

export default function OperationalStatusPanel() {
  const [items, setItems] = useState<EndpointStatus[]>(
    ENDPOINTS.map(({ label, url }) => ({
      label,
      url,
      state: "loading",
      detail: "Aguardando leitura"
    }))
  );
  const [updatedAt, setUpdatedAt] = useState<string>("-");

  useEffect(() => {
    let isMounted = true;

    const refresh = async () => {
      const checks = await Promise.all(
        ENDPOINTS.map(async ({ label, url }) => {
          const result = await checkEndpoint(url);
          return { label, url, ...result };
        })
      );

      if (!isMounted) {
        return;
      }

      setItems(checks);
      setUpdatedAt(new Date().toLocaleTimeString("pt-BR"));
    };

    refresh();
    const timer = window.setInterval(refresh, POLL_INTERVAL_MS);

    return () => {
      isMounted = false;
      window.clearInterval(timer);
    };
  }, []);

  const summary = useMemo(() => nextSummary(items.map((item) => item.state)), [items]);

  return (
    <section className="status-panel" aria-live="polite">
      <div className="status-panel-head">
        <h2>Status operacional em tempo real</h2>
        <p>
          {summary} • ultima atualizacao: <strong>{updatedAt}</strong>
        </p>
      </div>
      <div className="status-grid">
        {items.map((item) => (
          <article className="status-item" key={item.label}>
            <div className="status-item-top">
              <h3>{item.label}</h3>
              <span className={`status-pill state-${item.state}`}>{item.state}</span>
            </div>
            <p>{item.detail}</p>
            <small>{item.url}</small>
          </article>
        ))}
      </div>
    </section>
  );
}
