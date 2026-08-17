# Sift Gemini proxy

> **Not currently used by the app.** Sift now fetches the shared Gemini key
> from Firebase Remote Config (see `lib/core/config/shared_key_service.dart`),
> which needs no Cloudflare account and no card. This Worker is kept because it
> is the stronger design — the key never leaves the server, so it cannot be
> pulled out of a running app — and is worth adopting if the shared quota ever
> gets abused. Deploying it means pointing `LLMService` back at a proxy call.

A Cloudflare Worker that stands between the Sift app and Gemini. It holds the
real `GEMINI_API_KEY` as a server-side secret — the app never has it — and
only forwards a request once it's verified a Firebase App Check token proving
the request came from an unmodified copy of the real app.

This does not require adding a credit card. Cloudflare Workers' free plan
(100,000 requests/day) needs no payment method at all — a card is only asked
for if you choose to upgrade, which nothing here requires.

## One-time setup

You need a [Cloudflare account](https://dash.cloudflare.com/sign-up) (free,
email + password, no card) and Node.js installed locally.

```bash
cd server/gemini-proxy
npm install
```

## Log in to Cloudflare

```bash
npx wrangler login
```

This opens a browser tab to authorize the CLI against your Cloudflare
account. No payment step in this flow.

## Set the real Gemini key as a secret

This is the one place the real key should exist outside your own machine —
Cloudflare stores it encrypted and it's never visible in the dashboard, in
`wrangler.toml`, or in this repo.

```bash
npx wrangler secret put GEMINI_API_KEY
```

It'll prompt you to paste the key — the same one currently in your local
`dart_define.json` under `GEMINI_API_KEY`. Paste it and press enter.

## Deploy

```bash
npx wrangler deploy
```

Output includes your Worker's URL, something like:

```
https://sift-gemini-proxy.<your-subdomain>.workers.dev
```

Copy that — it goes into the Flutter app's `dart_define.json` as
`GEMINI_PROXY_URL` (see the root `dart_define.example.json`).

## Verifying it's actually gated

Once deployed, confirm unauthenticated requests are rejected:

```bash
curl -i -X POST https://sift-gemini-proxy.<your-subdomain>.workers.dev \
  -H "Content-Type: application/json" \
  -d '{"contents":[{"parts":[{"text":"hi"}]}]}'
```

Expected: `401 Missing App Check token`. If you see anything from Gemini
instead, something is wrong — stop and check the deployed code before
shipping the app pointed at this URL.

## Redeploying after a code change

```bash
npx wrangler deploy
```

The secret persists across deploys — you only run `wrangler secret put`
again if the key itself ever needs to rotate.

## Watching live requests (debugging)

```bash
npm run tail
```

Streams logs from the deployed Worker in real time — useful for seeing App
Check verification failures as they happen.
