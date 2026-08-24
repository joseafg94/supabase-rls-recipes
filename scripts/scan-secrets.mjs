import { readFileSync, readdirSync } from 'node:fs'
import { relative, resolve } from 'node:path'
import { pathToFileURL } from 'node:url'

const root = resolve(import.meta.dirname, '..')
const ignoredDirectories = new Set(['.git', 'node_modules'])
const ignoredRuntimeDirectories = new Set(['supabase/.branches', 'supabase/.temp'])
const patterns = [
  ['Supabase secret key', /sb_secret_[A-Za-z0-9_-]{16,}/g],
  ['JWT value', /eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}/g],
  ['privileged literal assignment', /\b(?:SERVICE_ROLE_KEY|SUPABASE_SECRET_KEY|JWT_SECRET)\s*[:=]\s*['"][^'"]+['"]/g],
]
export function scanDirectory(directory) {
  const findings = []

  function scan(currentDirectory) {
    for (const entry of readdirSync(currentDirectory, { withFileTypes: true })) {
      if (entry.isDirectory() && ignoredDirectories.has(entry.name)) continue
      const path = resolve(currentDirectory, entry.name)
      const relativePath = relative(directory, path).replaceAll('\\', '/')
      if (entry.isDirectory() && ignoredRuntimeDirectories.has(relativePath)) continue
      if (entry.isDirectory()) {
        scan(path)
      } else {
        const bytes = readFileSync(path)
        if (bytes.includes(0)) continue
        const source = bytes.toString('utf8')
        for (const [label, pattern] of patterns) {
          pattern.lastIndex = 0
          if (pattern.test(source)) findings.push(`${path.slice(directory.length + 1)}: ${label}`)
        }
      }
    }
  }

  scan(directory)
  return findings
}

if (process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url) {
  const target = process.argv[2] ? resolve(process.argv[2]) : root
  const findings = scanDirectory(target)
  if (findings.length) throw new Error(`Privileged credential scan failed:\n${findings.join('\n')}`)
  console.log('Privileged credential scan passed')
}
