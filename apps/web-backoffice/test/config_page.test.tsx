import assert from 'node:assert/strict';
import test from 'node:test';
import { renderToStaticMarkup } from 'react-dom/server';

import BackofficeConfigPage from '../app/backoffice/config/page';

test('backoffice config page exposes operational config route content', () => {
  const markup = renderToStaticMarkup(<BackofficeConfigPage />);

  assert.match(markup, /Governanca operacional do check-in e captura/);
  assert.match(markup, /Operational Policy Config/);
  assert.match(markup, /Voltar ao dashboard/);
  assert.match(markup, /editor legado foi retirado/i);
  assert.doesNotMatch(markup, /Package catalog/i);
});
