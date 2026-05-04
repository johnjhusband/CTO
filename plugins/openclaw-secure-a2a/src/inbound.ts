/**
 * Inbound message handling — receives encrypted A2A messages,
 * decrypts, verifies sender, checks permissions, dispatches to agent.
 */

import { getRuntime } from "./runtime.js";
import type { IncomingMessage, ServerResponse } from "http";

/**
 * Handle an inbound A2A request.
 * All messages MUST be JWE-encrypted containing a JWS-signed payload.
 * Unknown senders are rejected with 403.
 */
export async function handleInboundA2aRequest(
  api: any, // OpenClaw plugin API
  req: IncomingMessage,
  res: ServerResponse
): Promise<boolean> {
  const runtime = getRuntime();

  // Only accept POST
  if (req.method !== "POST") {
    res.statusCode = 405;
    res.end(JSON.stringify({ error: "Method not allowed" }));
    return true;
  }

  // Read body
  const body = await readBody(req);
  if (!body) {
    res.statusCode = 400;
    res.end(JSON.stringify({ error: "Empty body" }));
    return true;
  }

  try {
    // Parse the A2A envelope
    const envelope = JSON.parse(body);

    // The message field must contain the JWE-encrypted content
    const jwe = envelope.encrypted;
    if (!jwe || typeof jwe !== "string") {
      res.statusCode = 400;
      res.end(JSON.stringify({ error: "Missing encrypted field — all messages must be JWE encrypted" }));
      return true;
    }

    // Decrypt and verify
    const opened = await runtime.channel.open(jwe);

    // Parse the decrypted A2A task payload
    const a2aPayload = JSON.parse(opened.payload);

    // Log the verified message
    console.log(
      `[secure-a2a] Verified message from ${opened.senderId} (role: ${opened.role}): ${a2aPayload.message?.substring(0, 100)}...`
    );

    // Dispatch into OpenClaw agent pipeline
    // The message type (command vs inform) is passed as metadata
    // so the agent knows how to prioritize it
    const sessionKey = `secure-a2a:${opened.senderId}`;

    // TODO: Dispatch into OpenClaw's agent pipeline
    // api.runtime.agent.dispatch({
    //   channel: "secure-a2a",
    //   sessionKey,
    //   sender: opened.senderId,
    //   role: opened.role,
    //   content: a2aPayload.message,
    //   taskId: a2aPayload.taskId,
    // });

    // For now, acknowledge receipt
    res.statusCode = 200;
    res.setHeader("Content-Type", "application/json");
    res.end(JSON.stringify({
      status: "received",
      sender: opened.senderId,
      role: opened.role,
      taskId: a2aPayload.taskId ?? null,
    }));

    return true;

  } catch (err: any) {
    // Signature verification failed, unknown sender, decryption failed, etc.
    console.error(`[secure-a2a] Rejected message: ${err.message}`);
    res.statusCode = 403;
    res.end(JSON.stringify({ error: "Rejected — invalid signature, unknown sender, or decryption failed" }));
    return true;
  }
}

function readBody(req: IncomingMessage): Promise<string> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    req.on("data", (chunk: Buffer) => chunks.push(chunk));
    req.on("end", () => resolve(Buffer.concat(chunks).toString("utf-8")));
    req.on("error", reject);
  });
}
