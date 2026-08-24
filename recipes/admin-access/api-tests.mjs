import { createHmac } from 'node:crypto'
import { execFileSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const recipeDir = dirname(fileURLToPath(import.meta.url))
const rootDir = resolve(recipeDir, '../..')
const supabaseCli = resolve(rootDir, 'node_modules/supabase/dist/supabase.js')

function cli(args) {
  return execFileSync(process.execPath, [supabaseCli, ...args], {
    cwd: rootDir,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  })
}

for (const file of ['schema.sql', 'policies.sql', 'seed.sql']) {
  const statements = readFileSync(resolve(recipeDir, file), 'utf8').split(/;\s*(?:\r?\n|$)/).filter((sql) => sql.trim())
  for (const sql of statements) cli(['db', 'query', '--local', `${sql};`])
}

const status = JSON.parse(cli(['status', '-o', 'json']))
const apiUrl = status.API_URL
const publishableKey = status.PUBLISHABLE_KEY ?? status.ANON_KEY
const secretKey = status.SECRET_KEY
const jwtSecret = status.JWT_SECRET

if (!apiUrl || !publishableKey || !secretKey || !jwtSecret) {
  throw new Error('Local Supabase status omitted required runtime values')
}

function encodeJwtPart(value) {
  return Buffer.from(JSON.stringify(value)).toString('base64url')
}

function userToken(sub) {
  const now = Math.floor(Date.now() / 1000)
  const unsigned = `${encodeJwtPart({ alg: 'HS256', typ: 'JWT' })}.${encodeJwtPart({
    aud: 'authenticated',
    exp: now + 3600,
    iat: now,
    iss: 'supabase-demo',
    role: 'authenticated',
    sub,
  })}`
  const signature = createHmac('sha256', jwtSecret).update(unsigned).digest('base64url')
  return `${unsigned}.${signature}`
}

const aliceId = '00000000-0000-0000-0000-000000000001'
const bobId = '00000000-0000-0000-0000-000000000002'
const endpoint = `${apiUrl}/rest/v1/admin_boundary_records?select=id,owner_id,body&order=id`
let assertions = 0

function ok(condition, message) {
  if (!condition) throw new Error(message)
  assertions += 1
}

function userHeaders(sub) {
  return {
    apikey: publishableKey,
    authorization: `Bearer ${userToken(sub)}`,
  }
}

async function rows(headers) {
  const response = await fetch(endpoint, { headers })
  const body = await response.json()
  ok(response.ok, `Data API read failed: ${response.status}`)
  return body
}

const aliceRows = await rows(userHeaders(aliceId))
ok(aliceRows.length === 1 && aliceRows[0].owner_id === aliceId, 'Alice response crossed the owner boundary')

const bobRows = await rows(userHeaders(bobId))
ok(bobRows.length === 1 && bobRows[0].owner_id === bobId, 'Bob response crossed the owner boundary')

const crossUpdate = await fetch(
  `${apiUrl}/rest/v1/admin_boundary_records?id=eq.80000000-0000-0000-0000-000000000002`,
  {
    method: 'PATCH',
    headers: {
      ...userHeaders(aliceId),
      'content-type': 'application/json',
      prefer: 'return=representation',
    },
    body: JSON.stringify({ body: 'forged' }),
  },
)
ok(crossUpdate.ok, 'Alice cross-owner update did not return a zero-row result')
ok((await crossUpdate.json()).length === 0, 'Alice changed Bob record')

const backendRows = await rows({ apikey: secretKey })
ok(
  backendRows.length === 2
    && backendRows.some((row) => row.owner_id === aliceId)
    && backendRows.some((row) => row.owner_id === bobId && row.body === 'Bob private record'),
  'Trusted backend credential did not demonstrate its explicit RLS bypass boundary',
)

console.log(`Admin boundary API assertions passed: ${assertions}`)
