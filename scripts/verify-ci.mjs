import { execFileSync } from 'node:child_process'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const supabaseCli = resolve(root, 'node_modules/supabase/dist/supabase.js')
const recipeTests = [
  'recipes/user-owned-data/tests.sql',
  'recipes/organization-membership/tests.sql',
  'recipes/roles-and-permissions/tests.sql',
  'recipes/public-read-private-write/tests.sql',
  'recipes/multi-tenant-saas/tests.sql',
  'recipes/storage-isolation/tests.sql',
  'recipes/admin-access/tests.sql',
]

function run(executable, args) {
  execFileSync(executable, args, { cwd: root, stdio: 'inherit' })
}

const cli = (...args) => run(process.execPath, [supabaseCli, ...args])
const node = (script) => run(process.execPath, [resolve(root, script)])

node('scripts/verify-test-catalog.mjs')
node('scripts/scan-secrets.test.mjs')
cli('db', 'reset', '--local')
cli('db', 'lint', '--local', '--level', 'warning', '--fail-on', 'error')
cli('test', 'db', '--local')
cli('test', 'db', ...recipeTests, '--local')
cli('db', 'reset', '--local')
node('scripts/apply-recipe-catalog.mjs')
cli('test', 'db', 'scripts/security-catalog.test.sql', '--local')
cli('db', 'advisors', '--local', '--type', 'all', '--level', 'warn', '--fail-on', 'error')
cli('db', 'reset', '--local')
node('recipes/storage-isolation/api-tests.mjs')
cli('db', 'reset', '--local')
node('recipes/admin-access/api-tests.mjs')
node('scripts/scan-secrets.mjs')

console.log('Clean CI verification passed')
