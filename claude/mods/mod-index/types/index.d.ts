export type ModCommand = { name: string; description: string }

export type ModInfo = {
  id: string
  name: string
  version: string
  description: string
  when: string
  commands: ModCommand[]
}

export type ModIndex = {
  isScanned: boolean
  profile: string
  cwd: string
  mods: ModInfo[]
  error: string
}

declare module 'claude-code' {
  interface PluginState {
    'mod-index': { index: Shaped<ModIndex> }
  }
}
