# zvps-mini-ttyd

A minimal, always-on **shell sandbox** for Hostless-style app platforms:
a stock-Debian container running `sshd` + a password-protected **ttyd**
web terminal + a small network toolset. Nothing else.

Notably absent — by construction, not by deletion: there is **no proxy,
VPN or tunnel software** in this image (no cloudflared, EasyTier,
sing-box, hysteria, xray, or similar). It is a shell, not a relay.

## What's inside

- Debian 12 (bookworm-slim) base
- `sshd` (inside the box; app platforms typically expose only one HTTPS
  port, so the web terminal is the way in)
- `ttyd` 1.7.7 (pinned upstream static binary) serving a root shell on
  port 7681 behind basic auth
- Toolset: busybox, dnsutils, iperf3, jq, htop, tmux, socat, netcat,
  mtr-tiny, less, lsof, curl, wget, git, vim, python3
- A TCP-based `ping` shim (see below)

## Deploy (Hostless)

1. **Replace `CHANGEME`** in `Dockerfile` (user passwords) and in
   `supervisord.conf` (web-terminal login) with your own password.
2. Create an app from this repo, set build system to **Docker**,
   container port **7681**, and give it ~0.4 vCPU / 768 MB.
3. Open `https://<your-app>.hostless.app` and log in as `admin`.

## Platform constraints this design works around

Measured on Hostless (Kubernetes-based app containers):

- **Read-only root filesystem at runtime.** Nothing can be installed or
  written outside scratch space (`/tmp`), so users/passwords are baked
  in at build time and supervisord keeps its writable paths in `/tmp`.
  Nothing survives a redeploy — the repo is the source of truth.
- **`CAP_NET_RAW` dropped.** Real ICMP `ping`/`mtr` cannot work. The
  bundled `ping` shim times TCP connects instead
  (`ping [-c count] [-p port] host`, default port 443); use
  `mtr --tcp` / `mtr --udp` for the same reason.
- **`CAP_SETUID`/`CAP_SETGID` dropped.** No process can switch users
  (supervisord reports `couldn't setuid ... Could not set groups`), so
  everything, including the terminal, runs as root.
- **ttyd 1.7.7 is read-only by default.** Without `-W` the terminal
  renders a prompt but swallows all input. The flag is set here.
- **Program logs** reach the platform log stream only when supervisord
  writes them to the container's stdout (`stdout_logfile=/dev/stdout`
  with `redirect_stderr=true`), as configured here.

## Files

- `Dockerfile` — the whole build
- `supervisord.conf` — sshd + ttyd under supervisord
- `ping` — the TCP ping shim (bash, no dependencies)

## License

MIT. ttyd is a separate upstream project (MIT, (c) Shuanglei Tao);
this repo only downloads its release binary at build time.
