/**
 * App Check-gated reverse proxy for Gemini's generateContent endpoint.
 *
 * The real Gemini API key never leaves this Worker — it's stored as a
 * Cloudflare secret (`wrangler secret put GEMINI_API_KEY`), not in source,
 * and never sent to the client. The Flutter app authenticates each request
 * with a Firebase App Check token instead; this Worker verifies that token
 * against Firebase's public keys before forwarding anything to Gemini.
 *
 * This is a thin, dumb pipe on purpose: it does not know about tags, OCR, or
 * schemas. The client builds the exact Gemini REST request body (contents +
 * generationConfig, including responseSchema) and this Worker just forwards
 * it verbatim once the caller is verified. Keeping the prompt/schema logic
 * only in the Flutter app (already tested) avoids two implementations of the
 * same thing drifting apart.
 */
import { createRemoteJWKSet, jwtVerify } from 'jose';

export interface Env {
  GEMINI_API_KEY: string;
  FIREBASE_PROJECT_NUMBER: string;
  GEMINI_MODEL: string;
}

const APP_CHECK_JWKS_URL = 'https://firebaseappcheck.googleapis.com/v1/jwks';

// Cached across invocations within the same isolate — createRemoteJWKSet
// keeps its own internal cache (30s cooldown, 10min max age by default), so
// this avoids re-fetching Firebase's public keys on every single request.
let jwks: ReturnType<typeof createRemoteJWKSet> | undefined;

async function verifyAppCheckToken(token: string, projectNumber: string): Promise<boolean> {
  jwks ??= createRemoteJWKSet(new URL(APP_CHECK_JWKS_URL));
  try {
    await jwtVerify(token, jwks, {
      issuer: `https://firebaseappcheck.googleapis.com/${projectNumber}`,
      audience: `projects/${projectNumber}`,
    });
    return true;
  } catch (err) {
    console.warn('App Check verification failed:', err instanceof Error ? err.message : err);
    return false;
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    const appCheckToken = request.headers.get('X-Firebase-AppCheck');
    if (!appCheckToken) {
      return new Response('Missing App Check token', { status: 401 });
    }

    const isValid = await verifyAppCheckToken(appCheckToken, env.FIREBASE_PROJECT_NUMBER);
    if (!isValid) {
      return new Response('Invalid App Check token', { status: 401 });
    }

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return new Response('Invalid JSON body', { status: 400 });
    }

    // Reject anything that isn't shaped like a generateContent request before
    // spending a Gemini call on it.
    if (
      typeof body !== 'object' ||
      body === null ||
      !('contents' in body) ||
      !Array.isArray((body as { contents: unknown }).contents)
    ) {
      return new Response('Request body must include a "contents" array', { status: 400 });
    }

    const model = env.GEMINI_MODEL || 'gemini-2.5-flash';
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

    const upstream = await fetch(geminiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': env.GEMINI_API_KEY,
      },
      body: JSON.stringify(body),
    });

    // Forward Gemini's response (and status code) verbatim — the client
    // already knows how to parse both success and error shapes.
    return new Response(upstream.body, {
      status: upstream.status,
      headers: { 'Content-Type': 'application/json' },
    });
  },
};
