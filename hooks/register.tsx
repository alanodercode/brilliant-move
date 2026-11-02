import type { EngineInterface, Register } from 'claude-code'

const FOLDER = 'Movies/Brilliant Moves' // under $HOME, created on first start
const MAX_SIZE = 420 // square window; other formats get letterboxed
const TOOL = 'mcp__brilliant-move__brilliant_move'

const RULE = `Play one of the user's edits as a reward — the "!!" of chess analysis. Call it ONLY when the user's own latest message contains a genuinely brilliant move: a non-obvious insight, a reframe that makes the problem smaller, leverage that removes whole chunks of work, or a decision a top operator would make. Not for routine requests, plain instructions, good-enough ideas, or your own work. Be stingy: about one in ten of their ideas at most — the anticipation is the point, and a wrong "!!" devalues every later one. Never call it twice in one turn. When you call it, open your reply with one line: "!! Brilliant Move — <why, in their terms, in one sentence>".`

// Centered square over the window bounds "x1, y1, x2, y2".
export function placeOver(bounds: string) {
  const [x1, y1, x2, y2] = bounds.split(',').map(s => parseInt(s, 10))
  const size = Math.min(MAX_SIZE, Math.round((y2 - y1) * 0.8), Math.round((x2 - x1) * 0.8))
  return { size, left: Math.round((x1 + x2 - size) / 2), top: Math.round((y1 + y2 - size) / 2) }
}

export const register: Register = on => {
  let isPlaying = false

  on('session.start', async ($, e, next) => {
    await $.tool.register({
      name: 'brilliant_move',
      description: RULE,
      inputSchema: {
        type: 'object',
        properties: { why: { type: 'string', description: 'One sentence: what makes the move brilliant' } },
        required: ['why'],
      },
      isDeferred: false,
    })
    // Folder for the edits, then pull new ones from the Photos album "Brilliant Moves" in the background.
    void (async () => {
      await $.process.run(['mkdir', '-p', await folder($)])
      for await (const _ of $.process.spawn({ argv: [`${$.plugin.root}/player/photos-sync`] })) {
        // runs until the sync is done
      }
    })().catch(() => {})
    return next(e)
  })

  on('tool.call', { tool: TOOL }, async $ => {
    if (!isPlaying) {
      isPlaying = true
      void play($).catch(() => {}).finally(() => {
        isPlaying = false
      })
    }
    return { result: 'Edit is playing.' }
  })
}

async function folder($: EngineInterface) {
  return `${(await $.env.get('HOME')) ?? ''}/${FOLDER}`
}

async function play($: EngineInterface) {
  const dir = await folder($)
  const clips = (await $.fs.list(dir)).filter(f => f.kind === 'file' && /\.(mp4|mov|m4v)$/i.test(f.name))
  if (!clips.length) {
    $.ui.toast(`Brilliant move! Drop some edits into ~/${FOLDER} to get a treat next time.`)
    return
  }
  const clip = clips[Math.floor(Math.random() * clips.length)]

  // ponytail: front window of Terminal, else iTerm2, else mid-screen. With both open, Terminal wins;
  // asking which app is frontmost needs System Events + Accessibility, add if people mix the two.
  let bounds = ''
  for (const app of ['Terminal', 'iTerm2']) {
    const r = await $.process.run(['osascript', '-e',
      `if application "${app}" is running then tell application "${app}" to get bounds of front window`])
    if (r.exitCode === 0 && r.stdout.split(',').length === 4) { bounds = r.stdout; break }
  }
  if (!bounds) {
    const r = await $.process.run(['osascript', '-e', 'tell application "Finder" to get bounds of window of desktop'])
    bounds = r.exitCode === 0 ? r.stdout : '0, 0, 1512, 982'
  }
  const { size, left, top } = placeOver(bounds)

  // Native player (player/edit-player.swift): plays once, fades in/out, click-through, never takes focus.
  const player = $.process.spawn({
    argv: [`${$.plugin.root}/player/edit-player`, `${dir}/${clip.name}`, String(left), String(top), String(size)],
  })
  for await (const _ of player) {
    // runs until the clip ends
  }
}
