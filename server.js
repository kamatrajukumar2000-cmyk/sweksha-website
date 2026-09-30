const http = require('node:http');
const fs = require('node:fs/promises');
const path = require('node:path');

const root = __dirname;
const reviewsFile = path.resolve(process.env.REVIEWS_FILE || path.join(root, 'reviews.json'));
const port = Number(process.env.PORT || 3000);
const rateLimits = new Map();
let writeQueue = Promise.resolve();

function sendJson(response, status, value) {
  response.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store'
  });
  response.end(JSON.stringify(value));
}

async function readReviews() {
  try {
    const content = await fs.readFile(reviewsFile, 'utf8');
    const reviews = JSON.parse(content);
    if (!Array.isArray(reviews)) throw new Error('Review file must contain a JSON array.');
    return reviews.flatMap(review => Array.isArray(review.value) ? review.value : [review]);
  } catch (error) {
    if (error.code === 'ENOENT') return [];
    throw error;
  }
}

function appendReview(review) {
  const operation = writeQueue.then(async () => {
    const reviews = await readReviews();
    reviews.push(review);
    await fs.mkdir(path.dirname(reviewsFile), {recursive: true});
    const temporaryFile = `${reviewsFile}.${process.pid}.tmp`;
    await fs.writeFile(temporaryFile, `${JSON.stringify(reviews, null, 2)}\n`, 'utf8');
    await fs.rename(temporaryFile, reviewsFile);
  });
  writeQueue = operation.catch(() => {});
  return operation;
}

function validateSubmission(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const name = typeof value.name === 'string' ? value.name.trim() : '';
  const company = typeof value.company === 'string' ? value.company.trim() : '';
  const title = typeof value.title === 'string' ? value.title.trim() : '';
  const reviewText = typeof value.review_text === 'string' ? value.review_text.trim() : '';
  const rating = Number(value.rating);

  if (!name || name.length > 80 || company.length > 120 || title.length > 120) return null;
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) return null;
  if (!reviewText || reviewText.length > 1200) return null;

  return {
    name,
    company: company || null,
    rating,
    title: title || null,
    review_text: reviewText,
    approved: true,
    created_at: new Date().toISOString()
  };
}

function checkRateLimit(request) {
  const key = request.socket.remoteAddress || 'unknown';
  const now = Date.now();
  const limit = rateLimits.get(key);
  if (!limit || now - limit.startedAt > 60_000) {
    rateLimits.set(key, {startedAt: now, count: 1});
    return true;
  }
  if (limit.count >= 3) return false;
  limit.count += 1;
  return true;
}

async function readRequestBody(request) {
  let body = '';
  for await (const chunk of request) {
    body += chunk;
    if (body.length > 16_384) throw new Error('Review submission is too large.');
  }
  return JSON.parse(body);
}

const server = http.createServer(async (request, response) => {
  const requestUrl = new URL(request.url, `http://${request.headers.host || 'localhost'}`);

  if (request.method === 'GET' && requestUrl.pathname === '/api/reviews') {
    try {
      const reviews = await readReviews();
      sendJson(response, 200, reviews.filter(review => review.approved === true));
    } catch (error) {
      sendJson(response, 500, {error: 'Could not read reviews.json.'});
    }
    return;
  }

  if (request.method === 'POST' && requestUrl.pathname === '/api/reviews') {
    if (!checkRateLimit(request)) {
      sendJson(response, 429, {error: 'Please wait a minute before submitting another review.'});
      return;
    }

    try {
      const submission = validateSubmission(await readRequestBody(request));
      if (!submission) {
        sendJson(response, 400, {error: 'Check the name, rating, and review text, then try again.'});
        return;
      }
      await appendReview(submission);
      sendJson(response, 201, {review: submission});
    } catch (error) {
      const tooLarge = error.message === 'Review submission is too large.';
      sendJson(response, tooLarge ? 413 : 400, {
        error: tooLarge ? error.message : 'The review could not be saved. Please try again.'
      });
    }
    return;
  }

  if (request.method === 'GET' && ['/', '/index.html', '/reviews.json'].includes(requestUrl.pathname)) {
    try {
      const requestedFile = requestUrl.pathname === '/reviews.json' ? reviewsFile : path.join(root, 'index.html');
      const content = await fs.readFile(requestedFile);
      response.writeHead(200, {
        'Content-Type': requestUrl.pathname === '/reviews.json' ? 'application/json; charset=utf-8' : 'text/html; charset=utf-8',
        'Cache-Control': 'no-store'
      });
      response.end(content);
    } catch (error) {
      response.writeHead(500, {'Content-Type': 'text/plain; charset=utf-8'});
      response.end('Website file could not be read.');
    }
    return;
  }

  response.writeHead(404, {'Content-Type': 'text/plain; charset=utf-8'});
  response.end('Not found');
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Sweksha website listening on port ${port}`);
});
