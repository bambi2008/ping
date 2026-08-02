import { createClientFromRequest } from "npm:@base44/sdk@0.8.31";

interface EmailInput {
  subject: string;
  body?: string;
  date?: string;
  from?: string;
}

interface DetectedSubscription {
  name: string;
  amount: number;
  currency: string;
  billingCycle: string;
  nextBillingDate: string | null;
  confidence: number;
  source: string;
  emailFrom: string;
}

const SERVICE_PATTERNS: Record<string, { names: string[]; patterns: RegExp[] }> = {
  netflix: { names: ['Netflix'], patterns: [/netflix/i] },
  spotify: { names: ['Spotify'], patterns: [/spotify/i] },
  disney: { names: ['Disney+'], patterns: [/disney\+|disney\s*plus/i] },
  youtube: { names: ['YouTube Premium'], patterns: [/youtube\s*premium|youtube\s*music/i] },
  icloud: { names: ['iCloud+'], patterns: [/icloud\+|icloud\s*storage/i] },
  amazon: { names: ['Amazon Prime'], patterns: [/amazon\s*prime/i] },
  adobe: { names: ['Adobe Creative Cloud'], patterns: [/adobe/i] },
  chatgpt: { names: ['ChatGPT Plus'], patterns: [/chatgpt\s*plus|openai/i] },
  applemusic: { names: ['Apple Music'], patterns: [/apple\s*music/i] },
  github: { names: ['GitHub Pro'], patterns: [/github/i] },
  notion: { names: ['Notion'], patterns: [/notion/i] },
  dropbox: { names: ['Dropbox'], patterns: [/dropbox/i] },
  hbo: { names: ['HBO Max'], patterns: [/hbo\s*max/i] },
  duolingo: { names: ['Duolingo Plus'], patterns: [/duolingo/i] },
  figma: { names: ['Figma'], patterns: [/figma/i] },
  onepassword: { names: ['1Password'], patterns: [/1password/i] },
  headspace: { names: ['Headspace'], patterns: [/headspace/i] },
  slack: { names: ['Slack'], patterns: [/slack/i] },
  zoom: { names: ['Zoom'], patterns: [/zoom/i] },
  linkedin: { names: ['LinkedIn Premium'], patterns: [/linkedin/i] },
  audible: { names: ['Audible'], patterns: [/audible/i] },
  patreon: { names: ['Patreon'], patterns: [/patreon/i] },
  nintendo: { names: ['Nintendo Switch Online'], patterns: [/nintendo/i] },
  playstation: { names: ['PlayStation Plus'], patterns: [/playstation/i] },
  xbox: { names: ['Xbox Game Pass'], patterns: [/xbox/i] },
};

const AMOUNT_PATTERNS: RegExp[] = [
  /(?:€|EUR|USD|\$|£|GBP|¥|CNY|JPY)\s*(\d+[.,]\d{2})/i,
  /(\d+[.,]\d{2})\s*(?:€|EUR|USD|\$|£|GBP|¥|CNY|JPY)/i,
  /total[:\s]*(\d+[.,]\d{2})/i,
  /amount[:\s]*(\d+[.,]\d{2})/i,
  /billed[:\s]*(\d+[.,]\d{2})/i,
];

const CURRENCY_MAP: Record<string, string> = {
  '€': 'EUR', 'EUR': 'EUR', '$': 'USD', 'USD': 'USD',
  '£': 'GBP', 'GBP': 'GBP', '¥': 'CNY', 'CNY': 'CNY', 'JPY': 'JPY',
};

function detectBillingCycle(text: string): string {
  const l = text.toLowerCase();
  if (/yearly|annual|per\s*year|\/\s*year|every\s*12\s*months/i.test(l)) return 'yearly';
  if (/monthly|per\s*month|\/\s*month|every\s*month/i.test(l)) return 'monthly';
  if (/weekly|per\s*week|\/\s*week/i.test(l)) return 'weekly';
  if (/subscription|renewal|recurring|auto-renew/i.test(l)) return 'monthly';
  return 'monthly';
}

function extractNextBillingDate(text: string): string | null {
  const m1 = text.match(/next\s*(?:billing|payment|renewal)\s*(?:date)?[:\s]*([A-Za-z]+\s*\d{1,2},?\s*\d{4})/i);
  if (m1) return m1[1];
  const m2 = text.match(/renews?\s*on\s*(\d{4}-\d{2}-\d{2})/i);
  if (m2) return m2[1];
  const m3 = text.match(/renews?\s*([A-Za-z]+\s*\d{1,2},?\s*\d{4})/i);
  if (m3) return m3[1];
  return null;
}

function extractAmount(text: string): { amount: number; currency: string } | null {
  for (const p of AMOUNT_PATTERNS) {
    const m = text.match(p);
    if (m) {
      const amt = parseFloat(m[1].replace(',', '.'));
      if (!isNaN(amt) && amt > 0 && amt < 10000) {
        let cur = 'EUR';
        for (const [sym, code] of Object.entries(CURRENCY_MAP)) {
          if (m[0].includes(sym)) { cur = code; break; }
        }
        return { amount: amt, currency: cur };
      }
    }
  }
  return null;
}

function isSubscriptionEmail(subject: string, body: string): boolean {
  const t = (subject + ' ' + body).toLowerCase();
  return ['subscription', 'renewal', 'recurring', 'auto-renew', 'receipt', 'invoice', 'billing', 'payment confirmation', 'charged', 'membership', 'premium', 'plan'].some(k => t.includes(k));
}

function detectService(text: string): string | null {
  for (const [key, info] of Object.entries(SERVICE_PATTERNS)) {
    for (const p of info.patterns) { if (p.test(text)) return key; }
  }
  const fb = text.match(/(?:your\s+)?([A-Z][a-zA-Z0-9+]+)\s+(?:subscription|receipt|billing|membership|premium)/);
  return fb ? fb[1].toLowerCase() : null;
}

Deno.serve(async (req) => {
  const base44 = createClientFromRequest(req);

  try {
    const { emails } = await req.json() as { emails: EmailInput[] };
    if (!emails || !Array.isArray(emails)) {
      return Response.json({ error: 'emails array required' }, { status: 400 });
    }

    const detected: DetectedSubscription[] = [];
    const seen = new Set<string>();

    for (const email of emails) {
      const text = `${email.subject} ${email.body || ''}`;
      if (!isSubscriptionEmail(email.subject, email.body || '')) continue;
      const key = detectService(text);
      if (!key || seen.has(key)) continue;

      const info = SERVICE_PATTERNS[key];
      const name = info ? info.names[0] : key.charAt(0).toUpperCase() + key.slice(1);
      const amt = extractAmount(text);
      const cycle = detectBillingCycle(text);
      const nextDate = extractNextBillingDate(text);

      let conf = 0.5;
      if (amt) conf += 0.3;
      if (cycle !== 'unknown') conf += 0.1;
      if (nextDate) conf += 0.1;

      detected.push({
        name, amount: amt?.amount || 0, currency: amt?.currency || 'EUR',
        billingCycle: cycle, nextBillingDate: nextDate,
        confidence: Math.min(conf, 1.0), source: email.subject, emailFrom: email.from || '',
      });
      seen.add(key);
    }

    detected.sort((a, b) => b.confidence - a.confidence);
    return Response.json({ subscriptions: detected });

  } catch (e) {
    return Response.json({ error: e.message }, { status: 500 });
  }
});
