import { expect, mock, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'
import type { On } from 'claude-code'

import { commandsIn, pickEntry } from './discover'

const HOME = '/Users/test'
const CONFIG = `${HOME}/.claude-alt`
const CACHE = `${CONFIG}/plugins/cache`
const PROJECT = '/work/app'
const SURFACES = ['terminal', 'desktop'] as const
const RUN_MODS = {
  command: 'mods',
  args: '',
  origin: { kind: 'composer' },
  presentation: { isFullscreen: true, columns: 160 },
} as const

type Disk = Record<string, string>

const PANE = (bodyColumns: number) =>
  ({
    plugin: 'mod-index',
    component: 'Pane',
    requestId: 'mods',
    props: {
      title: 'Mods',
      isFocused: true,
      bodyColumns,
      placement: 'dock',
      scroll: { offset: 0, bodyRows: 40 },
      view: {},
    },
  }) as const

const MOD_SOURCE = `
const CMD = 'shape'
export const register = on => {
  on('session.start', async $ => {
    await $.command.register({ name: CMD, description: 'Turn shaping on or off' })
    await $.command.register({
      name: "brief",
      description: "Write a brief, with \\"quotes\\"",
      immediate: true,
    })
  })
}
`

function mod(name: string, version: string, description: string, hooksJson: string, source: string): Disk {
  const root = `${CACHE}/m/${name}/${version}`
  return {
    [`${root}/.claude-plugin/plugin.json`]: JSON.stringify({ name, version, description }),
    [`${root}/hooks/hooks.json`]: hooksJson,
    [`${root}/hooks/register.tsx`]: source,
    [`${root}/hooks/register.test.tsx`]: "$.command.register({ name: 'ghost', description: 'x' })",
  }
}

const entry = (name: string, version: string, scope: string, projectPath?: string) => ({
  scope,
  ...(projectPath ? { projectPath } : {}),
  installPath: `${CACHE}/m/${name}/${version}`,
  version,
})

function world(): Disk {
  const installed = {
    version: 2,
    plugins: {
      'brain-dump@m': [entry('brain-dump', '0.2.0', 'project', HOME), entry('brain-dump', '0.2.0', 'user')],
      'off-mod@m': [entry('off-mod', '1.0.0', 'user')],
      'skills-only@m': [entry('skills-only', '1.0.0', 'user')],
      'proj-mod@m': [entry('proj-mod', '0.3.0', 'project', PROJECT)],
      'other-proj@m': [entry('other-proj', '0.1.0', 'project', '/elsewhere')],
      'mod-index@m': [entry('mod-index', '0.1.0', 'user')],
    },
  }
  const settings = {
    enabledPlugins: {
      'brain-dump@m': true,
      'off-mod@m': false,
      'skills-only@m': true,
      'proj-mod@m': true,
      'other-proj@m': true,
      'mod-index@m': true,
    },
  }
  return {
    [`${CONFIG}/plugins/installed_plugins.json`]: JSON.stringify(installed),
    [`${CONFIG}/settings.json`]: JSON.stringify(settings),
    ...mod('brain-dump', '0.2.0', 'Shapes long prompts into briefs', '{ "modules": ["./register.tsx"] }', MOD_SOURCE),
    ...mod('off-mod', '1.0.0', 'Disabled', '{ "modules": ["./register.tsx"] }', ''),
    ...mod('skills-only', '1.0.0', 'Only skills', '{ "hooks": {} }', ''),
    ...mod('proj-mod', '0.3.0', 'A project mod', '{ "modules": ["./register.tsx"] }', "$.command.register({ name: 'proj', description: 'Do project things' })"),
    ...mod('other-proj', '0.1.0', 'Elsewhere', '{ "modules": ["./register.tsx"] }', ''),
    ...mod('mod-index', '0.1.0', 'Me', '{ "modules": ["./register.tsx"] }', ''),
  }
}

function listing(disk: Disk, dir: string) {
  const prefix = `${dir}/`
  const names = new Map<string, 'file' | 'dir'>()
  for (const path of Object.keys(disk)) {
    if (!path.startsWith(prefix)) continue
    const [head, ...rest] = path.slice(prefix.length).split('/')
    if (head) names.set(head, rest.length ? 'dir' : 'file')
  }
  return [...names].map(([name, kind]) => ({ name, kind, size: 10, mtimeMs: 0, isLink: false }))
}

type Recorder = { opened: string[]; focused: boolean[]; closed: string[]; filled: string[]; panes: string[] }

function setup(on: On, disk: Disk, env: Record<string, string>, cwd = PROJECT): Recorder {
  const r: Recorder = { opened: [], focused: [], closed: [], filled: [], panes: [] }
  mock.env(on, env)
  on('session.start', async (_, e) => ({ cwd: e.cwd }))
  on('session.cwd', async () => ({ value: cwd }) as never)
  on('command.register', async () => ({ value: { command: 'mods' } }) as never)
  on('fs.exists', async (_, e) => ({ value: (e as { path: string }).path in disk }) as never)
  on('fs.read', async (_, e) => ({ value: disk[(e as { path: string }).path] ?? '' }) as never)
  on('fs.list', async (_, e) => ({ value: listing(disk, (e as { path: string }).path) }) as never)
  on('ui.open', async (_, e) => {
    const { id, focus } = e as { id: string; focus?: boolean }
    r.opened.push(id)
    r.focused.push(focus === true)
    r.panes.push(id)
    return { value: { isPlaced: true } } as never
  })
  on('ui.close', async (_, e) => {
    const id = (e as { id: string }).id
    r.closed.push(id)
    r.panes.splice(r.panes.indexOf(id), 1)
    return { value: undefined } as never
  })
  on('ui.panes', async () =>
    ({ value: r.panes.map(id => ({ id, title: 'Mods', isShown: true, isFocused: false, isPlaced: true })) }) as never,
  )
  on('ui.log', async () => ({ value: undefined }) as never)
  on('ui.toast', async () => ({ value: undefined }) as never)
  on('prompt.fill', async (_, e) => {
    r.filled.push((e as { text: string }).text)
    return { isFilled: true } as never
  })
  return r
}

const start = ($: Engine, cwd = PROJECT) =>
  $.session.start({ cwd, surface: 'terminal', isInteractive: true })

test('extracts command names and descriptions, constants and escapes included', () => {
  expect(commandsIn(MOD_SOURCE)).toEqual([
    { name: 'shape', description: 'Turn shaping on or off' },
    { name: 'brief', description: 'Write a brief, with "quotes"' },
  ])
  expect(commandsIn("$.command.register({ name: 'bare' })")).toEqual([{ name: 'bare', description: '' }])
  expect(commandsIn('$.command.register({ name: dynamicName })')).toEqual([])
})

test('prefers the user entry and matches a project entry by cwd prefix', () => {
  const user = { scope: 'user', projectPath: '', installPath: '/u', version: '1' }
  const proj = { scope: 'project', projectPath: '/work/app', installPath: '/p', version: '1' }
  expect(pickEntry([proj, user], '/elsewhere')?.installPath).toBe('/u')
  expect(pickEntry([proj], '/work/app/src')?.installPath).toBe('/p')
  expect(pickEntry([proj], '/work/application')).toBeUndefined()
})

for (const surface of SURFACES) {
  test(`lists enabled mods only, with commands and when they run (${surface})`, async ($, on) => {
    setup(on, world(), { CLAUDE_CONFIG_DIR: `${CONFIG}/`, HOME })
    await start($)
    const ui = await $.ui.mount({ ...PANE(60), surface })

    expect(await ui.find({ type: 'Text', text: 'brain-dump' })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: 'proj-mod' })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: 'off-mod' })).toBeUndefined()
    expect(await ui.find({ type: 'Text', text: 'skills-only' })).toBeUndefined()
    expect(await ui.find({ type: 'Text', text: 'other-proj' })).toBeUndefined()
    expect(await ui.find({ type: 'Text', text: /^mod-index/ })).toBeUndefined()
    expect(await ui.find({ type: 'Text', text: 'Sozinho: prompts com 120+ palavras' })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: 'Manual: /proj' })).toBeDefined()
    expect(await ui.find({ key: 'cmd:brain-dump@m:shape' })).toBeDefined()
    expect(await ui.find({ key: 'cmd:brain-dump@m:brief' })).toBeDefined()
    expect(await ui.find({ key: 'cmd:brain-dump@m:ghost' })).toBeUndefined()
    expect((await ui.find({ type: 'Text', text: /perfil/ }))?.text).toBe('2 mods · perfil .claude-alt')
    await ui.unmount()
  })
}

test('falls back to HOME/.claude when CLAUDE_CONFIG_DIR is unset', async ($, on) => {
  const disk = Object.fromEntries(Object.entries(world()).map(([k, v]) => [k.replace(CONFIG, `${HOME}/.claude`), v.split(CONFIG).join(`${HOME}/.claude`)]))
  setup(on, disk, { HOME })
  await start($, '/nowhere')
  const ui = await $.ui.mount({ ...PANE(60), surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /perfil/ }))?.text).toBe('1 mod · perfil .claude')
  await ui.unmount()
})

test('opens unfocused at session start; /mods closes it and reopens it focused', async ($, on) => {
  const r = setup(on, world(), { CLAUDE_CONFIG_DIR: CONFIG, HOME })
  await start($)
  for (let i = 0; i < 20 && r.opened.length === 0; i += 1) await new Promise(resolve => setTimeout(resolve, 5))
  expect(r.opened).toEqual(['mods'])
  expect(r.focused).toEqual([false])
  const closed = await $.command.run(RUN_MODS)
  expect(closed.text).toBe('Painel Mods fechado.')
  expect(r.closed).toEqual(['mods'])
  const opened = await $.command.run(RUN_MODS)
  expect(opened.text).toBe('Painel Mods aberto.')
  for (let i = 0; i < 50 && r.opened.length < 2; i += 1) await Promise.resolve()
  expect(r.opened).toEqual(['mods', 'mods'])
  expect(r.focused).toEqual([false, true])
})

for (const surface of SURFACES) {
  test(`pressing a command row fills the prompt without sending (${surface})`, async ($, on) => {
    const r = setup(on, world(), { CLAUDE_CONFIG_DIR: CONFIG, HOME })
    await start($)
    const ui = await $.ui.mount({ ...PANE(40), surface })
    await ui.press({ key: 'cmd:proj-mod@m:proj' })
    expect(r.filled).toEqual(['/proj '])
    await ui.unmount()
  })
}

for (const surface of SURFACES) {
  test(`shows the empty state when nothing is installed (${surface})`, async ($, on) => {
    setup(on, {}, { CLAUDE_CONFIG_DIR: CONFIG, HOME })
    await start($)
    const ui = await $.ui.mount({ ...PANE(30), surface })
    const texts = (await ui.findAll({ type: 'Text' })).map(t => t.text)
    expect(texts.slice(0, -2).join(' ')).toBe('Nenhum mod instalado neste perfil.')
    expect((await ui.find({ type: 'Text', text: /perfil \./ }))?.text).toBe('0 mods · perfil .claude-alt')
    await ui.unmount()
  })
}

test('every text fits a narrow pane', async ($, on) => {
  setup(on, world(), { CLAUDE_CONFIG_DIR: CONFIG, HOME })
  await start($)
  for (const cols of [16, 24, 120]) {
    const ui = await $.ui.mount({ ...PANE(cols), surface: 'terminal' })
    const texts = await ui.findAll({ type: 'Text' })
    for (const t of texts) expect(t.text.length <= cols).toBe(true)
    await ui.unmount()
  }
})
