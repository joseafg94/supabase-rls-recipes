import { mkdtempSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { resolve } from 'node:path'
import { scanDirectory } from './scan-secrets.mjs'

const fixture = mkdtempSync(resolve(tmpdir(), 'rls-secret-scan-'))

try {
  writeFileSync(resolve(fixture, 'safe.txt'), 'no credential here')
  if (scanDirectory(fixture).length !== 0) throw new Error('Scanner rejected a safe text file')

  const fakeSecret = ['sb', 'secret', 'AUDITFIXTURE0123456789'].join('_')
  writeFileSync(resolve(fixture, 'unusual-extension.txt'), fakeSecret)
  const findings = scanDirectory(fixture)
  if (findings.length !== 1 || !findings[0].includes('unusual-extension.txt')) {
    throw new Error('Scanner missed a privileged value in an arbitrary text file')
  }

  console.log('Privileged credential scanner regression passed')
} finally {
  rmSync(fixture, { recursive: true, force: true })
}
