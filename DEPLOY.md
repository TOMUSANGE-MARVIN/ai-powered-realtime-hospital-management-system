# Deploying to Coolify

This repo deploys as three services via `docker-compose.yml` at the repo root: `mongo`, `backend`, `frontend`.

## Setup in Coolify

1. Create a new **Docker Compose** resource in Coolify, pointing at this repository (root `docker-compose.yml`).
2. Set environment variables on the Coolify resource (these populate the root `.env` used by the compose file) — copy from `.env.example`:
   - `MONGO_ROOT_USER`, `MONGO_ROOT_PASSWORD` — pick a strong password; Mongo is only reachable internally, never exposed to the host.
   - `BETTER_AUTH_SECRET` — generate with `openssl rand -hex 32`.
   - `BETTER_AUTH_URL` — the **public** URL of the backend once deployed (e.g. `https://api.yourdomain.com`).
   - `FRONTEND_URL` — the **public** URL of the frontend (e.g. `https://app.yourdomain.com`).
   - `VITE_API_URL` — same value as `BETTER_AUTH_URL`. This one matters at **build time**: it gets baked into the frontend's JS bundle, so it must be set before the frontend image builds, and changing it later requires a rebuild (not just a restart).
   - `GEMINI_KEY`, `UPLOADTHING_TOKEN` — optional; leave blank to disable those features.
   - `POLAR_PRODUCT_ID`, `POLAR_ACCESS_TOKEN`, `POLAR_WEBHOOK_SECRET` — optional; leave blank to disable billing/checkout. When unset, sign-up still works (the app only auto-creates a Polar customer when `POLAR_ACCESS_TOKEN` is present).
3. Assign domains in Coolify to the `backend` (port 5000) and `frontend` (port 3000) services, and make sure both are served over HTTPS (Coolify's built-in Let's Encrypt handles this).
4. Deploy. Coolify will build all three images and start them on an internal network; `backend` reaches Mongo at `mongo:27017`, and the browser reaches `backend` at whatever public URL you set in `VITE_API_URL`.

## Why `VITE_API_URL` must match your real backend domain

The frontend calls the backend directly from the **user's browser**, not through the Docker network — so `http://localhost:5000` (used during local dev) does not work in production. All frontend API/socket/auth calls now read `import.meta.env.VITE_API_URL` at build time, falling back to `localhost:5000` only when unset (i.e. local dev).

## First deploy / promoting an admin

The database starts empty. Sign up through the app's `/login` page (or `/book-appointment` flow), then promote that user to `admin` directly in Mongo:

```bash
docker exec -it <mongo-container-name> mongosh -u <MONGO_ROOT_USER> -p <MONGO_ROOT_PASSWORD> --authenticationDatabase admin hospital --eval '
db.user.updateOne({ email: "you@example.com" }, { $set: { role: "admin" } })
'
```

## Local testing of the compose stack

```bash
cp .env.example .env   # fill in real values, or use localhost defaults for a local smoke test
docker compose up --build
```
