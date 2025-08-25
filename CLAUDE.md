# Wedding Website Project - CLAUDE.md

## Document Context

This document was created through conversation between Anthony Bailey and Claude (August 2025) to plan a wedding website project for implementation with Claude Code. This is a handoff document between Claude instances.

**Important:** Most specifications here are starting points and suggestions. The implementing Claude instance should treat these as initial ideas to test, refine, and adapt based on actual implementation needs and testing results. Wiki pages, technical choices, and design decisions are all provisional.

## Project Overview

Unified wedding website for Anthony Bailey & Julie Dawson's wedding on May 23, 2026.

**Core concept:** Single-domain experience combining:
- Canva-designed homepage (Julie maintains control)
- Open wiki for guest collaboration
- Apache reverse proxy unifying presentation

**Design references:**
- Homepage preview: https://ordiwedding-preview.my.canva.site/ (testing URL only - production will use registered subdomain)
- Homepage screenshots (Google Drive):
  - Section 1: https://drive.google.com/file/d/1qvCcVwZC34v_OFeMfUWBV7zTaAKVxEsZ/view
  - Section 2: https://drive.google.com/file/d/1qtZJfu5wB3Qg51M7rz0Qzm1paR3irDZG/view
  - Section 3: https://drive.google.com/file/d/1qtCjRT98HHrhNX3op2NmzsClcNDgsqOE/view
- Visual theme: Vintage romantic, sage green/cream/pink palette
- Welsh elements ("O'r diwedd!" - "At last!")
- Venues: Andrew Logan Museum of Sculpture & Cwm Weeg Gardens

## Technical Architecture

### Domain Structure (Provisional)
```
example.com/            → Canva homepage (proxied)
example.com/wiki/*      → Wiki installation  
homepage.example.com    → Canva subdomain (hidden from users)
```

Note: Actual domain names and Canva URL will be configured during implementation.

### Apache Configuration (Starting Point - Test and Adapt)
```apache
<VirtualHost *:443>
    ServerName example.com
    
    # Preserve original host for wiki
    ProxyPreserveHost On
    
    # Wiki paths served directly
    ProxyPass /wiki !
    Alias /wiki /var/www/wedding-wiki
    
    # Everything else proxies to Canva
    ProxyPreserveHost Off
    ProxyPass / https://[canva-production-url]/
    ProxyPassReverse / https://[canva-production-url]/
    
    # Handle Canva assets (may need adjustment)
    ProxyPass /_next https://[canva-production-url]/_next
    ProxyPassReverse /_next https://[canva-production-url]/_next
    
    # Headers for JavaScript functionality
    Header always set Access-Control-Allow-Origin "*"
    RequestHeader set X-Forwarded-Proto "https"
</VirtualHost>
```

### Wiki Requirements

**Software candidates (evaluate during Phase 2):**
1. **DokuWiki** - File-based, built-in versioning, mobile editing
2. **Wiki.js** - Modern UI, git backend option, markdown native
3. **Custom minimal** - Markdown files + git, simple web editor

**Essential features:**
- Open editing (no registration required)
- Version control/history
- Mobile-friendly WYSIWYG or markdown editor
- Recent changes tracking
- Search functionality
- Page creation workflow

## Content Structure

### Homepage (Canva-controlled by Julie)
Per screenshots, includes:
- Welcome message & "O'r diwedd!"
- Venue information with links
- Schedule overview (10:30-midnight)
- Love story ("Something Changed")
- Gift registry preferences (givewell.org)
- RSVP & contact details

### Wiki Pages (Initial Suggestions - Refine as Needed)
```
/wiki/
  ├── Travel
  │   ├── Getting_to_Museum
  │   ├── Museum_to_Gardens (15:00 transport)
  │   └── Departure_Options
  ├── Accommodation
  │   ├── Hotels
  │   ├── B&Bs
  │   └── Guest_Recommendations
  ├── Schedule
  │   ├── Detailed_Timeline
  │   ├── Ceremony_Details
  │   └── Evening_Activities
  ├── Venues
  │   ├── Andrew_Logan_Museum
  │   └── Cwm_Weeg_Gardens
  ├── Local_Guide
  │   └── Things_to_Do
  └── FAQ
```

## Implementation Phases

### Phase 1: Canva Proxy Verification (Days 1-3)
**Goal:** Confirm technical approach works

- [ ] Set up Apache reverse proxy configuration
- [ ] Test Canva site through proxy
- [ ] Verify JavaScript/assets load correctly
- [ ] Check mobile responsiveness
- [ ] Test CORS headers if needed
- [ ] Document any Canva-specific quirks

**Success criteria:**
- Site loads identically through proxy
- All images/fonts display
- JavaScript interactions work
- Mobile viewport correct

### Phase 2: Wiki Selection & Setup (Days 4-7)
**Goal:** Deploy functional wiki

- [ ] Install/test DokuWiki vs Wiki.js (or explore alternatives)
- [ ] Configure for open editing
- [ ] Set up version control
- [ ] Create initial page structure
- [ ] Test mobile editing experience
- [ ] Configure backups

**Decision criteria:**
- Ease of guest editing (no accounts)
- Mobile editing quality (80% confidence)
- Version history interface
- Maintenance overhead

### Phase 3: Integration & Polish (Week 2)
**Goal:** Unified experience

- [ ] Style wiki to complement Canva design (suggestions):
  - Sage green accents (#8B9F8C approximate)
  - Readable serif/script fonts
  - Cream background (#F5F5DC approximate)
- [ ] Link homepage elements to wiki pages:
  - Venue names → /wiki/Venues/*
  - "travel & accommodation" → /wiki/Travel
  - RSVP button → /wiki/RSVP (or disable)
- [ ] Add Open Graph tags:
  ```html
  <meta property="og:title" content="Julie & Anthony's Wedding - May 23, 2026">
  <meta property="og:description" content="Join us at the Andrew Logan Museum and Cwm Weeg Gardens">
  <meta property="og:image" content="[couple photo URL]">
  <meta property="og:type" content="website">
  ```
- [ ] Create 404 page matching theme

### Phase 4: Content & Launch (Week 2-3)
**Goal:** Ready for guests

- [ ] Seed initial wiki pages (adapt structure as needed)
- [ ] Add example content to encourage editing
- [ ] Test guest editing workflow
- [ ] Create "How to Edit" guide
- [ ] Soft launch with trusted guests
- [ ] Iterate based on feedback
- [ ] Full announcement when ready

## Technical Notes

### Canva Considerations
- Site fully JavaScript-rendered (no server-side content)
- Currently uses preview URL, will migrate to production
- May update frequently (Julie's edits)
- Cannot extract content programmatically
- Test after each major Canva platform update

### Wiki Backup Strategy (Suggested Approach)
- Git backend (if Wiki.js) or filesystem snapshots
- Daily automated backups
- Version history within wiki software
- Apache access logs for vandalism tracking

### Monitoring (Minimal)
- Apache access/error logs
- Periodic manual review of wiki changes
- No active alerting needed (low vandalism risk)

### Mobile Optimization
- Canva site already mobile-responsive
- Wiki must support touch editing
- Test on iOS Safari, Chrome Android
- Consider simplified mobile edit interface

## Key Information Extracted from Homepage

**Event Details:**
- Date: May 23rd, 2026
- Start: 10:30 at Andrew Logan Museum of Sculpture
- Transport: 15:00 to Cwm Weeg Gardens  
- Ceremony: 16:00 onwards (Handfasting & Vows)
- End: "Carriages at Midnight"

**Contact:**
- Anthony Bailey: 07851 377 199, mail@anthonybailey.net
- Julie Dawson: 07951 137 218, julie.dawson@gmail.com

**Theme:**
- "Granny's attic, garden parties & afternoon tea"
- Dress accordingly but comfort prioritized

**Gift Preference:**
- Donations to charities via givewell.org
- Handmade or secondhand if insisting

## Testing Checklist

### Technical Tests
- [ ] Proxy loads Canva homepage correctly
- [ ] Wiki accessible at /wiki
- [ ] Mobile editing functional
- [ ] Version history working
- [ ] Search returns results
- [ ] Links between systems work

### User Journey Tests
- [ ] Guest finds travel information
- [ ] Guest adds accommodation recommendation
- [ ] Guest views on mobile
- [ ] Julie updates homepage design
- [ ] Wiki edit reverted after mistake
- [ ] Social media preview displays correctly

## Notes for Claude Code Implementation

1. **Start with Phase 1** - Verify proxy setup before investing in wiki
2. **Apache config is provisional** - Test with actual Canva URL and domain
3. **Wiki choice flexible** - Pick based on actual testing
4. **Style matching optional** - Functional first, pretty second
5. **All suggestions are starting points** - Adapt based on implementation reality
6. **No authentication complexity** - Keep it simple
7. **Expect iteration** - This is a living document

## Success Metrics

- Julie can update homepage without technical help (100% requirement)
- Guests can edit wiki without registration (100% requirement)  
- Mobile editing works smoothly (80% confidence needed)
- Single domain experience maintained
- All changes tracked/reversible
- Ready for announcement within 3 weeks

---

*Document created: August 2025 via Claude conversation*
*Wedding date: May 23, 2026*
*Venues: Andrew Logan Museum of Sculpture & Cwm Weeg Gardens, Wales*
*Implementation: Via Claude Code on Anthony's VPS*