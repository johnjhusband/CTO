/**
 * Key pair generation and management for A2A secure communication.
 *
 * Uses Ed25519 for signing (JWS) and X25519 for encryption (JWE).
 * Ed25519 keys are converted to X25519 for encryption operations.
 */

import * as jose from 'jose';
import { readFile, writeFile, mkdir } from 'fs/promises';
import { join } from 'path';

export interface KeyPair {
  publicKey: jose.KeyLike;
  privateKey: jose.KeyLike;
  publicKeyJwk: jose.JWK;
  privateKeyJwk: jose.JWK;
}

export interface ExportedKeyPair {
  publicKey: string;   // Base64url-encoded JWK
  privateKey: string;  // Base64url-encoded JWK
  id: string;          // Key identifier
}

/**
 * Generate a new Ed25519 key pair for signing.
 * The same key can derive X25519 for encryption via jose library.
 */
export async function generateKeyPair(id: string): Promise<ExportedKeyPair> {
  const { publicKey, privateKey } = await jose.generateKeyPair('EdDSA', {
    crv: 'Ed25519',
    extractable: true,
  });

  const publicKeyJwk = await jose.exportJWK(publicKey);
  const privateKeyJwk = await jose.exportJWK(privateKey);

  // Add key ID
  publicKeyJwk.kid = id;
  privateKeyJwk.kid = id;

  return {
    publicKey: JSON.stringify(publicKeyJwk),
    privateKey: JSON.stringify(privateKeyJwk),
    id,
  };
}

/**
 * Load key pair from JWK strings.
 */
export async function loadKeyPair(publicKeyStr: string, privateKeyStr: string): Promise<KeyPair> {
  const publicKeyJwk = JSON.parse(publicKeyStr) as jose.JWK;
  const privateKeyJwk = JSON.parse(privateKeyStr) as jose.JWK;

  const publicKey = await jose.importJWK(publicKeyJwk, 'EdDSA');
  const privateKey = await jose.importJWK(privateKeyJwk, 'EdDSA');

  return { publicKey, privateKey, publicKeyJwk, privateKeyJwk };
}

/**
 * Import a public key from JWK string (for contacts list).
 */
export async function importPublicKey(publicKeyStr: string): Promise<jose.KeyLike> {
  const jwk = JSON.parse(publicKeyStr) as jose.JWK;
  return await jose.importJWK(jwk, 'EdDSA') as jose.KeyLike;
}

/**
 * Save key pair to disk.
 */
export async function saveKeyPair(dir: string, keyPair: ExportedKeyPair): Promise<void> {
  await mkdir(dir, { recursive: true });
  await writeFile(join(dir, 'public.jwk'), keyPair.publicKey, { mode: 0o644 });
  await writeFile(join(dir, 'private.jwk'), keyPair.privateKey, { mode: 0o600 });
  await writeFile(join(dir, 'key-id.txt'), keyPair.id, { mode: 0o644 });
}

/**
 * Load key pair from disk.
 */
export async function loadKeyPairFromDisk(dir: string): Promise<ExportedKeyPair> {
  const publicKey = await readFile(join(dir, 'public.jwk'), 'utf-8');
  const privateKey = await readFile(join(dir, 'private.jwk'), 'utf-8');
  const id = await readFile(join(dir, 'key-id.txt'), 'utf-8');
  return { publicKey, privateKey, id: id.trim() };
}
