---
name: stealth-browser
description: "Anti-bot browser automation using stealth technology to bypass detection."
metadata:
  {
    "openclaw":
      {
        "emoji": "🥷",
        "requires": { "bins": ["stealth-browser"] },
        "install": [
          {
            "id": "npm-stealth-browser",
            "kind": "npm",
            "package": "stealth-browser-cli",
            "bins": ["stealth-browser"],
            "label": "Install stealth browser CLI"
          }
        ]
      }
  }
---

## Stealth Browser Skill

Advanced browser automation with anti-detection capabilities to bypass bot protection systems.

### Features

- **Anti-bot bypass**: Evades Cloudflare Turnstile, Datadome, and other bot detection
- **Stealth browsing**: Uses Camoufox and Nodriver for undetectable automation
- **Proxy support**: Integrates with proxy networks for IP rotation
- **Fingerprint spoofing**: Masks browser fingerprints to appear human-like
- **CAPTCHA solving**: Built-in CAPTCHA handling capabilities

### Use Cases

Use when standard automation tools (Playwright, Selenium) get blocked by:

- **Cloudflare Turnstile**: Modern challenge systems
- **Datadome**: Advanced bot detection
- **Bot protection services**: ReCAPTCHA v2/v3 alternatives
- **Rate limiting**: IP-based restrictions
- **Fingerprint detection**: Browser fingerprint analysis

### Requirements

- **Node.js** (v16+)
- **NPM** for package installation
- **Python** (optional, for advanced features)

### Installation

```bash
npm install -g stealth-browser-cli
```

### Usage Examples

- "Automate login to website with anti-bot protection"
- "Scrape data from site with Cloudflare protection"
- "Create multiple browser instances with unique fingerprints"
- "Automate form submission without detection"

### Technical Details

- **Engine**: Camoufox (Firefox-based) + Nodriver
- **Stealth Features**: WebGL spoofing, Canvas fingerprinting, Audio context manipulation
- **Performance**: Optimized for both speed and stealth
- **Compatibility**: Works with most modern websites

### Notes

- Use responsibly and ethically
- Respect website terms of service
- Consider the legal implications of bypassing bot protection
- Test thoroughly before deploying in production