import type { EngineInterface } from 'claude-code'

import type { ModCommand, ModIndex, ModInfo } from '../types'

const SELF = 'mod-index'
const SOURCE_FILE = /\.(tsx?|mts|cts|mjs|cjs|jsx?)$/
const TEST_FILE = /\.test\./
const MAX_DEPTH = 2
const MAX_FILE_BYTES = 2_000_000

const WHEN: Readonly<Record<string, string>> = {
  'brain-dump': 'Sozinho: prompts com 120+ palavras',
  handoff: 'Sozinho: aos 250k tokens',
  'helper-desk': 'Sozinho: quando há tarefas ou subagentes',
  reflect: 'Sozinho: quando corriges o Claude',
  'chat-inventory': 'Sozinho: abre no primeiro uso de ferramentas',
  'blast-radius': 'Sozinho: antes de rm -rf, reset --hard, force push…',
  filetree: 'Manual: /filetree (precisa de 110+ colunas)',
}

type InstallEntry = { scope: string; projectPath: string; installPath: string; version: string }

type Json = Record<string, unknown>

const isObject = (value: unknown): value is Json =>
  typeof value === 'object' && value !== null && !Array.isArray(value)

const str = (value: unknown): string => (typeof value === 'string' ? value : '')

const trimSlash = (path: string): string => (path.length > 1 ? path.replace(/\/+$/, '') : path)

export const basename = (path: string): string => trimSlash(path).split('/').pop() ?? path

function parseJson(text: string): Json | undefined {
  try {
    const value: unknown = JSON.parse(text)
    return isObject(value) ? value : undefined
  } catch {
    return undefined
  }
}

async function readText($: EngineInterface, path: string): Promise<string | undefined> {
  try {
    if (!(await $.fs.exists(path))) return undefined
    const text = await $.fs.read(path)
    return typeof text === 'string' ? text : undefined
  } catch {
    return undefined
  }
}

const unquote = (body: string): string => body.replace(/\\(.)/g, '$1')

const literal = (group: number): string => `(['"\\x60])((?:\\\\.|(?!\\${group})[^\\\\])*)\\${group}`

function constants(source: string): Map<string, string> {
  const found = new Map<string, string>()
  for (const m of source.matchAll(new RegExp(String.raw`\bconst\s+([A-Za-z_$][\w$]*)\s*=\s*` + literal(2), 'g'))) {
    const [, name, , body] = m
    if (name && body !== undefined && !found.has(name)) found.set(name, unquote(body))
  }
  return found
}

function field(block: string, key: string, consts: Map<string, string>): string | undefined {
  const quoted = block.match(new RegExp(String.raw`\b${key}\s*:\s*` + literal(1)))
  if (quoted?.[2] !== undefined) return unquote(quoted[2])
  const ident = block.match(new RegExp(String.raw`\b${key}\s*:\s*([A-Za-z_$][\w$]*)`))
  return ident?.[1] ? consts.get(ident[1]) : undefined
}

export function commandsIn(source: string): ModCommand[] {
  const consts = constants(source)
  const seen = new Set<string>()
  const out: ModCommand[] = []
  for (const m of source.matchAll(/command\.register\(\s*\{([\s\S]*?)\}\s*\)/g)) {
    const block = m[1] ?? ''
    const name = field(block, 'name', consts)
    if (!name || !/^[\w-]{1,64}$/.test(name) || seen.has(name)) continue
    seen.add(name)
    out.push({ name, description: field(block, 'description', consts) ?? '' })
  }
  return out
}

async function sourceFiles($: EngineInterface, dir: string, depth: number): Promise<string[]> {
  let entries: Awaited<ReturnType<EngineInterface['fs']['list']>>
  try {
    entries = await $.fs.list(dir)
  } catch {
    return []
  }
  const files = entries
    .filter(x => x.kind === 'file' && SOURCE_FILE.test(x.name) && !TEST_FILE.test(x.name) && x.size <= MAX_FILE_BYTES)
    .map(x => `${dir}/${x.name}`)
    .sort()
  if (depth >= MAX_DEPTH) return files
  const subdirs = entries
    .filter(x => x.kind === 'dir' && !x.name.startsWith('.') && x.name !== 'node_modules')
    .map(x => `${dir}/${x.name}`)
    .sort()
  const nested = await Promise.all(subdirs.map(d => sourceFiles($, d, depth + 1)))
  return [...files, ...nested.flat()]
}

async function commandsOf($: EngineInterface, installPath: string): Promise<ModCommand[]> {
  const files = await sourceFiles($, `${installPath}/hooks`, 0)
  const texts = await Promise.all(files.map(f => readText($, f)))
  const all = texts.flatMap(t => (t ? commandsIn(t) : []))
  return all.filter((c, i) => all.findIndex(x => x.name === c.name) === i)
}

function entriesOf(value: unknown): InstallEntry[] {
  if (!Array.isArray(value)) return []
  return value.filter(isObject).map(x => ({
    scope: str(x.scope),
    projectPath: trimSlash(str(x.projectPath)),
    installPath: trimSlash(str(x.installPath)),
    version: str(x.version),
  }))
}

const isUnder = (cwd: string, root: string): boolean => root !== '' && (cwd === root || cwd.startsWith(`${root}/`))

export function pickEntry(entries: readonly InstallEntry[], cwd: string): InstallEntry | undefined {
  const usable = entries.filter(x => x.installPath)
  const user = usable.find(x => x.scope === 'user')
  if (user) return user
  return usable
    .filter(x => x.scope !== 'user' && isUnder(cwd, x.projectPath))
    .sort((a, b) => b.projectPath.length - a.projectPath.length)[0]
}

function whenOf(name: string, commands: readonly ModCommand[]): string {
  const curated = WHEN[name]
  if (curated) return curated
  return commands.length ? `Manual: ${commands.map(c => `/${c.name}`).join(', ')}` : ''
}

async function inspect($: EngineInterface, id: string, entry: InstallEntry): Promise<ModInfo | undefined> {
  const hooksJson = parseJson((await readText($, `${entry.installPath}/hooks/hooks.json`)) ?? '')
  if (!hooksJson || !('modules' in hooksJson)) return undefined
  const manifest = parseJson((await readText($, `${entry.installPath}/.claude-plugin/plugin.json`)) ?? '') ?? {}
  const name = str(manifest.name) || id.split('@')[0] || id
  if (name === SELF) return undefined
  const commands = await commandsOf($, entry.installPath)
  return {
    id,
    name,
    version: str(manifest.version) || entry.version,
    description: str(manifest.description),
    when: whenOf(name, commands),
    commands,
  }
}

export async function configDirOf($: EngineInterface): Promise<string> {
  const explicit = await $.env.get('CLAUDE_CONFIG_DIR')
  if (explicit) return trimSlash(explicit)
  const home = (await $.env.get('HOME')) ?? ''
  return `${trimSlash(home)}/.claude`
}

export async function discover($: EngineInterface, cwd: string): Promise<ModIndex> {
  const configDir = await configDirOf($)
  const base: ModIndex = { isScanned: true, profile: basename(configDir), cwd, mods: [], error: '' }
  const installedText = await readText($, `${configDir}/plugins/installed_plugins.json`)
  if (installedText === undefined) return base
  const installed = parseJson(installedText)
  if (!installed) return { ...base, error: 'Não foi possível ler installed_plugins.json.' }
  const settings = parseJson((await readText($, `${configDir}/settings.json`)) ?? '') ?? {}
  const enabled = isObject(settings.enabledPlugins) ? settings.enabledPlugins : {}
  const plugins = isObject(installed.plugins) ? installed.plugins : {}
  const candidates = Object.entries(plugins)
    .filter(([id]) => enabled[id] === true && id.split('@')[0] !== SELF)
    .map(([id, value]) => [id, pickEntry(entriesOf(value), cwd)] as const)
    .filter((pair): pair is readonly [string, InstallEntry] => pair[1] !== undefined)
  const found = await Promise.all(candidates.map(([id, entry]) => inspect($, id, entry)))
  const mods = found
    .filter((m): m is ModInfo => m !== undefined)
    .sort((a, b) => a.name.localeCompare(b.name))
  return { ...base, mods }
}
