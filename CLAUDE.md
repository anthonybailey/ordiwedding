# Wedding Website Project - CLAUDE.md

## Document Context

Planning and implementation document for Anthony Bailey & Julie Dawson's wedding website. Maintained across Claude Code sessions.

## Project Overview

Unified wedding website for Anthony Bailey & Julie Dawson's wedding on May 23, 2026.

**Core concept:** Single-domain experience combining:
- Canva-designed homepage (Julie maintains control)
- Static HTML content pages served from monkeys VPS
- Cloudflare Worker routing between the two

**Domains:**
- ordiwedd.ing (primary, HTTPS via Cloudflare)
- ordi.wedding (also works)

**Design references:**
- Canva site URL: https://ordiwedding-preview.my.canva.site/
- Visual theme: Vintage romantic, sage green/cream/pink palette
- Welsh elements ("O'r diwedd!" - "At last!")
- Venues: Andrew Logan Museum of Sculpture & Cwm Weeg Gardens

## Technical Architecture

### Routing
```
ordiwedd.ing/          → Cloudflare Worker → Canva homepage
ordiwedd.ing/-/*       → Cloudflare Worker → monkeys VPS
```

Cloudflare Worker matches `/-*` (full glob — no single-character matching available). The `/-/` prefix is an unobtrusive URL convention.

SSL is terminated by Cloudflare (Flexible mode — connects to monkeys via HTTP).

### Server (monkeys VPS)
- **IP:** 173.45.225.190, port 30022
- **OS:** Ubuntu 8.04 (ancient but functional)
- **Apache:** 2.2.8 with mod_include (SSI) and MultiViews enabled
- **Perl:** Available (for future CGI forms)
- **PHP:** Not installed
- **Python:** 2.5.2 only
- **SSH:** Only offers ssh-rsa/ssh-dss (modern clients need `HostKeyAlgorithms +ssh-rsa`)
- **Admin:** Using `sumo` wrapper for sudo (opens terminal popup — cannot run over SSH)

### Apache Config
Located in `apache-config/ordiwedding`. Key features:
- Alias `/-` to `/var/www/ordiwedding/-`
- SSI enabled (`AddOutputFilter INCLUDES .html`) for shared nav
- MultiViews enabled (extensionless URLs: `/-/travel` serves `travel.html`)
- Content directory owned by `anthony` (no root needed for deploys)

### Deployment
- `deploy/deploy-pages.sh` — rsync pages to monkeys (no root needed)
- `deploy/deploy-apache-config.sh` — installs Apache config (needs `sumo`, local terminal only)
- Manual Apache config deploy from SSH: copy to `/tmp/ordiwedding.tmp` then `sudo cp` + `sudo apache2ctl graceful`

## Content Structure

### Homepage (Canva, 7 sections)
1. Cover — "Julie & Anthony are getting married!" + RSVP link
2. "O'r diwedd!" — Love story summary + link to Our Story
3. "Good things come to those who wait" — Celebrations, venue, programme
4. Gift Registry — givewell.org + link to Gifts page
5. Special Guest — Jake Shillingford + link to Our Story #mls
6. Accommodation & Travel — link to Travel page
7. Contact info + RSVP

### Content Pages (on monkeys, under `/-/`)
- `/-/our-story` — How they met, narrative, photo placeholders, YouTube embeds
- `/-/gifts` — Julie's gift wish list, maker listings (written in Julie's voice)
- `/-/travel` — Transport advice, accommodation listings by area
- `/-/rsvp` — Placeholder: email Julie to RSVP
- Shared nav via SSI include (`nav.html`)
- Shared stylesheet (`style.css`) — sage green, cream, serif fonts

## Canva → Content Page Links

Julie has added these links to the Canva homepage:
- RSVP → `https://ordiwedd.ing/-/rsvp`
- Our Story → `https://ordiwedd.ing/-/our-story`
- Gifts → `https://ordiwedd.ing/-/gifts`
- Travel → `https://ordiwedd.ing/-/travel`
- Special Guest → `https://ordiwedd.ing/-/our-story#mls`

Links must be absolute URLs in Canva (relative URLs resolve to canva.site).

## Key Information

**Event Details:**
- Date: May 23rd, 2026
- Start: 10:30 at Andrew Logan Museum of Sculpture
- Transport: 15:00 to Cwm Weeg Gardens
- Ceremony: 16:00 onwards (Handfasting & Vows)
- End: "Carriages at Midnight"

**Contact:**
- Anthony Bailey: 07851 377 199, mail@anthonybailey.net
- Julie Dawson: 07951 137 218, julie.dawson@gmail.com
- Julie is primary contact for RSVP and guest queries

## Implementation Status (February 1, 2026)

### Completed
- Both domains active and routing correctly via Cloudflare
- Cloudflare Workers routing `/-*` to monkeys, everything else to Canva
- Apache config with SSI and MultiViews
- Content pages live: our-story, gifts, travel, rsvp
- Shared nav via SSI include
- Extensionless URLs working
- Canva homepage links to all content pages
- Deploy pipeline working (rsync, no root needed)

### Content Notes
- Our Story has photo placeholders — awaiting images from Julie
- Julie's "neurotypical" typo corrected to "neurodivergent" (check with Julie)
- References to other partners removed from Our Story for sensitivity
- Anthony's Pulp fan page linked via Wayback Machine

### Outstanding / Future
- Photos from Julie for Our Story page
- RSVP form (Perl CGI — server has Perl and CGI enabled)
- "I've booked here" form on travel page (accommodation coordination)
- Guest contribution features (travel tips, guestbook) — same form→file pattern
- Custom 404 page
- Open Graph meta tags for social sharing
- Mobile testing
- Soft launch with trusted guests

### Tools
- `sumo` — Remote sudo wrapper for monkeys (in ~/repos/main/bin/, SVN)
  - Opens terminal popup for password entry
  - Cannot be used over SSH — run from local terminal or give manual commands

---

*Document created: August 2025*
*Last updated: February 2026*
*Wedding date: May 23, 2026*
*Venues: Andrew Logan Museum of Sculpture & Cwm Weeg Gardens, Wales*
