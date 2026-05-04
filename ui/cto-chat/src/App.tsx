import React, { useState, useEffect, useRef } from 'react';
import { generateAndStoreKeys, loadStoredKeys, sealMessage, type StoredKeys } from './crypto';

interface Message {
  id: string;
  sender: 'john' | 'cto';
  text: string;
  time: string;
  role?: string;
}

export function App() {
  const [keys, setKeys] = useState<StoredKeys | null>(null);
  const [agentUrl, setAgentUrl] = useState(() => localStorage.getItem('cto-agent-url') ?? '');
  const [ctoPublicKey, setCtoPublicKey] = useState(() => localStorage.getItem('cto-public-key') ?? '');
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [connected, setConnected] = useState(false);
  const [sending, setSending] = useState(false);
  const messagesEnd = useRef<HTMLDivElement>(null);

  // Load keys on mount
  useEffect(() => {
    const stored = loadStoredKeys();
    if (stored) setKeys(stored);
  }, []);

  // Auto-scroll to bottom
  useEffect(() => {
    messagesEnd.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // Setup: generate keys
  async function handleSetup() {
    const newKeys = await generateAndStoreKeys();
    setKeys(newKeys);
  }

  // Connect to agent
  function handleConnect() {
    localStorage.setItem('cto-agent-url', agentUrl);
    localStorage.setItem('cto-public-key', ctoPublicKey);
    setConnected(true);
    setMessages([{
      id: crypto.randomUUID(),
      sender: 'cto',
      text: 'Connected to CTO via secure A2A channel. All messages are encrypted.',
      time: new Date().toLocaleTimeString(),
    }]);
  }

  // Send message
  async function handleSend() {
    if (!input.trim() || !keys || !ctoPublicKey || sending) return;

    const text = input.trim();
    setInput('');
    setSending(true);

    // Add to local messages
    const msgId = crypto.randomUUID();
    setMessages(prev => [...prev, {
      id: msgId,
      sender: 'john',
      text,
      time: new Date().toLocaleTimeString(),
    }]);

    try {
      // Seal: sign + encrypt
      const a2aPayload = JSON.stringify({
        jsonrpc: '2.0',
        method: 'tasks/send',
        params: {
          message: { role: 'user', parts: [{ type: 'text', text }] },
          taskType: 'command',
        },
        id: msgId,
      });

      const encrypted = await sealMessage(
        a2aPayload,
        keys.privateKey,
        keys.keyId,
        ctoPublicKey
      );

      // Send to CTO
      const response = await fetch(`${agentUrl}/a2a`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ encrypted }),
      });

      if (response.ok) {
        const data = await response.json();
        // TODO: Handle encrypted response from CTO
        // For now, show the raw response
        if (data.reply) {
          setMessages(prev => [...prev, {
            id: crypto.randomUUID(),
            sender: 'cto',
            text: data.reply,
            time: new Date().toLocaleTimeString(),
            role: 'command',
          }]);
        }
      } else {
        setMessages(prev => [...prev, {
          id: crypto.randomUUID(),
          sender: 'cto',
          text: `Error: ${response.status} ${response.statusText}`,
          time: new Date().toLocaleTimeString(),
        }]);
      }
    } catch (err: any) {
      setMessages(prev => [...prev, {
        id: crypto.randomUUID(),
        sender: 'cto',
        text: `Connection error: ${err.message}`,
        time: new Date().toLocaleTimeString(),
      }]);
    }

    setSending(false);
  }

  // Key setup screen
  if (!keys) {
    return (
      <div className="app">
        <div className="setup">
          <h2>CTO Secure Chat</h2>
          <p>Generate your encryption keys to communicate with CTO securely.</p>
          <button onClick={handleSetup}>Generate Keys</button>
        </div>
      </div>
    );
  }

  // Connection screen
  if (!connected) {
    return (
      <div className="app">
        <div className="setup">
          <h2>Connect to CTO</h2>
          <p>Your key ID: {keys.keyId}</p>
          <p>Share your public key with CTO to be added to its contacts list.</p>
          <input
            placeholder="CTO Agent URL (e.g., https://116.203.68.119:18789)"
            value={agentUrl}
            onChange={e => setAgentUrl(e.target.value)}
          />
          <input
            placeholder="CTO's public key (JWK)"
            value={ctoPublicKey}
            onChange={e => setCtoPublicKey(e.target.value)}
          />
          <button onClick={handleConnect} disabled={!agentUrl || !ctoPublicKey}>
            Connect
          </button>
          <p style={{ fontSize: 11, color: '#666' }}>
            Public key to give CTO:<br />
            <code style={{ fontSize: 10, wordBreak: 'break-all' }}>{keys.publicKey}</code>
          </p>
        </div>
      </div>
    );
  }

  // Chat screen
  return (
    <div className="app">
      <div className="header">
        <h1>CTO</h1>
        <span className={`status ${connected ? 'connected' : ''}`}>
          {connected ? 'Encrypted' : 'Disconnected'}
        </span>
      </div>

      <div className="messages">
        {messages.map(msg => (
          <div key={msg.id} className={`message ${msg.sender === 'john' ? 'self' : 'other'}`}>
            {msg.sender === 'cto' && <div className="sender">CTO</div>}
            {msg.text}
            <div className="time">
              {msg.time}
              {msg.role && <span className="role-badge">{msg.role}</span>}
            </div>
          </div>
        ))}
        <div ref={messagesEnd} />
      </div>

      <div className="input-area">
        <input
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleSend()}
          placeholder="Message CTO..."
          disabled={sending}
        />
        <button onClick={handleSend} disabled={!input.trim() || sending}>
          {sending ? '...' : 'Send'}
        </button>
      </div>
    </div>
  );
}
