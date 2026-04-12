'use client';

import { useState } from 'react';

export default function LogoutButton() {
  const [submitting, setSubmitting] = useState(false);

  async function handleLogout() {
    setSubmitting(true);

    try {
      await fetch('/api/auth/logout', {
        method: 'POST',
        credentials: 'same-origin',
      });
    } finally {
      window.location.href = '/login';
    }
  }

  return (
    <button
      type="button"
      className="ghost danger"
      onClick={handleLogout}
      disabled={submitting}
    >
      {submitting ? 'Saindo...' : 'Sair'}
    </button>
  );
}
