# Deploying to Coolify

This repo deploys as three services via `docker-compose.yaml` at the repo root: `mongo`, `backend`, `frontend`.

## Setup in Coolify

1. Create a new **Docker Compose** resource in Coolify, pointing at this repository (root `docker-compose.yaml`).
2. Set environment variables on the Coolify resource (these populate the root `.env` used by the compose file) — copy from `.env.example`:
   - `MONGO_ROOT_USER`, `MONGO_ROOT_PASSWORD` — pick a strong password; Mongo is only reachable internally, never exposed to the host.
   - `BETTER_AUTH_SECRET` — generate with `openssl rand -hex 32`.
   - `BETTER_AUTH_URL` — the **public** URL of the backend once deployed (e.g. `https://api.yourdomain.com`).
   - `FRONTEND_URL` — the **public** URL of the frontend (e.g. `https://app.yourdomain.com`).
   - `VITE_API_URL` — same value as `BETTER_AUTH_URL`. This one matters at **build time**: it gets baked into the frontend's JS bundle, so it must be set before the frontend image builds, and changing it later requires a rebuild (not just a restart).
   - `GEMINI_KEY`, `UPLOADTHING_TOKEN` — optional; leave blank to disable those features.
   - `POLAR_PRODUCT_ID`, `POLAR_ACCESS_TOKEN`, `POLAR_WEBHOOK_SECRET` — optional; leave blank to disable billing/checkout. When unset, sign-up still works (the app only auto-creates a Polar customer when `POLAR_ACCESS_TOKEN` is present).
3. In the Coolify UI, assign a domain to the `backend` service and a domain to the `frontend` service, and make sure both are served over HTTPS (Coolify's built-in Let's Encrypt handles this). Coolify auto-detects each service's internal port from `expose` in `docker-compose.yaml` (5000 for backend, 3000 for frontend) and routes to it through its own Traefik proxy — **the compose file intentionally does not bind these to fixed host ports**, since a shared VPS usually has other apps already using common ports like 3000; Coolify's proxy avoids that conflict entirely.
4. Deploy. Coolify will build all three images and start them on an internal network; `backend` reaches Mongo at `mongo:27017`, and the browser reaches `backend` at whatever public domain you assigned to it (must match `VITE_API_URL`, see below).

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

The compose file uses `expose` (internal-only) rather than `ports`, matching how Coolify's proxy expects it — so `docker compose up` alone won't publish anything to your host. To test locally, add a small override with `ports` mappings:

```bash
cp .env.example .env   # fill in real values, or use localhost defaults for a local smoke test
cat > docker-compose.override.yaml << 'EOF'
services:
  backend:
    ports:
      - "5000:5000"
  frontend:
    ports:
      - "3000:3000"
EOF
docker compose up --build
```

`docker-compose.override.yaml` is picked up automatically by `docker compose` and is gitignored — don't commit it, since Coolify must not see host port bindings.
