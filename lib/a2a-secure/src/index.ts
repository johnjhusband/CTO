/**
 * @cto/a2a-secure — Mandatory encrypted A2A communication layer.
 *
 * No unencrypted path exists. Every message is signed (JWS) and encrypted (JWE).
 * Sender identity verified against contacts list. Roles (command/inform) enforced.
 */

export { generateKeyPair, loadKeyPair, loadKeyPairFromDisk, saveKeyPair, importPublicKey } from './keys.js';
export { ContactsList } from './contacts.js';
export { signMessage, verifyMessage, extractKeyId } from './sign.js';
export { encryptMessage, decryptMessage } from './encrypt.js';
export { SecureChannel } from './secure-channel.js';

export type { KeyPair, ExportedKeyPair } from './keys.js';
export type { Contact, ContactRole, ContactsFile, ResolvedContact } from './contacts.js';
export type { SealedMessage, OpenedMessage } from './secure-channel.js';
