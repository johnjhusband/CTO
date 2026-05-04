/**
 * Contacts list — each agent knows its trusted peers and their roles.
 * Like a person knowing their boss's face (public key) and role (command vs inform).
 */

import { readFile, writeFile } from 'fs/promises';
import { importPublicKey } from './keys.js';
import type { KeyLike } from 'jose';

export type ContactRole = 'command' | 'inform';

export interface Contact {
  publicKey: string;     // JWK string
  role: ContactRole;
  description: string;
}

export interface ContactsFile {
  contacts: Record<string, Contact>;
}

export interface ResolvedContact {
  id: string;
  publicKey: KeyLike;
  role: ContactRole;
  description: string;
}

export class ContactsList {
  private contacts: Map<string, ResolvedContact> = new Map();
  private keyToId: Map<string, string> = new Map(); // kid → contact id

  /**
   * Load contacts from a JSON file.
   */
  async loadFromFile(path: string): Promise<void> {
    const raw = await readFile(path, 'utf-8');
    const data: ContactsFile = JSON.parse(raw);

    for (const [id, contact] of Object.entries(data.contacts)) {
      const publicKey = await importPublicKey(contact.publicKey);
      const jwk = JSON.parse(contact.publicKey);

      this.contacts.set(id, {
        id,
        publicKey,
        role: contact.role,
        description: contact.description,
      });

      // Map key ID to contact ID for signature verification
      if (jwk.kid) {
        this.keyToId.set(jwk.kid, id);
      }
    }
  }

  /**
   * Look up a contact by their key ID (from JWS header).
   * Returns null if unknown — message should be rejected.
   */
  getByKeyId(kid: string): ResolvedContact | null {
    const contactId = this.keyToId.get(kid);
    if (!contactId) return null;
    return this.contacts.get(contactId) ?? null;
  }

  /**
   * Get a contact by their identity name.
   */
  getById(id: string): ResolvedContact | null {
    return this.contacts.get(id) ?? null;
  }

  /**
   * Check if a contact has command authority.
   */
  canCommand(kid: string): boolean {
    const contact = this.getByKeyId(kid);
    return contact?.role === 'command';
  }

  /**
   * Check if a contact has inform authority.
   */
  canInform(kid: string): boolean {
    const contact = this.getByKeyId(kid);
    return contact !== null; // Any known contact can inform
  }

  /**
   * List all contacts.
   */
  listAll(): ResolvedContact[] {
    return Array.from(this.contacts.values());
  }

  /**
   * Add a contact programmatically (for when CTO creates new agents).
   */
  addContact(id: string, publicKeyStr: string, role: ContactRole, description: string): void {
    // Will be resolved on next loadFromFile or can be resolved immediately
    const jwk = JSON.parse(publicKeyStr);
    if (jwk.kid) {
      this.keyToId.set(jwk.kid, id);
    }
    // Note: publicKey (KeyLike) not resolved here — call resolveAll() after adding
  }

  /**
   * Save contacts to a JSON file.
   */
  async saveToFile(path: string): Promise<void> {
    const data: ContactsFile = { contacts: {} };
    for (const [id, contact] of this.contacts) {
      data.contacts[id] = {
        publicKey: '', // Would need to export back to JWK — implement if needed
        role: contact.role,
        description: contact.description,
      };
    }
    await writeFile(path, JSON.stringify(data, null, 2), { mode: 0o600 });
  }
}
