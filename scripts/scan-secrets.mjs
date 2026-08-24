import { readFileSync, readdirSync } from 'node:fs'
import { extname, resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const ignoredDirectories = new Set(['.git', 'node_modules', '.temp', '.branches'])
const textExtensions = new Set(['.json', '.md', '.mjs', '.sql', '.toml', '.yaml', '.yml', '.gitignore'])
const patterns = [
  ['Supabase secret key', /sb_secret_[A-Za-z0-9_-]{16,}/g],
  ['JWT value', /eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}/g],
  ['privileged literal assignment', /\b(?:SERVICE_ROLE_KEY|SUPABASE_SECRET_KEY|JWT_SECRET)\s*[:=]\s*['"][^'"]+['"]/g],
]
const findings = []

function scan(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (entry.isDirectory() && ignoredDirectories.has(entry.name)) continue
    const path = resolve(directory, entry.name)
    if (entry.isDirectory()) {
      scan(path)
    } else if (textExtensions.has(extname(entry.name)) || entry.name === '.gitignore') {
      const source = readFileSync(path, 'utf8')
      for (const [label, pattern] of patterns) {
        pattern.lastIndex = 0
        if (pattern.test(source)) findings.push(`${path.slice(root.length + 1)}: ${label}`)
      }
    }
  }
}

scan(root)
if (findings.length) throw new Error(`Privileged credential scan failed:\n${findings.join('\n')}`)
console.log('Privileged credential scan passed')

