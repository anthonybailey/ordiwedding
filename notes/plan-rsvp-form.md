# RSVP Form Implementation Plan

Auto-apply plan: implement without asking for approval at each step.

## Context

- Server: monkeys, Apache 2.2, Perl available, CGI module enabled
- No PHP, no Python 3, no sendmail
- Current RSVP page (`pages/rsvp.html`) is a placeholder saying "email Julie"
- Content served under `/-/` with SSI and MultiViews
- Content directory owned by `anthony` — deploys via rsync, no root
- Apache config changes need `sudo` on monkeys (can't use `sumo` over SSH)

## Architecture

```
pages/rsvp.html          — form (static HTML, served via SSI like other pages)
pages/cgi/rsvp-submit.pl — Perl CGI script handling form POST
/var/www/ordiwedding/-/rsvp-data/  — submitted RSVPs (one file per response)
```

## Step 1: Update Apache config

Add CGI handler for a `cgi` subdirectory within the content area:

```apache
# Inside the <Directory /var/www/ordiwedding/-> block, add:
<Directory /var/www/ordiwedding/-/cgi>
    Options +ExecCGI
    AddHandler cgi-script .pl
</Directory>
```

This keeps CGI isolated to one subdirectory rather than enabling it site-wide.

**Deploy:** scp config to `/tmp/ordiwedding.tmp` on monkeys, then Anthony runs:
```bash
sudo cp /tmp/ordiwedding.tmp /etc/apache2/sites-available/ordiwedding
sudo /usr/sbin/apache2ctl configtest
sudo /usr/sbin/apache2ctl graceful
```

## Step 2: Create data directory on monkeys

```bash
ssh monkeys 'mkdir -p /var/www/ordiwedding/-/rsvp-data'
```

This should work without sudo since anthony owns `/-/`. If not, Anthony needs:
```bash
sudo mkdir -p /var/www/ordiwedding/-/rsvp-data
sudo chown anthony:anthony /var/www/ordiwedding/-/rsvp-data
```

## Step 3: RSVP form (`pages/rsvp.html`)

Replace the placeholder with a real form. Keep the SSI nav include.

**Fields:**
- Name (text, required)
- Email or phone (text, required — for contact about logistics)
- Attending? (radio: Yes / No / Not sure yet)
- Number attending including yourself (number, default 1, shown only if Yes/Not sure)
- Names of additional guests (text, shown only if number > 1)
- Dietary requirements or allergies (textarea, optional)
- Message for Julie & Anthony (textarea, optional)

**Form attributes:**
- `method="POST" action="/-/cgi/rsvp-submit.pl"`
- Style consistent with existing pages (use style.css)

**JavaScript:** Minimal — just show/hide the "number attending" and "additional guests"
fields based on the attendance radio selection. No framework needed.

## Step 4: Perl CGI script (`pages/cgi/rsvp-submit.pl`)

**Input handling:**
- Parse POST parameters using CGI module (standard Perl, no install needed)
- Sanitize: strip HTML tags, limit field lengths (name: 200 chars, textarea: 2000 chars)
- Validate: name and contact are non-empty, attending is one of yes/no/maybe

**File output:**
- Filename: `YYYYMMDD-HHMMSS-sanitized_name.txt` (timestamp prevents collisions)
- Sanitize name for filename: lowercase, replace non-alphanumeric with underscore, truncate to 50 chars
- Format: simple key: value pairs, one per line, human-readable
- Example:
  ```
  Date: 2026-02-15 14:30:22
  Name: Jane Smith
  Contact: jane@example.com
  Attending: yes
  Number: 2
  Additional guests: John Smith
  Dietary: Vegetarian
  Message: Can't wait!
  ```

**Response:**
- On success: output a complete HTML page (matching site style) with:
  - "Thank you, [Name]!" heading
  - Summary of what they submitted
  - Link back to main site
- On error (missing required fields): output error page with link back to form

**Important Perl notes:**
- Shebang: `#!/usr/bin/perl` (verify path on monkeys with `which perl`)
- `use strict; use warnings;`
- `use CGI qw(:standard);`
- File must be executable (`chmod +x`)
- Output `Content-Type: text/html\n\n` header before any HTML
- Use file locking (flock) when writing to prevent race conditions
- No email notification (no sendmail) — Anthony/Julie check rsvp-data directory

## Step 5: Viewing submissions

Don't build a custom viewer. Apache already has `Options Indexes` enabled.
Browsing to `/-/rsvp-data/` will show a directory listing of all response files.
Each file is human-readable plain text.

For a nicer view later, a simple Perl CGI or SSI script could format them,
but the directory listing is sufficient for launch.

**Privacy note:** The rsvp-data directory will be publicly listable. This is
acceptable for a wedding site — guests can see who else has RSVP'd, which is
a feature not a bug (similar to the original wiki concept). If Anthony wants
to restrict access later, add a `.htaccess` with basic auth.

## Step 6: Deploy and test

1. Deploy pages (rsync — handles form HTML and CGI script)
2. Deploy Apache config (needs sudo)
3. Create rsvp-data directory on monkeys
4. Ensure CGI script is executable: `ssh monkeys 'chmod +x /var/www/ordiwedding/-/cgi/rsvp-submit.pl'`
5. Test: `curl -X POST https://ordiwedd.ing/-/cgi/rsvp-submit.pl -d 'name=Test&contact=test@test.com&attending=yes&number=1'`
6. Verify file created in rsvp-data
7. Check form works in browser at `https://ordiwedd.ing/-/rsvp`

## Files to create/modify

- `apache-config/ordiwedding` — add CGI directory config
- `pages/rsvp.html` — replace placeholder with form
- `pages/cgi/rsvp-submit.pl` — new Perl CGI script (must be committed as executable)

## Edge cases / decisions already made

- Duplicate submissions: allowed (guests might update their plans)
- No CAPTCHA: low-traffic wedding site, spam unlikely
- No email notification: check rsvp-data manually or add later
- File-per-response not append-to-one-file: easier to manage, delete, review individually
- MultiViews won't interfere with cgi subdirectory: CGI handler takes precedence
- Timestamp in filename prevents collisions even if two "Jane Smith"s submit simultaneously
