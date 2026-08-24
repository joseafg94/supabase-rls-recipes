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

const aliceId = '00000000-0000-4000-8000-000000000001'
const bobId = '00000000-0000-4000-8000-000000000002'
const orgA = '10000000-0000-4000-8000-000000000001'
const orgB = '10000000-0000-4000-8000-000000000002'
const bucket = 'storage-recipe-private'
const otherBucket = 'storage-recipe-other'
const alicePath = `${orgA}/${aliceId}/alice.txt`
const bobPath = `${orgB}/${bobId}/bob.txt`
const forgedTenantPath = `${orgB}/${aliceId}/forged.txt`
const aliceToBobPath = `${orgB}/${bobId}/cross.txt`

const pathUrl = (value) => value.split('/').map(encodeURIComponent).join('/')
const userHeaders = (sub) => ({
  apikey: publishableKey,
  authorization: `Bearer ${userToken(sub)}`,
})
const adminHeaders = { apikey: secretKey }
let assertions = 0

function ok(condition, message) {
  if (!condition) throw new Error(message)
  assertions += 1
}

async function request(url, options = {}) {
  return fetch(url, options)
}

async function createBucket(id) {
  const response = await request(`${apiUrl}/storage/v1/bucket`, {
    method: 'POST',
    headers: { ...adminHeaders, 'content-type': 'application/json' },
    body: JSON.stringify({ id, name: id, public: false }),
  })
  ok(response.ok, `trusted setup could not create bucket ${id}: ${response.status}`)
}

async function upload(id, objectPath, headers, content, upsert = false) {
  return request(`${apiUrl}/storage/v1/object/${encodeURIComponent(id)}/${pathUrl(objectPath)}`, {
    method: 'POST',
    headers: {
      ...headers,
      'content-type': 'text/plain',
      ...(upsert ? { 'x-upsert': 'true' } : {}),
    },
    body: content,
  })
}

async function update(id, objectPath, headers, content) {
  return request(`${apiUrl}/storage/v1/object/${encodeURIComponent(id)}/${pathUrl(objectPath)}`, {
    method: 'PUT',
    headers: { ...headers, 'content-type': 'text/plain' },
    body: content,
  })
}

async function download(id, objectPath, headers) {
  return request(`${apiUrl}/storage/v1/object/authenticated/${encodeURIComponent(id)}/${pathUrl(objectPath)}`, { headers })
}

async function list(id, headers, prefix = '') {
  return request(`${apiUrl}/storage/v1/object/list/${encodeURIComponent(id)}`, {
    method: 'POST',
    headers: { ...headers, 'content-type': 'application/json' },
    body: JSON.stringify({ prefix, limit: 100, offset: 0, sortBy: { column: 'name', order: 'asc' } }),
  })
}

async function remove(id, objectPath, headers) {
  return request(`${apiUrl}/storage/v1/object/${encodeURIComponent(id)}/${pathUrl(objectPath)}`, {
    method: 'DELETE',
    headers,
  })
}

async function cleanup() {
  for (const objectPath of [alicePath, bobPath, forgedTenantPath, aliceToBobPath]) {
    await remove(bucket, objectPath, adminHeaders).catch(() => undefined)
  }
  for (const id of [bucket, otherBucket]) {
    await request(`${apiUrl}/storage/v1/bucket/${encodeURIComponent(id)}`, {
      method: 'DELETE',
      headers: adminHeaders,
    }).catch(() => undefined)
  }
}

try {
  await createBucket(bucket)
  await createBucket(otherBucket)

  ok((await upload(bucket, alicePath, userHeaders(aliceId), 'alice-v1')).ok, 'Alice upload to Alice/Org A path failed')
  ok((await upload(bucket, bobPath, userHeaders(bobId), 'bob-v1')).ok, 'Bob upload to Bob/Org B path failed')
  ok(!(await upload(bucket, aliceToBobPath, userHeaders(aliceId), 'cross')).ok, '[deny:upload] Alice uploaded to Bob path')
  ok(!(await upload(bucket, forgedTenantPath, userHeaders(aliceId), 'forged')).ok, 'Alice forged Org B path')
  ok(!(await upload(otherBucket, alicePath, userHeaders(aliceId), 'wrong-bucket')).ok, 'Alice escaped bucket scope')

  const aliceList = await list(bucket, userHeaders(aliceId), `${orgA}/${aliceId}`)
  ok(aliceList.ok, 'Alice list request failed')
  const aliceObjects = await aliceList.json()
  ok(aliceObjects.length === 1 && aliceObjects[0].name === 'alice.txt', 'Alice list did not return only her object')
  const aliceCrossList = await list(bucket, userHeaders(aliceId), `${orgB}/${bobId}`)
  ok(aliceCrossList.ok && (await aliceCrossList.json()).length === 0, '[deny:list] Alice listed Bob path')

  const bobList = await list(bucket, userHeaders(bobId), `${orgB}/${bobId}`)
  ok(bobList.ok, 'Bob list request failed')
  const bobObjects = await bobList.json()
  ok(bobObjects.length === 1 && bobObjects[0].name === 'bob.txt', 'Bob list did not return only his object')

  const aliceDownload = await download(bucket, alicePath, userHeaders(aliceId))
  ok(aliceDownload.ok && (await aliceDownload.text()) === 'alice-v1', 'Alice could not download her object')
  ok(!(await download(bucket, bobPath, userHeaders(aliceId))).ok, '[deny:read] Alice downloaded Bob object')
  const bobDownload = await download(bucket, bobPath, userHeaders(bobId))
  ok(bobDownload.ok && (await bobDownload.text()) === 'bob-v1', 'Bob could not download his object')
  ok(!(await download(bucket, alicePath, { apikey: publishableKey })).ok, 'Anonymous downloaded private object')
  const anonymousList = await list(bucket, { apikey: publishableKey }, `${orgA}/${aliceId}`)
  ok(anonymousList.ok && (await anonymousList.json()).length === 0, 'Anonymous list did not return an empty result')

  ok((await update(bucket, alicePath, userHeaders(aliceId), 'alice-update')).ok, 'Alice UPDATE failed')
  const updated = await download(bucket, alicePath, userHeaders(aliceId))
  ok(updated.ok && (await updated.text()) === 'alice-update', 'Alice UPDATE content mismatch')
  ok(!(await update(bucket, bobPath, userHeaders(aliceId), 'cross-update')).ok, '[deny:update] Alice updated Bob object')
  ok((await upload(bucket, alicePath, userHeaders(aliceId), 'alice-upsert', true)).ok, 'Alice upsert failed')
  const upserted = await download(bucket, alicePath, userHeaders(aliceId))
  ok(upserted.ok && (await upserted.text()) === 'alice-upsert', 'Alice upsert content mismatch')
  ok(!(await upload(bucket, bobPath, userHeaders(aliceId), 'cross-upsert', true)).ok, '[deny:upsert] Alice upserted Bob object')

  ok(!(await remove(bucket, bobPath, userHeaders(aliceId))).ok, '[deny:delete] Alice deleted Bob object')
  ok((await remove(bucket, alicePath, userHeaders(aliceId))).ok, 'Alice could not delete her object')
  ok((await remove(bucket, bobPath, userHeaders(bobId))).ok, 'Bob could not delete his object')

  const finalList = await list(bucket, adminHeaders)
  ok(finalList.ok && (await finalList.json()).length === 0, 'Storage final state is not empty')

  console.log(`Storage API assertions passed: ${assertions}`)
} finally {
  await cleanup()
}
