import assert from 'node:assert/strict';
import test from 'node:test';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';

import BackofficeConfigPage from '../app/backoffice/config/page';

test('backoffice config page exposes operational config route content', () => {
  const markup = renderToStaticMarkup(React.createElement(BackofficeConfigPage));

  assert.match(markup, /Configuracao dinamica de check-in/);
  assert.match(markup, /Central de configuracoes/);
  assert.match(markup, /Voltar ao dashboard/);
});
