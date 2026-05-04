/**
 * Message signing — proves who sent the message.
 * Uses JWS (JSON Web Signature) with Ed25519.
 */

import * as jose from 'jose';

/**
 * Sign a message with the sender's private key.
 * Returns a compact JWS string.
 */
export async function signMessage(
  payload: string,
  privateKey: jose.KeyLike,
  keyId: string
): Promise<string> {
  const encoder = new TextEncoder();

  const jws = await new jose.CompactSign(encoder.encode(payload))
    .setProtectedHeader({
      alg: 'EdDSA',
      kid: keyId,
      typ: 'a2a-secure+jws',
    })
    .sign(privateKey);

  return jws;
}

/**
 * Verify a signed message and extract the payload.
 * Returns the sender's key ID and the original payload.
 * Throws if signature is invalid.
 */
export async function verifyMessage(
  jws: string,
  publicKey: jose.KeyLike
): Promise<{ payload: string; kid: string }> {
  const { payload, protectedHeader } = await jose.compactVerify(jws, publicKey);

  const decoder = new TextDecoder();
  return {
    payload: decoder.decode(payload),
    kid: protectedHeader.kid ?? 'unknown',
  };
}

/**
 * Extract the key ID from a JWS without verifying (for contact lookup).
 * Use this to find which public key to verify against.
 */
export function extractKeyId(jws: string): string | null {
  try {
    const header = jose.decodeProtectedHeader(jws);
    return header.kid ?? null;
  } catch {
    return null;
  }
}
