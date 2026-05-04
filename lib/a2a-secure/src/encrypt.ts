/**
 * Message encryption — ensures only the intended receiver can read it.
 * Uses JWE (JSON Web Encryption) with ECDH-ES.
 *
 * Note: Ed25519 keys are used for signing. For encryption, jose handles
 * the Ed25519→X25519 conversion internally when using ECDH-ES with OKP keys.
 * If that doesn't work, we generate separate X25519 keys for encryption.
 *
 * For v1: we use dir+A256GCM which is simpler — the sender generates
 * an ephemeral key agreement with the receiver's public key.
 */

import * as jose from 'jose';

/**
 * Encrypt a signed message for a specific receiver.
 * Takes a JWS string (already signed) and encrypts it.
 * Returns a compact JWE string.
 */
export async function encryptMessage(
  signedPayload: string,
  receiverPublicKey: jose.KeyLike
): Promise<string> {
  const encoder = new TextEncoder();

  const jwe = await new jose.CompactEncrypt(encoder.encode(signedPayload))
    .setProtectedHeader({
      alg: 'ECDH-ES',
      enc: 'A256GCM',
      typ: 'a2a-secure+jwe',
    })
    .encrypt(receiverPublicKey);

  return jwe;
}

/**
 * Decrypt a message with the receiver's private key.
 * Returns the inner JWS string (still needs signature verification).
 */
export async function decryptMessage(
  jwe: string,
  receiverPrivateKey: jose.KeyLike
): Promise<string> {
  const { plaintext } = await jose.compactDecrypt(jwe, receiverPrivateKey);
  const decoder = new TextDecoder();
  return decoder.decode(plaintext);
}
