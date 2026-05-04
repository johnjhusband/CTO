/**
 * Lightweight setup entry — loaded when channel is disabled/unconfigured.
 */

import { defineSetupPluginEntry } from "openclaw/plugin-sdk/channel-core";
import { secureA2aPlugin } from "./src/channel.js";

export default defineSetupPluginEntry(secureA2aPlugin);
