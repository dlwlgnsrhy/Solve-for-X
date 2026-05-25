import { describe, it } from 'vitest';
import { expect } from 'vitest';

describe('EncryptionService - Privacy Rules', () => {
  it('should not import fetch or network libraries in encryptionService.ts', () => {
    const fs = require('fs');
    const path = require('path');
    const servicePath = path.join(__dirname, '../lib/services/encryptionService.ts');
    const content = fs.readFileSync(servicePath, 'utf-8');
    expect(content).not.toMatch(/from\s+['"]fetch['"]|import\s+.*fetch\s*\(/);
    expect(content).toMatch(/@\/lib\/crypto\/aes-gcm/);
  });
});
