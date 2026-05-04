/**
 * Outbound message handling — encrypts and sends A2A messages to peers.
 * Called by the agent via the a2a_send tool or by the channel's sendText.
 */

import { getRuntime } from "./runtime.js";

/**
 * Send an encrypted message to a peer agent.
 * Signs with our private key, encrypts with recipient's public key.
 */
export async function sendSecureMessage(
  recipientId: string,
  message: string,
  taskType: string = "inform"
): Promise<{ success: boolean; error?: string }> {
  const runtime = getRuntime();

  // Look up recipient in contacts
  const recipient = runtime.contacts.getById(recipientId);
  if (!recipient) {
    return { success: false, error: `Unknown recipient: ${recipientId}` };
  }

  try {
    // Build A2A task payload
    const a2aPayload = JSON.stringify({
      jsonrpc: "2.0",
      method: "tasks/send",
      params: {
        message: {
          role: "agent",
          parts: [{ type: "text", text: message }],
        },
        taskType,
      },
      id: crypto.randomUUID(),
    });

    // Seal: sign + encrypt
    const sealed = await runtime.channel.seal(a2aPayload, recipientId);

    // Send to recipient's A2A endpoint
    // TODO: Look up recipient's endpoint URL from their Agent Card
    // For now, use a configured URL from contacts
    const recipientUrl = `https://${recipientId}.agent.local/a2a`; // placeholder

    const response = await fetch(recipientUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ encrypted: sealed.jwe }),
    });

    if (!response.ok) {
      const body = await response.text();
      return { success: false, error: `HTTP ${response.status}: ${body}` };
    }

    return { success: true };

  } catch (err: any) {
    return { success: false, error: err.message };
  }
}
