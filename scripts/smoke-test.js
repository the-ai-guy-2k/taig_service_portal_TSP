#!/usr/bin/env node
/**
 * TSP route smoke test — used by CI and deployment runbook validation.
 * Usage: node scripts/smoke-test.js [baseUrl]
 * Default baseUrl: http://localhost:3000
 */

const http = require('http');

const baseUrl = process.argv[2] || 'http://localhost:3000';

const checks = [
  { path: '/health', contains: '"status":"ok"', label: 'Health endpoint' },
  { path: '/', contains: 'Technology that starts with your business problem', label: 'Home page' },
  { path: '/', contains: 'Nebula', label: 'Home Nebula section' },
  { path: '/about', contains: 'Start With The Problem', label: 'About page' },
  { path: '/services', contains: 'IT Support', label: 'Services page' },
  { path: '/contact', contains: 'Send a Message', label: 'Contact page' },
];

function fetch(path) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, baseUrl);
    http
      .get(url, (res) => {
        let body = '';
        res.on('data', (chunk) => {
          body += chunk;
        });
        res.on('end', () => {
          resolve({ statusCode: res.statusCode, body });
        });
      })
      .on('error', reject);
  });
}

async function run() {
  let failed = 0;

  for (const check of checks) {
    try {
      const { statusCode, body } = await fetch(check.path);
      if (statusCode !== 200) {
        console.error(`FAIL [${check.label}] ${check.path} — HTTP ${statusCode}`);
        failed += 1;
        continue;
      }
      if (!body.includes(check.contains)) {
        console.error(`FAIL [${check.label}] ${check.path} — missing "${check.contains}"`);
        failed += 1;
        continue;
      }
      console.log(`PASS [${check.label}] ${check.path}`);
    } catch (err) {
      console.error(`FAIL [${check.label}] ${check.path} — ${err.message}`);
      failed += 1;
    }
  }

  if (failed > 0) {
    console.error(`\n${failed} check(s) failed.`);
    process.exit(1);
  }

  console.log(`\nAll ${checks.length} smoke tests passed.`);
}

run();
