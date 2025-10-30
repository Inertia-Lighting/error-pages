Inertia Error Pages
===================

This repository holds static error pages and tooling to produce HAProxy-compatible error responses.

Files of interest
-----------------

- `pages/*.html` — source HTML error pages (400, 401, 403, 404, 500, 502, 503, 504)
- `pages/haproxy/*.http` — generated HAProxy error files (status line + headers + HTML body)
- `scripts/generate_haproxy_errors.sh` — script to generate `.http` files from the HTML sources and optionally install to `/etc/haproxy/errors`
- `pages/index.html` — quick links to the pages for local preview

Quick start
-----------

1. Make the generator executable and run it (from repo root):

   chmod +x scripts/generate_haproxy_errors.sh
   ./scripts/generate_haproxy_errors.sh

   This writes `.http` files to `pages/haproxy/` (one per numeric status code matching `pages/*.html`).

2. Preview a generated file locally:

   On macOS you can open it directly:

   open pages/haproxy/404.http

   Or serve the `pages` folder and visit in a browser:

   python3 -m http.server 8000
   # then open http://localhost:8000/pages/haproxy/404.http

Install into HAProxy
--------------------

To install the generated files into the global HAProxy errors directory (usually `/etc/haproxy/errors`), run:

   sudo ./scripts/generate_haproxy_errors.sh --install

The script will copy the files to `/etc/haproxy/errors` and set appropriate permissions.

HAProxy configuration snippet
----------------------------

Example `haproxy.cfg` fragment to use the files:

   defaults
     mode http
     timeout client  50s
     timeout server  50s

   frontend http_front
     bind *:80
     default_backend app

   backend app
     server app1 127.0.0.1:8080

   # Map errors to files
   errorfile 400 /etc/haproxy/errors/400.http
   errorfile 401 /etc/haproxy/errors/401.http
   errorfile 403 /etc/haproxy/errors/403.http
   errorfile 404 /etc/haproxy/errors/404.http
   errorfile 500 /etc/haproxy/errors/500.http
   errorfile 502 /etc/haproxy/errors/502.http
   errorfile 503 /etc/haproxy/errors/503.http
   errorfile 504 /etc/haproxy/errors/504.http

Notes and troubleshooting
-------------------------

- The generator writes HTTP/1.0 status lines and a small set of headers (Cache-Control, Content-Type, Connection). HAProxy expects a full response in these files.
- If you see `env: bash\r: No such file or directory` when running the script on macOS, convert the script to Unix line endings:

   sed -i '' -e $'s/\\r$//' scripts/generate_haproxy_errors.sh
   chmod +x scripts/generate_haproxy_errors.sh

- The script skips non-3-digit filenames (like `index.html`). Files named `400.html` -> `400.http`.
- Customize messages in the `pages/*.html` sources and re-run the generator.

Contributing
------------

If you add more error pages, follow the naming pattern `NNN.html` (where `NNN` is the three-digit status code). Run the generator to produce the HAProxy `.http` file.
