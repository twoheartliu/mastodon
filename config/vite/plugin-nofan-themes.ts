/* This plugin registers glitch-style flavour/skin stylesheets as build
 * entrypoints. Phase 1 covers skins only; flavoured script packs arrive
 * with phase 2 (see flavours/*/theme.yml pack_directory consumers).
 */

import fs from 'node:fs/promises';
import path from 'node:path';

import type { Plugin } from 'vite';

const SKIN_EXTENSIONS = ['scss', 'css'] as const;
const SKIN_ENTRY_NAMES = ['common', 'index', 'application'] as const;

export function NofanThemes(): Plugin {
  const entrypoints: Record<string, string> = {};

  return {
    name: 'nofan-themes',
    async config(userConfig) {
      const existingInputs = userConfig.build?.rolldownOptions?.input;

      if (typeof existingInputs === 'string') {
        entrypoints[path.basename(existingInputs)] = existingInputs;
      } else if (Array.isArray(existingInputs)) {
        for (const input of existingInputs) {
          if (typeof input === 'string') {
            entrypoints[path.basename(input)] = input;
          }
        }
      } else if (typeof existingInputs === 'object') {
        Object.assign(entrypoints, existingInputs);
      }

      if (!userConfig.root) {
        throw new Error('Unknown project directory');
      }
      const jsRoot = userConfig.root;

      await loadSkinEntrypoints(jsRoot, entrypoints);

      return {
        build: {
          rolldownOptions: {
            input: entrypoints,
          },
        },
      };
    },
    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        if (!req.url?.startsWith('/packs-dev/skins/')) {
          next();
          return;
        }

        // Rewrite the URL to the entrypoint if it matches a skin.
        const filename = req.url.slice('/packs-dev/'.length).split(/[.?]/)[0] ?? '';
        if (filename in entrypoints) {
          req.url = `/packs-dev/${entrypoints[filename]}`;
        }
        next();
      });
    },
    handleHotUpdate({ modules, server }) {
      if (modules.length === 0 || !server.config.root) {
        return;
      }

      // The theme name can be deduced solely from the path relative to the
      // skins root: <flavour>/<skin>(/common).<ext>
      const baseRoot = path.join(server.config.root, 'skins');
      const themeNames = new Set<string>();

      const addIfMatches = (file: string | null) => {
        if (!file) {
          return false;
        }
        const segments = path.relative(baseRoot, file).split(path.sep);
        if (
          segments.length >= 2 &&
          segments.length <= 3 &&
          segments[0] !== '..' &&
          segments[1]
        ) {
          const themeName = `skins/${segments[0]}/${path.basename(segments[1], path.extname(segments[1]))}`;
          themeNames.add(themeName);
          return true;
        }
        return false;
      };

      for (const module of modules) {
        if (!addIfMatches(module.file)) {
          for (const importer of module.importers) {
            addIfMatches(importer.file);
          }
        }
      }

      if (themeNames.size > 0) {
        server.ws.send({
          type: 'update',
          updates: Array.from(themeNames).map((themeName) => ({
            type: 'css-update',
            path: themeName,
            acceptedPath: themeName,
            timestamp: Date.now(),
          })),
        });
      }
    },
  };
}

async function loadSkinEntrypoints(jsRoot: string, entrypoints: Record<string, string>) {
  const skinsRoot = path.join(jsRoot, 'skins');
  let flavourNames: string[];
  try {
    flavourNames = await readdirIfDirectory(skinsRoot);
  } catch {
    return; // No skins directory yet.
  }

  for (const flavour of flavourNames) {
    const flavourRoot = path.join(skinsRoot, flavour);
    for (const name of await readdirIfDirectory(flavourRoot)) {
      const location = path.join(flavourRoot, name);

      if ((await fs.stat(location)).isDirectory()) {
        const entry = await findSkinEntry(location);
        if (entry) {
          entrypoints[`skins/${flavour}/${name}`] = entry;
        }
      } else if (SKIN_EXTENSIONS.some((ext) => name.endsWith(`.${ext}`))) {
        entrypoints[`skins/${flavour}/${stripExtension(name)}`] = location;
      }
    }
  }
}

/** Flavours live one level below the skins root; anything else is ignored. */
async function readdirIfDirectory(dir: string): Promise<string[]> {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  return entries.filter((entry) => entry.isDirectory()).map((entry) => entry.name);
}

async function findSkinEntry(dir: string): Promise<string | undefined> {
  for (const base of SKIN_ENTRY_NAMES) {
    for (const ext of SKIN_EXTENSIONS) {
      const candidate = path.join(dir, `${base}.${ext}`);
      try {
        await fs.access(candidate);
        return candidate;
      } catch {
        // Try the next candidate.
      }
    }
  }
  return undefined;
}

function stripExtension(filename: string): string {
  return filename.replace(/\.(?:scss|css)$/i, '');
}
