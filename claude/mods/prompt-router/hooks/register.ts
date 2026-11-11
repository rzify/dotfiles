import type { EngineInterface, PromptSubmitInput, Register } from 'claude-code'

export type Route = 'code' | 'chat' | 'cowork'
export type Verdict = { route: Route; sure: boolean; repo: boolean }

const NAME = 'prompt-router'
const CMD = 'route'
const MODEL = 'haiku'
const MIN_WORDS = 3
const MAX_URL_PROMPT = 14000
const KEEP_PREFIX = /^\s*(here|aqui)\s*:\s*/i
const WORK_DATA_DIR = 'Library/Application Support/Claude-Work'
const LABEL: Record<Exclude<Route, 'code'>, string> = { chat: 'chat', cowork: 'Cowork' }

const SYSTEM = `You route one prompt a developer typed into Claude Code (a coding agent in a terminal) to the best Claude surface. Prompts may be in Portuguese or English.

Surfaces:
- code: Claude Code. Real development work on this machine: write, change, fix, refactor, test, run, build, deploy, commit, review a diff, read or search files, logs or terminal output, inspect the codebase to answer. Also any short follow-up that approves, steers or continues the work in progress ("sim", "avança", "now also X", "undo that", answers to a question the agent just asked).
- chat: the Claude app chat. Pure conversation: opinions, "o que achas", "does this make sense", trade-offs, is-this-over-engineering, should-we, explanations, learning, brainstorming, naming, team or process questions, planning or scoping a feature at a high level (goals, scope, approach, phases), drafting a short text to copy. This includes opinions about the feature, approach or architecture being built, as long as the prompt does not ask to open, read, run or change anything.
- cowork: the Claude app Cowork. Non-code knowledge work that acts across apps or produces a file: email, calendar, Notion, tasks, meeting notes, documents, spreadsheets, slides, PDFs, reports, organizing files or folders outside a repository, multi-source research that ends in a document, recurring non-code jobs.

Examples:
"o que achas desta abordagem de white label, faz sentido?" -> chat, sure
"explica-me como funciona o useEffect" -> chat, sure
"preciso de planear uma feature nova para um projeto" -> chat, sure
"planeia a implementação desta feature com base no código" -> code, sure
"corrige o bug do header" -> code, sure
"porque falha o teste? vê os logs" -> code, sure
"cria uma folha de cálculo a partir dos PDFs nos Downloads" -> cowork, sure
"prepara as notas da reunião e cria as tarefas no Notion" -> cowork, sure

Return JSON only, no prose, no code fences:
{"route":"code|chat|cowork","sure":true|false,"repo":true|false}

- sure: true when the prompt clearly matches one surface above. False only when it fits two surfaces about equally; then pick code.
- repo: true when the prompt refers to the current project, feature, branch or recent work in this session.`

let off = false
let auto = true

async function readSwitch($: EngineInterface) {
  try {
    const path = `${$.plugin.root.split('/.claude/')[0] ?? ''}/.claude/mods/switches.json`
    if (await $.fs.exists(path)) {
      const json = JSON.parse(String(await $.fs.read(path))) as Record<string, unknown>
      off = json[NAME] === false
    }
  } catch {
    return
  }
}

const words = (text: string) => text.trim().split(/\s+/).filter(Boolean).length

export const skips = (e: PromptSubmitInput) => {
  const t = e.text.trim()
  return (
    e.origin.kind !== 'composer' ||
    e.command !== undefined ||
    e.isMeta === true ||
    e.turnId !== undefined ||
    (e.attachments?.length ?? 0) > 0 ||
    t.startsWith('/') ||
    t.startsWith('!') ||
    words(t) < MIN_WORDS
  )
}

export const parseVerdict = (raw: string): Verdict | undefined => {
  const a = raw.indexOf('{')
  const b = raw.lastIndexOf('}')
  if (a < 0 || b <= a) return undefined
  try {
    const j = JSON.parse(raw.slice(a, b + 1)) as { route?: unknown; sure?: unknown; repo?: unknown }
    if (j.route !== 'code' && j.route !== 'chat' && j.route !== 'cowork') return undefined
    return { route: j.route, sure: j.sure === true, repo: j.repo === true }
  } catch {
    return undefined
  }
}

const clip = (s: string, n: number) => (s.length > n ? `${s.slice(0, n)}…` : s)

async function lastTurns($: EngineInterface, count: number, each: number) {
  try {
    const msgs = await $.session.messages()
    return msgs
      .filter(m => m.text.trim())
      .slice(-count)
      .map(m => `${m.role === 'user' ? 'Me' : 'Claude Code'}: ${clip(m.text.trim(), each)}`)
  } catch {
    return []
  }
}

async function classify($: EngineInterface, text: string): Promise<Verdict | undefined> {
  const recent = await lastTurns($, 2, 600)
  const prompt = `${recent.length ? `<recent>\n${recent.join('\n\n')}\n</recent>\n\n` : ''}<prompt>\n${text}\n</prompt>\n\nReturn the JSON.`
  const r = await $.model.complete({ model: MODEL, system: SYSTEM, prompt, maxTokens: 60, effort: 'low', timeoutMs: 8000 })
  return r.isAnswered ? parseVerdict(r.text) : undefined
}

async function git($: EngineInterface, root: string, args: string[]) {
  try {
    const r = await $.process.run(['git', '-C', root, ...args], { timeoutMs: 5000 })
    return r.exitCode === 0 ? r.stdout.trim() : ''
  } catch {
    return ''
  }
}

async function repoContext($: EngineInterface, root: string) {
  const branch = await git($, root, ['rev-parse', '--abbrev-ref', 'HEAD'])
  if (!branch) return ''
  const top = await git($, root, ['rev-parse', '--show-toplevel'])
  const stat = (await git($, root, ['diff', '--stat', 'HEAD'])).split('\n').slice(-25).join('\n')
  const log = await git($, root, ['log', '--oneline', '-5'])
  const recent = await lastTurns($, 4, 700)
  const parts = [`Context from my Claude Code session in ${top.split('/').pop() ?? 'the repo'} on branch ${branch}.`]
  if (log) parts.push(`Recent commits:\n${log}`)
  if (stat) parts.push(`Uncommitted changes:\n${stat}`)
  if (recent.length) parts.push(`Last messages there:\n${recent.join('\n\n')}`)
  return parts.join('\n\n')
}

export const buildUrl = (route: Exclude<Route, 'code'>, text: string, context: string) => {
  let q = context ? `${text}\n\n---\n${context}` : text
  if (q.length > MAX_URL_PROMPT) q = clip(q, MAX_URL_PROMPT)
  return `claude://claude.ai/new?surface=${route}&q=${encodeURIComponent(q)}`
}

export const isWorkContext = (root: string, home: string, configDir: string | undefined) =>
  root.startsWith(`${home}/Development/hypnotic`) || (configDir ?? '').replace(/\/$/, '').endsWith('/.claude-work')

async function openInApp($: EngineInterface, url: string, dataDir: string) {
  const script = `${$.plugin.root}/scripts/open-in-claude.jxa`
  const r = await $.process.run(['osascript', '-l', 'JavaScript', script, dataDir, url], { timeoutMs: 40000 })
  if (r.exitCode !== 0) throw new Error(r.stderr.trim() || `osascript exited ${r.exitCode}`)
}

async function isOn($: EngineInterface) {
  return (await $.store.get('enabled').catch(() => undefined)) !== false
}

async function decide($: EngineInterface, e: PromptSubmitInput): Promise<{ drop: string } | string | undefined> {
  if (off || skips(e) || !(await isOn($))) return undefined
  if (KEEP_PREFIX.test(e.text)) return e.text.replace(KEEP_PREFIX, '')

  $.ui.status('Routing your prompt…')
  const verdict = await classify($, e.text).catch(() => undefined)
  $.ui.status(undefined)
  if (!verdict || verdict.route === 'code' || !verdict.sure) return undefined
  const route = verdict.route

  if (!auto) {
    const move = `Open in ${LABEL[route]}`
    const pick = await $.ui
      .ask(`This reads like a ${route === 'chat' ? 'conversation' : 'Cowork task'}. Move it to the Claude app?`, {
        options: [move, 'Keep here'],
        header: 'Route',
      })
      .catch(() => 'Keep here')
    if (pick !== move) return undefined
  }

  const root = await $.session.root()
  const home = (await $.env.get('HOME')) ?? ''
  const configDir = await $.env.get('CLAUDE_CONFIG_DIR')
  const work = isWorkContext(root, home, configDir)
  const busy = (await $.session.turns().catch(() => 0)) > 0
  const context = route === 'chat' && (verdict.repo || busy) ? await repoContext($, root) : ''
  const url = buildUrl(route, e.text, context)

  try {
    $.ui.status(`Opening ${LABEL[route]}…`)
    await openInApp($, url, work ? `${home}/${WORK_DATA_DIR}` : '')
  } catch (err) {
    $.ui.status(undefined)
    $.ui.toast(`Could not open ${LABEL[route]} (${err instanceof Error ? err.message : String(err)}). Kept here.`)
    return undefined
  }
  $.ui.status(undefined)
  $.ui.toast(`Moved to ${LABEL[route]} (${work ? 'Hypnotic' : 'default'} app). Start with "here:" to keep a prompt in Claude Code.`)
  return { drop: `moved to ${LABEL[route]}` }
}

export const register: Register = (on, options) => {
  auto = options?.mode !== 'ask'

  on('session.start', async ($, e, next) => {
    const result = await next(e)
    await $.command.register({ name: CMD, description: 'Turn prompt routing to chat and Cowork on or off' })
    await readSwitch($)
    $.clock.every(3000, () => {
      void readSwitch($)
    })
    return result
  })

  on('command.run', { command: CMD }, async $ => {
    const now = !(await isOn($))
    await $.store.set('enabled', now).catch(() => undefined)
    const text = now ? 'Prompt routing is on.' : 'Prompt routing is off. Every prompt stays here.'
    $.ui.toast(text)
    return { text }
  })

  on('prompt.submit', async ($, e, next) => {
    const moved = await decide($, e).catch(() => {
      $.ui.status(undefined)
      return undefined
    })
    if (moved === undefined) return next(e)
    if (typeof moved === 'string') return next({ ...e, text: moved })
    return moved
  })
}
