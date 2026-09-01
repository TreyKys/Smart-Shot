/// Per-model rate limits, straight from the user's own Mistral console
/// (Admin → Limits) — not published docs, not a guess. Requests-per-second
/// is often fractional (e.g. 0.07 for mistral-large-2512, meaning roughly
/// one request per 14 seconds), which is exactly what makes a naive
/// fire-and-hope client fall over — see RateLimitedQueue.
///
/// Update this table if the account's limits change or a different model
/// gets used; MistralClient looks itself up here by model id.
const Map<String, ({double rps, double tpm})> kMistralRateLimits = {
  'codestral-2508': (rps: 2.08, tpm: 625000),
  'codestral-embed': (rps: 1.00, tpm: 50000),
  'glm-5-2': (rps: 1.00, tpm: 100000),
  'labs-leanstral-1-5-1': (rps: 0.63, tpm: 5000000),
  'ministral-14b-2512': (rps: 0.50, tpm: 937500),
  'ministral-3b-2512': (rps: 12.50, tpm: 1300000),
  'ministral-8b-2512': (rps: 3.13, tpm: 625000),
  'mistral-embed-2312': (rps: 1.00, tpm: 20000000),
  'mistral-large-2512': (rps: 0.07, tpm: 250000),
  'mistral-medium-latest': (rps: 0.83, tpm: 25000),
  'mistral-moderation-2603': (rps: 1.67, tpm: 50000),
  'mistral-small-2603': (rps: 0.83, tpm: 50000),
  'voxtral-mini-2602': (rps: 1.00, tpm: 50000),
  'voxtral-mini-transcribe-realtime-2602': (rps: 1.00, tpm: 50000),
  'voxtral-mini-tts-2603': (rps: 1.00, tpm: 50000),
  'voxtral-small-2507': (rps: 1.00, tpm: 50000),
};

/// Conservative fallback for a model id not in the table above — e.g. one
/// Mistral renamed again after this was written. Better to under-use the
/// account and run slow than to guess a generous limit and get 429'd blind.
const ({double rps, double tpm}) kMistralFallbackLimit = (rps: 0.5, tpm: 20000);
