import type { ReactNode } from "react";
import LogoutButton from "../components/logout_button";

const links = [
  { href: "/backoffice/users", label: "Usuarios" },
  { href: "/backoffice/cases", label: "Cases" },
  { href: "/backoffice/jobs", label: "Jobs" },
  { href: "/backoffice/config", label: "Configuracao" },
  { href: "/backoffice/operations", label: "Operacoes" }
];

export default function BackofficeLayout({ children }: { children: ReactNode }) {
  return (
    <div>
      <header
        style={{
          position: "sticky",
          top: 0,
          zIndex: 20,
          background: "#ffffff",
          borderBottom: "1px solid rgba(15, 23, 42, 0.12)"
        }}
      >
        <div
          style={{
            maxWidth: "1200px",
            margin: "0 auto",
            padding: "14px 20px",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            gap: "16px"
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: "12px", flexWrap: "wrap" }}>
            <a href="/" style={{ textDecoration: "none", color: "#0f172a", fontWeight: 800 }}>
              AppMobile
            </a>
            <nav style={{ display: "flex", gap: "10px", flexWrap: "wrap" }}>
              {links.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  style={{ textDecoration: "none", color: "#475569", fontSize: "14px", fontWeight: 600 }}
                >
                  {link.label}
                </a>
              ))}
            </nav>
          </div>
          <LogoutButton />
        </div>
      </header>
      {children}
    </div>
  );
}
