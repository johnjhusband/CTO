/**
 * Plugin runtime store — holds the SecureChannel instance, contacts, and Agent Card.
 */

import { createPluginRuntimeStore } from "openclaw/plugin-sdk/runtime-store";
import type { SecureChannel, ContactsList } from "../../../lib/a2a-secure/src/index.js";

export interface SecureA2aRuntime {
  channel: SecureChannel;
  contacts: ContactsList;
  agentCard: Record<string, unknown>;
  myKeyId: string;
  agentUrl: string;
}

const store = createPluginRuntimeStore<SecureA2aRuntime>({
  pluginId: "secure-a2a",
  errorMessage: "secure-a2a runtime not initialized — encryption layer not ready",
});

export const setSecureA2aRuntime = store.setRuntime;
export const getRuntime = store.getRuntime;
export const tryGetRuntime = store.tryGetRuntime;
