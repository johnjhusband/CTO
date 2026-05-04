/**
 * Client-side crypto for the chat UI.
 * Signs outgoing messages with John's private key.
 * Verifies incoming messages from CTO.
 * Encrypts/decrypts using JWE.
 */

import * as jose from 'jose';

const STORAGE_KEY = 'cto-chat-keys';

export interface StoredKeys {
  publicKey: string;   // JWK JSON
  privateKey: string;  // JWK JSON
  keyId: string;
}

/**
 * Generate a new key pair for John and store in localStorage.
 */
export async function generateAndStoreKeys(): Promise<StoredKeys> {
  const { publicKey, privateKey } = await jose.generateKeyPair('EdDSA', {
    crv: 'Ed25519',
    extractable: true,
  });

  const publicKeyJwk = await jose.exportJWK(publicKey);
  const privateKeyJwk = await jose.exportJWK(privateKey);

  const keyId = 'john-' + crypto.randomUUID().slice(0, 8);
  publicKeyJwk.kid = keyId;
  privateKeyJwk.kid = keyId;

  const stored: StoredKeys = {
    publicKey: JSON.stringify(publicKeyJwk),
    privateKey: JSON.stringify(privateKeyJwk),
    keyId,
  };

  localStorage.setItem(STORAGE_KEY, JSON.stringify(stored));
  return stored;
}

/**
 * Load keys from localStorage.
 */
export function loadStoredKeys(): StoredKeys | null {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return null;
  return JSON.parse(raw);
}

/**
 * Sign and encrypt a message for CTO.
 */
export async function sealMessage(
  message: string,
  senderPrivateKeyStr: string,
  senderKeyId: string,
  recipientPublicKeyStr: string
): Promise<string> {
  const senderPrivateKey = await jose.importJWK(JSON.parse(senderPrivateKeyStr), 'EdDSA');
  const recipientPublicKey = await jose.importJWK(JSON.parse(recipientPublicKeyStr), 'EdDSA');

  // Sign
  const encoder = new TextEncoder();
  const jws = await new jose.CompactSign(encoder.encode(message))
    .setProtectedHeader({ alg: 'EdDSA', kid: senderKeyId, typ: 'a2a-secure+jws' })
    .sign(senderPrivateKey);

  // Encrypt
  const jwe = await new jose.CompactEncrypt(encoder.encode(jws))
    .setProtectedHeader({ alg: 'ECDH-ES', enc: 'A256GCM', typ: 'a2a-secure+jwe' })
    .encrypt(recipientPublicKey);

  return jwe;
}

/**
 * Decrypt and verify a message from CTO.
 */
export async function openMessage(
  jwe: string,
  receiverPrivateKeyStr: string,
  senderPublicKeyStr: string
): Promise<{ payload: string; kid: string }> {
  const receiverPrivateKey = await jose.importJWK(JSON.parse(receiverPrivateKeyStr), 'EdDSA');
  const senderPublicKey = await jose.importJWK(JSON.parse(senderPublicKeyStr), 'EdDSA');

  // Decrypt
  const { plaintext } = await jose.compactDecrypt(jwe, receiverPrivateKey);
  const decoder = new TextDecoder();
  const jws = decoder.decode(plaintext);

  // Verify
  const { payload, protectedHeader } = await jose.compactVerify(jws, senderPublicKey);
  return {
    payload: decoder.decode(payload),
    kid: protectedHeader.kid ?? 'unknown',
  };
}
