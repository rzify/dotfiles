import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { ModCommand, ModIndex, ModInfo } from '../types'
import { discover } from './discover'

const PANE = 'mods'
const TITLE = 'Mods'
const COMMAND = 'mods'
const MIN_COLUMNS = 16
const RULE = '─'

const COLOR = {
  title: '#ffffff',
  body: '#e6e6e6',
  secondary: '#888888',
  dim: '#555555',
  hairline: '#333333',
  hairlineSoft: '#1a1a1a',
  selected: '#0f0f0f',
  error: '#e5534b',
} as const

const EMPTY: ModIndex = { isScanned: false, profile: '', cwd: '', mods: [], error: '' }

const index = atom({ plugin: 'mod-index', key: 'index' } as const, EMPTY, { shape: 'index-1' })

function cut(text: string, width: number): string {
  if (width <= 0) return ''
  return text.length <= width ? text : `${text.slice(0, Math.max(0, width - 1))}…`
}

export function wrapLines(text: string, width: number): string[] {
  const words = text.split(/\s+/).filter(Boolean)
  const lines: string[] = []
  let line = ''
  for (const word of words) {
    const chunks = word.length > width ? word.match(new RegExp(`.{1,${width}}`, 'g')) ?? [word] : [word]
    for (const chunk of chunks) {
      const next = line ? `${line} ${chunk}` : chunk
      if (next.length <= width) {
        line = next
      } else {
        if (line) lines.push(line)
        line = chunk
      }
    }
  }
  return line ? [...lines, line] : lines
}

const plural = (n: number): string => (n === 1 ? '1 mod' : `${n} mods`)

async function currentCwd($: EngineInterface): Promise<string> {
  try {
    return await $.session.cwd()
  } catch {
    return (await read($, index)).cwd
  }
}

async function rescan($: EngineInterface, cwd: string): Promise<void> {
  try {
    const found = await discover($, cwd)
    await update($, index, () => found)
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    await update($, index, old => ({ ...old, isScanned: true, cwd, error: `Falha ao procurar mods: ${message}` }))
  }
}

async function dockPane($: EngineInterface): Promise<void> {
  const opened = await $.ui.open({ id: PANE, title: TITLE })
  if (!opened.isPlaced) $.ui.log(`mod-index: painel em espera (${opened.reason})`, { to: 'debug' })
}

async function focusPane($: EngineInterface): Promise<void> {
  const opened = await $.ui.open({ id: PANE, title: TITLE, focus: true })
  if (!opened.isPlaced) $.ui.log(`mod-index: painel em espera (${opened.reason})`, { to: 'debug' })
  await rescan($, await currentCwd($))
}

async function isPaneOpen($: EngineInterface): Promise<boolean> {
  try {
    return (await $.ui.panes()).some(pane => pane.id === PANE)
  } catch {
    return false
  }
}

async function fillCommand($: EngineInterface, name: string): Promise<void> {
  const filled = await $.prompt.fill({ text: `/${name} `, mode: 'replace' })
  if (!filled.isFilled) $.ui.toast(`Não foi possível escrever /${name} no prompt.`)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: COMMAND,
      description: 'Mostrar ou esconder o painel com os mods ativos neste perfil',
      immediate: true,
    })
    await rescan($, e.cwd)
    void dockPane($).catch(err => $.ui.log(`mod-index: ${String(err)}`, { to: 'debug' }))
    return next(e)
  })

  on('command.run', { command: COMMAND }, async $ => {
    if (await isPaneOpen($)) {
      await $.ui.close({ id: PANE })
      return { text: 'Painel Mods fechado.' }
    }
    void focusPane($).catch(err => $.ui.log(`mod-index: ${String(err)}`, { to: 'debug' }))
    return { text: 'Painel Mods aberto.' }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text, Button } = $.ui.resolve(e)
    const cols = Math.max(MIN_COLUMNS, e.props.bodyColumns)
    const state = await read($, index)

    const line = (text: string, color: string, extra: { bold?: true } = {}) => (
      <Text color={color} wrap="truncate-end" {...extra}>
        {cut(text, cols)}
      </Text>
    )

    const commandRow = (mod: ModInfo, command: ModCommand) => {
      const head = cut(`/${command.name}`, cols)
      const tail = command.description ? cut(` — ${command.description}`, cols - head.length) : ''
      return (
        <Box key={`row:${mod.id}:${command.name}`} hover={{ backgroundColor: COLOR.selected }}>
          <Button key={`cmd:${mod.id}:${command.name}`} plain onPress={() => fillCommand($, command.name)}>
            <Text color={COLOR.body}>{head}</Text>
            {tail ? <Text color={COLOR.secondary}>{tail}</Text> : ''}
          </Button>
        </Box>
      )
    }

    const section = (mod: ModInfo, position: number) => {
      const name = cut(mod.name, cols)
      const version = mod.version ? cut(` ${mod.version}`, cols - name.length) : ''
      const label = 'Quando corre: '
      return (
        <Box key={`mod:${mod.id}`} flexDirection="column" width={cols}>
          {position > 0 ? line(RULE.repeat(cols), COLOR.hairlineSoft) : null}
          <Box flexDirection="row">
            <Text bold color={COLOR.title} wrap="truncate-end">
              {name}
            </Text>
            {version ? (
              <Text color={COLOR.dim} wrap="truncate-end">
                {version}
              </Text>
            ) : null}
          </Box>
          {wrapLines(mod.description, cols).map(text => line(text, COLOR.secondary))}
          {mod.when ? (
            <Box flexDirection="row">
              <Text color={COLOR.dim} wrap="truncate-end">
                {cut(label, cols)}
              </Text>
              <Text color={COLOR.body} wrap="truncate-end">
                {cut(mod.when, cols - Math.min(cols, label.length))}
              </Text>
            </Box>
          ) : null}
          {mod.commands.map(command => commandRow(mod, command))}
        </Box>
      )
    }

    const note = (text: string) => wrapLines(text, cols).map(part => line(part, COLOR.secondary))
    const body = !state.isScanned
      ? note('A procurar mods…')
      : state.mods.length === 0 && !state.error
        ? note('Nenhum mod instalado neste perfil.')
        : state.mods.map(section)

    const footer = `${plural(state.mods.length)} · perfil ${state.profile || '—'}`

    return (
      <Box flexDirection="column" width={cols} rowGap={0}>
        {state.error ? wrapLines(state.error, cols).map(text => line(text, COLOR.error)) : null}
        {body}
        {line(RULE.repeat(cols), COLOR.hairline)}
        {state.isScanned ? line(footer, COLOR.dim) : null}
      </Box>
    )
  })
}
