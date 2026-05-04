/**
 * OpenClaw Secure A2A Channel Plugin
 *
 * The ONLY communication channel. All other channels are removed post-install.
 * Every message is signed (JWS) and encrypted (JWE).
 * Unknown senders are rejected. Roles (command/inform) enforced.
 *
 * Follows the same plugin pattern as Telegram, Discord, etc.
 */

import { defineChannelPluginEntry } from "openclaw/plugin-sdk/channel-core";
import { secureA2aPlugin } from "./src/channel.js";
import { setSecureA2aRuntime } from "./src/runtime.js";

export default defineChannelPluginEntry({
  id: "secure-a2a",
  name: "Secure A2A",
  description: "Encrypted agent-to-agent communication — the only channel",
  plugin: secureA2aPlugin,
  setRuntime: setSecureA2aRuntime,

  registerCliMetadata(api) {
    api.registerCli(
      ({ program }) => {
        program
          .command("secure-a2a")
          .description("Manage secure A2A connections and contacts");
      },
      {
        descriptors: [
          { name: "secure-a2a", description: "Manage secure A2A connections", hasSubcommands: false },
        ],
      },
    );
  },

  registerFull(api) {
    // Agent Card endpoint — public, no auth
    api.registerHttpRoute({
      path: "/.well-known/agent.json",
      auth: "none",
      handler: async (req, res) => {
        const { getRuntime } = await import("./src/runtime.js");
        const runtime = getRuntime();
        res.setHeader("Content-Type", "application/json");
        res.end(JSON.stringify(runtime.agentCard));
        return true;
      },
    });

    // A2A task endpoint — all messages must be encrypted
    api.registerHttpRoute({
      path: "/a2a",
      auth: "plugin", // we handle our own auth via JWS/JWE
      handler: async (req, res) => {
        const { handleInboundA2aRequest } = await import("./src/inbound.js");
        return await handleInboundA2aRequest(api, req, res);
      },
    });

    // Register tool so the LLM can send A2A messages to peers
    api.registerTool({
      name: "a2a_send",
      description: "Send an encrypted message to a peer agent via A2A secure channel",
      parameters: {
        type: "object",
        properties: {
          recipient: { type: "string", description: "Contact ID from contacts list" },
          message: { type: "string", description: "Message content" },
          taskType: { type: "string", enum: ["command", "inform", "query"], description: "Type of A2A task" },
        },
        required: ["recipient", "message"],
      },
      execute: async (params: { recipient: string; message: string; taskType?: string }) => {
        const { sendSecureMessage } = await import("./src/outbound.js");
        return await sendSecureMessage(params.recipient, params.message, params.taskType ?? "inform");
      },
    });
  },
});
