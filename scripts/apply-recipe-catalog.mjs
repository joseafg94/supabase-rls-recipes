import { execFileSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const supabaseCli = resolve(root, 'node_modules/supabase/dist/supabase.js')
const recipes = [
  'user-owned-data',
  'organization-membership',
  'roles-and-permissions',
  'public-read-private-write',
  'multi-tenant-saas',
  'storage-isolation',
  'admin-access',
]

function cli(args) {
  execFileSync(process.execPath, [supabaseCli, ...args], { cwd: root, stdio: 'inherit' })
}

for (const recipe of recipes) {
  for (const file of ['schema.sql', 'policies.sql']) {
    const source = readFileSync(resolve(root, 'recipes', recipe, file), 'utf8')
    const statements = source.split(/;\s*(?:\r?\n|$)/).filter((sql) => sql.trim())
    for (const sql of statements) cli(['db', 'query', '--local', `${sql};`])
  }
}

console.log(`Applied audit catalog: ${recipes.length} recipes`)
