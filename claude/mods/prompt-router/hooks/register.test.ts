import { expect, test } from 'claude-code/testing'
import { buildUrl, isWorkContext, parseVerdict } from './register'

type Run = { argv: readonly string[] }

test('routes conversation to chat, work to Cowork, keeps code and short follow-ups here', { timeoutMs: 30000 }, async ($, on) => {
  let reply = '{"route":"chat","sure":true,"repo":false}'
  let modelCalls = 0
  const opened: string[][] = []
  const passed: string[] = []
  const toasts: string[] = []

  on('session.start', async ($, e) => ({ cwd: e.cwd }) as never)
  on('command.register', async () => ({ value: undefined }) as never)
  on('store.get', async () => ({ value: undefined }) as never)
  on('fs.exists', async () => ({ value: false }) as never)
  on('ui.status', async () => ({ value: undefined }) as never)
  on('ui.toast', async ($, e) => {
    toasts.push((e as { text: string }).text)
    return { value: undefined } as never
  })
  on('session.root', async () => ({ value: '/Users/rz/Development/hypnotic/yetify' }) as never)
  on('session.messages', async () => ({ value: [] }) as never)
  on('env.get', async ($, e) => ({ value: (e as { name: string }).name === 'HOME' ? '/Users/rz' : undefined }) as never)
  on('model.complete', async () => {
    modelCalls += 1
    return { value: { isAnswered: true, text: reply, usage: {} } } as never
  })
  on('process.run', async ($, e) => {
    const { argv } = e as Run
    if (argv[0] === 'osascript') opened.push([...argv])
    return { value: { exitCode: 0, stdout: argv[0] === 'git' ? 'main' : '', stderr: '' } } as never
  })
  on('prompt.submit', async ($, e) => {
    passed.push(e.text)
    return { text: e.text }
  })

  await $.session.start({ source: 'startup', cwd: '/tmp', surface: 'terminal', isInteractive: true } as never)
  const composer = { kind: 'composer' } as const

  const r1 = await $.prompt.submit({ text: 'what do you think is better, zustand or jotai for this?', origin: composer, wait: false } as never)
  expect((r1 as { drop?: string }).drop).toBe('moved to chat')
  expect(opened.length).toBe(1)
  expect(opened[0]?.[4]).toBe('/Users/rz/Library/Application Support/Claude-Work')
  expect(opened[0]?.[5] ?? '').toContain('claude://claude.ai/new?surface=chat&q=')
  expect(passed.length).toBe(0)

  reply = '{"route":"cowork","sure":true,"repo":false}'
  await $.prompt.submit({ text: 'draft the weekly status email for the client from my notes', origin: composer, wait: false } as never)
  expect(opened[1]?.[5] ?? '').toContain('surface=cowork')

  reply = '{"route":"code","sure":true,"repo":true}'
  await $.prompt.submit({ text: 'fix the failing login test please', origin: composer, wait: false } as never)
  expect(passed).toEqual(['fix the failing login test please'])

  reply = '{"route":"chat","sure":false,"repo":false}'
  await $.prompt.submit({ text: 'hmm not sure about this approach', origin: composer, wait: false } as never)
  expect(passed.length).toBe(2)

  const calls = modelCalls
  await $.prompt.submit({ text: 'yes go', origin: composer, wait: false } as never)
  await $.prompt.submit({ text: '/review the branch now', origin: composer, wait: false } as never)
  await $.prompt.submit({ text: 'here: what do you think of this naming?', origin: composer, wait: false } as never)
  expect(modelCalls).toBe(calls)
  expect(passed.at(-1)).toBe('what do you think of this naming?')
  expect(opened.length).toBe(2)
})

test('falls back to keeping the prompt when the app cannot open', async ($, on) => {
  const passed: string[] = []
  const toasts: string[] = []
  on('session.start', async ($, e) => ({ cwd: e.cwd }) as never)
  on('command.register', async () => ({ value: undefined }) as never)
  on('store.get', async () => ({ value: undefined }) as never)
  on('fs.exists', async () => ({ value: false }) as never)
  on('ui.status', async () => ({ value: undefined }) as never)
  on('ui.toast', async ($, e) => {
    toasts.push((e as { text: string }).text)
    return { value: undefined } as never
  })
  on('session.root', async () => ({ value: '/Users/rz/Development/obraxray/app' }) as never)
  on('session.messages', async () => ({ value: [] }) as never)
  on('env.get', async () => ({ value: '/Users/rz' }) as never)
  on('model.complete', async () => ({ value: { isAnswered: true, text: '{"route":"chat","sure":true,"repo":false}', usage: {} } }) as never)
  on('process.run', async () => ({ value: { exitCode: 1, stdout: '', stderr: 'Claude did not start' } }) as never)
  on('prompt.submit', async ($, e) => {
    passed.push(e.text)
    return { text: e.text }
  })
  await $.session.start({ source: 'startup', cwd: '/tmp', surface: 'terminal', isInteractive: true } as never)
  await $.prompt.submit({ text: 'explain the difference between RSC and SSR to me', origin: { kind: 'composer' }, wait: false } as never)
  expect(passed.length).toBe(1)
  expect(toasts.at(-1) ?? '').toContain('Kept here')
})

test('helpers', async () => {
  expect(parseVerdict('```json\n{"route":"cowork","sure":true,"repo":false}\n```')).toEqual({ route: 'cowork', sure: true, repo: false })
  expect(parseVerdict('{"route":"elsewhere"}')).toBe(undefined)
  expect(isWorkContext('/Users/rz/Development/hypnotic/tandem', '/Users/rz', undefined)).toBe(true)
  expect(isWorkContext('/tmp/wt', '/Users/rz', '/Users/rz/.claude-work')).toBe(true)
  expect(isWorkContext('/Users/rz/Development/obraxray', '/Users/rz', '/Users/rz/.claude-obraxray')).toBe(false)
  expect(buildUrl('chat', 'a b', 'ctx')).toBe(`claude://claude.ai/new?surface=chat&q=${encodeURIComponent('a b\n\n---\nctx')}`)
})
