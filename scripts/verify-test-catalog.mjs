import { existsSync, readFileSync, readdirSync } from 'node:fs'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const catalog = {
  'user-owned-data': { operations: ['select', 'insert', 'update', 'delete'], sources: ['tests.sql'] },
  'organization-membership': { operations: ['select', 'insert', 'update', 'delete'], sources: ['tests.sql'] },
  'roles-and-permissions': { operations: ['select', 'insert', 'update', 'delete'], sources: ['tests.sql'] },
  'public-read-private-write': { operations: ['select', 'insert', 'update', 'delete'], sources: ['tests.sql'] },
  'multi-tenant-saas': { operations: ['select', 'insert', 'update', 'delete'], sources: ['tests.sql'] },
  'storage-isolation': { operations: ['list', 'read', 'upload', 'update', 'upsert', 'delete'], sources: ['api-tests.mjs'] },
  'admin-access': { operations: ['select', 'update'], sources: ['tests.sql'] },
}
const requiredFiles = ['README.md', 'schema.sql', 'policies.sql', 'seed.sql', 'tests.sql']
const recipeRoot = resolve(root, 'recipes')
const actualRecipes = readdirSync(recipeRoot, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort()
const expectedRecipes = Object.keys(catalog).sort()

if (actualRecipes.join('\n') !== expectedRecipes.join('\n')) {
  throw new Error(`Test catalog mismatch. Expected ${expectedRecipes.join(', ')}; found ${actualRecipes.join(', ')}`)
}

let operationCount = 0
for (const [recipe, entry] of Object.entries(catalog)) {
  const recipeDir = resolve(recipeRoot, recipe)
  for (const file of requiredFiles) {
    if (!existsSync(resolve(recipeDir, file))) throw new Error(`${recipe} is missing ${file}`)
  }
  const source = entry.sources.map((file) => readFileSync(resolve(recipeDir, file), 'utf8')).join('\n')
  for (const operation of entry.operations) {
    if (!source.includes(`[deny:${operation}]`)) throw new Error(`${recipe} lacks an explicit negative ${operation} assertion`)
    operationCount += 1
  }
}

console.log(`Negative test catalog passed: ${expectedRecipes.length} recipes, ${operationCount} operations`)

