import { readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";

const root = resolve(process.cwd(), "test");

function collectTests(dirPath) {
  const entries = readdirSync(dirPath, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const fullPath = join(dirPath, entry.name);

    if (entry.isDirectory()) {
      files.push(...collectTests(fullPath));
      continue;
    }

    if (entry.isFile() && entry.name.endsWith(".test.ts")) {
      files.push(fullPath);
    }
  }

  return files;
}

if (!statSync(root).isDirectory()) {
  console.error("Diretorio de testes nao encontrado:", root);
  process.exit(1);
}

const testFiles = collectTests(root);

if (testFiles.length === 0) {
  console.error("Nenhum arquivo .test.ts encontrado em", root);
  process.exit(1);
}

const result = spawnSync(process.execPath, ["--import", "tsx", "--test", ...testFiles], {
  stdio: "inherit"
});

process.exit(result.status ?? 1);