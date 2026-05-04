# a2a-secure — Encrypted A2A Communication Layer

Mandatory JWS signing + JWE encryption for A2A protocol messages.
No unencrypted path exists.

## Design

### Key Pairs
- Algorithm: Ed25519 (signing) + X25519 (encryption)
- Each agent and human gets a key pair
- Private key never leaves the owner's device/VPS
- Public keys shared freely via contacts list

### Contacts List
JSON file mapping identities to public keys and roles:
```json
{
  "contacts": {
    "john": {
      "publicKey": "base64...",
      "role": "command",
      "description": "Owner/Operator"
    },
    "cfo": {
      "publicKey": "base64...", 
      "role": "inform",
      "description": "CFO Agent — peer"
    }
  }
}
```

### Roles
- `command` — can send directives that CTO must act on
- `inform` — can send information that CTO prioritizes as reliable
- Unknown senders — rejected entirely

### Message Flow
1. Sender signs message with their Ed25519 private key (JWS)
2. Sender encrypts signed message with receiver's X25519 public key (JWE)
3. Message sent via A2A protocol over HTTPS
4. Receiver decrypts with their X25519 private key
5. Receiver verifies signature against contacts list
6. Receiver checks role (command vs inform)
7. Message processed accordingly
