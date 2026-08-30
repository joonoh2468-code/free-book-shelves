# Free Book Shelf Network

A live-inventory app for community "take forever" book shelves. Visitors
scan a shelf's QR code (or search from home) to see exactly which
children's/pre-teen books are on it right now, and tap to take one —
no accounts, no returns. Volunteers scan a barcode to add donated
books in seconds.

**Stack (100% free tier):** plain HTML/CSS/JS frontend, Supabase for
database + auth, Netlify for hosting (deployed from GitHub),
`html5-qrcode` for barcode scanning, Google Books API for metadata
lookup, `api.qrserver.com` for QR code generation.

---

## 1. Create the Supabase project

1. Go to [supabase.com](https://supabase.com) and sign up (free).
2. Click **New Project**. Pick a name, generate a database password
   (save it somewhere — you likely won't need it day-to-day, but keep
   it safe), and choose a region close to you.
3. Wait a minute or two for the project to finish provisioning.

## 2. Run the database schema

1. In the Supabase dashboard, open the **SQL Editor** in the left
   sidebar.
2. Click **New query**, paste in the entire contents of `schema.sql`,
   and click **Run**.
3. This creates the `shelves` and `books` tables, locks them down with
   Row Level Security so visitors can only view books and take them
   (never edit titles or authors), and creates the `mark_book_taken`
   function that safely handles checkout.

You can re-run this file safely later — it uses `if not exists` and
`drop policy if exists` so it won't error on a second run.

## 3. Get your Project URL and API key

1. On your project's main page, click the green **Connect** button
   near the top — this shows your **Project URL** and **Publishable**
   (anon) key together, ready to copy.
   - If you don't see Connect, go to **Project Settings → API**
     instead. The Project URL is at the top; the key is under **API
     Keys** (labeled **Publishable** on newer projects, **anon** on
     older ones).
2. Open `supabaseClient.js` and paste both values in:

   ```js
   const SUPABASE_URL = 'https://your-project-id.supabase.co';
   const SUPABASE_ANON_KEY = 'sb_publishable_xxxxxxxx'; // or the anon JWT key
   ```

3. **Never** use the **Secret** (or `service_role`) key here — that
   key bypasses every security rule and must never appear in code that
   runs in a browser.

## 4. Turn off public sign-ups (staff accounts are invite-only)

1. In Supabase, go to **Authentication → Sign In / Providers** (or
   **Authentication → Settings**, depending on dashboard version).
2. Find the option to **disable public sign-ups** (sometimes phrased
   as "Allow new users to sign up") and turn it off. This means the
   only way to become a volunteer/staff account is for you to invite
   someone directly.
3. To invite a volunteer: go to **Authentication → Users → Invite
   user**, enter their email, and Supabase sends them a link to set a
   password. They can then log in at `staff-login.html`.

## 5. Put the code on GitHub

1. Create a new (public or private, either works) GitHub repository.
2. Add all the project files to it: `schema.sql` (kept for reference —
   it doesn't need to deploy), `supabaseClient.js` (now with your real
   values), `index.html`, `checkout.html`, `staff-login.html`,
   `add-book.html`, `manage-shelves.html`, `style.css`, and this
   `README.md`.
3. Commit and push.

**Heads up:** your Publishable/anon key is safe to commit — it's
designed to be public and is exactly what ships to every visitor's
browser. Just double-check you never paste the Secret key anywhere in
the repo.

## 6. Deploy on Netlify

1. Go to [netlify.com](https://netlify.com) and sign up free.
2. Click **Add new site → Import an existing project**, connect your
   GitHub account, and select the repo.
3. Leave the build settings blank (there's no build step — this is a
   static site) and click **Deploy**.
4. Netlify gives you a live URL like `https://your-site-name.netlify.app`.
   That's the link people will scan and search from.

## 7. Test the whole flow before printing anything

1. Visit your Netlify URL — you should land on the search page
   (`index.html`), currently empty since no books exist yet.
2. Go to `your-site.netlify.app/staff-login.html` and log in with an
   invited account.
3. On `manage-shelves.html`, create one test shelf. A QR code appears
   immediately.
4. On `add-book.html`, scan a real book's barcode (or use manual
   entry) and save it to that test shelf.
5. Scan the shelf's QR code with your phone (or open the checkout link
   directly) and confirm the book shows up and "I'm taking this book"
   works.
6. Search for it on the public search page.
7. If all of that works, delete the test shelf/book from
   `manage-shelves.html`/Supabase's table editor and you're ready for
   real shelves.

## 8. Add your real shelves and books

1. Create a shelf in `manage-shelves.html` for each physical location
   you've lined up.
2. Print and laminate each QR code once. Because the QR points at the
   shelf (not individual books), you never reprint — new books just
   start appearing when scanned.
3. Load your book donations through `add-book.html`. Scan the barcode
   on the back cover; title and author autofill from Google Books.
   Books with no working barcode (common with older/worn donations)
   can be entered manually — just fill in the title and author
   yourself.

---

## Troubleshooting

- **"Invalid API key" or nothing loads:** double-check
  `supabaseClient.js` has the Publishable/anon key, not the Secret
  key, and that the Project URL has no typos or trailing slash.
- **Camera won't open for barcode scanning:** the browser needs HTTPS
  (Netlify gives you this automatically) and camera permission —
  check the browser's site settings if it was denied once.
- **A book/shelf you added isn't showing up:** confirm you're logged
  in as staff when adding it, and that Row Level Security policies
  from `schema.sql` ran successfully (check the SQL Editor for errors
  if you re-run it).
- **Barcode scans but no book info fills in:** some older or
  independently-published books aren't in Google Books — that's
  expected; just fill in the title/author by hand.

## Phase 2 (not built yet, deliberately deferred)

True AI vision recognition — take a photo of a cover with no barcode
and have AI read the title/author — would need a Supabase Edge
Function to keep an AI API key secure server-side. Worth revisiting
once the barcode + manual-entry version has been running a while and
it's clear how often books actually lack a scannable barcode.
