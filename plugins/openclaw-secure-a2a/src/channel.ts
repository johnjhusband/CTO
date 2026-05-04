/**
 * Channel plugin object — follows the same pattern as Telegram, Discord, etc.
 * Created with createChatChannelPlugin from the OpenClaw SDK.
 */

import { createChatChannelPlugin, createChannelPluginBase } from "openclaw/plugin-sdk/channel-core";
import { sendSecureMessage } from "./outbound.js";

export const secureA2aPlugin = createChatChannelPlugin({
  base: createChannelPluginBase({
    id: "secure-a2a",
    setup: {
      resolveAccount(cfg: any, accountId: string | undefined) {
        const section = cfg.channels?.["secure-a2a"];
        return {
          accountId: accountId ?? "default",
          enabled: section?.enabled ?? true,
          contactsPath: section?.contactsPath ?? "/opt/cto/contacts.json",
          keysDir: section?.keysDir ?? "/opt/cto/.keys",
          agentUrl: section?.agentUrl ?? "https://localhost:18789",
        };
      },
      inspectAccount(cfg: any, accountId: string | undefined) {
        const section = cfg.channels?.["secure-a2a"];
        return {
          enabled: section?.enabled ?? false,
          configured: Boolean(section?.contactsPath && section?.keysDir),
        };
      },
    },
  }),

  capabilities: {
    chatTypes: ["direct"],
  },

  security: {
    dm: {
      channelKey: "secure-a2a",
      resolvePolicy: () => "allowlist",
      resolveAllowFrom: () => ["*"], // Handled by our contacts list, not OpenClaw's
      defaultPolicy: "allowlist",
    },
  },

  threading: { topLevelReplyToMode: "reply" },

  outbound: {
    attachedResults: {
      sendText: async (params: any) => {
        // params.to = recipient identifier
        // params.text = message content from the agent
        const result = await sendSecureMessage(
          params.to,
          params.text,
          "inform"
        );
        if (!result.success) {
          throw new Error(`Failed to send: ${result.error}`);
        }
        return { messageId: crypto.randomUUID() };
      },
    },
    base: {
      sendMedia: async (params: any) => {
        // TODO: Implement media sending via A2A
        throw new Error("Media sending not yet implemented");
      },
    },
  },
});
