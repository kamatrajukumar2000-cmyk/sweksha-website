# Sweksha Fondation Club — JSON File Hosting

The site has no database. A small Node.js server saves submitted reviews directly into `reviews.json` and serves the website. GitHub Pages only serves static files and cannot run this server, so automatic shared review submission requires Node-capable hosting with a persistent writable disk.

## Run locally

Install Node.js, then run:

```sh
npm start
```

Open `http://localhost:3000`. Submitting the form sends the review to the server, appends it to `reviews.json`, and publishes it immediately. No review file download is created.

## Deploy

Deploy this repository as a Node.js web service on a host that provides a persistent disk. Set the start command to `npm start`, and configure `REVIEWS_FILE` to a JSON file on that persistent disk, for example `/var/data/reviews.json`. Initialize that file with `[]` if it does not exist. Keep a single server instance unless the host provides shared file locking; the JSON file is not designed for multiple independent server copies.

Do not host this version only on GitHub Pages: the page would load, but review submissions could not be saved. Opening `index.html` directly as a `file://` URL also will not work; open the URL served by Node.js.

## Review behavior

Every valid submission is immediately marked approved, saved in `reviews.json`, and shown publicly. The API validates field lengths and limits each IP address to three submissions per minute. Because reviews publish immediately, remove inappropriate entries from the JSON file on the persistent disk.

## Important

- Submitted reviews and names are public. Do not submit passwords, confidential production data, or private information.
- Back up the persistent `reviews.json` file regularly.
- The WhatsApp service-request form still opens WhatsApp and does not store those requests.
