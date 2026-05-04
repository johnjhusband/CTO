/**
 * SecureChannel — the high-level API that combines signing, encryption,
 * verification, and decryption into a single interface.
 *
 * Usage:
 *   const channel = new SecureChannel(myKeys, contacts);
 *
 *   // Send to CFO
 *   const encrypted = await channel.seal("Hello CFO", "cfo");
 *
 *   // Receive from someone
 *   const { payload, sender, role } = await channel.open(encryptedMessage);
 */

import { signMessage, verifyMessage, extractKeyId } from './sign.js';
import { encryptMessage, decryptMessage } from './encrypt.js';
import { ContactsList, type ContactRole } from './contacts.js';
import { loadKeyPair, type KeyPair } from './keys.js';

export interface SealedMessage {
  jwe: string;      // The encrypted envelope
  recipient: string; // Who it's for
}

export interface OpenedMessage {
  payload: string;    // The decrypted, verified content
  senderId: string;   // Who sent it (from contacts list)
  role: ContactRole;  // Their role (command or inform)
}

export class SecureChannel {
  private myKeys: KeyPair;
  private myKeyId: string;
  private contacts: ContactsList;

  constructor(myKeys: KeyPair, myKeyId: string, contacts: ContactsList) {
    this.myKeys = myKeys;
    this.myKeyId = myKeyId;
    this.contacts = contacts;
  }

  /**
   * Seal a message for a specific recipient.
   * Signs with our private key, encrypts with recipient's public key.
   */
  async seal(payload: string, recipientId: string): Promise<SealedMessage> {
    const recipient = this.contacts.getById(recipientId);
    if (!recipient) {
      throw new Error(`Unknown recipient: ${recipientId}`);
    }

    // Step 1: Sign with our private key
    const signed = await signMessage(payload, this.myKeys.privateKey, this.myKeyId);

    // Step 2: Encrypt with recipient's public key
    const jwe = await encryptMessage(signed, recipient.publicKey);

    return { jwe, recipient: recipientId };
  }

  /**
   * Open a received message.
   * Decrypts with our private key, verifies sender's signature.
   * Returns the payload, sender identity, and their role.
   * Throws if:
   *   - Decryption fails (not for us)
   *   - Signature invalid (tampered)
   *   - Sender unknown (not in contacts)
   */
  async open(jwe: string): Promise<OpenedMessage> {
    // Step 1: Decrypt with our private key
    const signed = await decryptMessage(jwe, this.myKeys.privateKey);

    // Step 2: Extract sender's key ID from JWS header
    const kid = extractKeyId(signed);
    if (!kid) {
      throw new Error('Message has no key ID — cannot identify sender');
    }

    // Step 3: Look up sender in contacts
    const sender = this.contacts.getByKeyId(kid);
    if (!sender) {
      throw new Error(`Unknown sender (kid: ${kid}) — not in contacts list. Rejected.`);
    }

    // Step 4: Verify signature with sender's public key
    const { payload } = await verifyMessage(signed, sender.publicKey);

    return {
      payload,
      senderId: sender.id,
      role: sender.role,
    };
  }

  /**
   * Check if a sender has command authority.
   */
  isCommand(message: OpenedMessage): boolean {
    return message.role === 'command';
  }

  /**
   * Check if a sender has inform authority.
   */
  isInform(message: OpenedMessage): boolean {
    return message.role === 'inform' || message.role === 'command'; // command implies inform
  }
}
