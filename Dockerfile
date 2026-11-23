FROM debian:bookworm-slim

# zvps-mini-ttyd: a minimal shell sandbox for Hostless-style app platforms.
# Built from stock Debian so the image contains ONLY the packages listed
# below - no cloudflared, no EasyTier, no sing-box, no hysteria, no xray:
# no proxy, VPN or tunnel software.
#
# BEFORE DEPLOYING: replace CHANGEME in this file and in supervisord.conf
# with your own password (both places must match your intent: the user
# passwords here, the web-terminal login in supervisord.conf).
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server supervisor \
    curl wget sudo ca-certificates openssl tzdata vim git python3 \
    busybox dnsutils iperf3 jq htop tmux socat netcat-openbsd mtr-tiny less lsof \
    && rm -rf /var/lib/apt/lists/*

# ttyd is not in Debian's main repo section; fetch the pinned upstream
# static binary instead. (Or vendor it into the repo and COPY it.)
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -o /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# Some app platforms give containers a read-only /etc at runtime, so bake
# the user and passwords at build time; supervisord's writable paths /tmp.
RUN useradd -m -s /bin/bash zv; \
    echo 'zv:CHANGEME' | chpasswd; \
    echo 'root:CHANGEME' | chpasswd; \
    echo 'zv ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/zv; \
    mkdir -p /run/sshd; \
    ssh-keygen -A

# TCP-based ping shim (real ICMP ping is impossible where the platform
# drops CAP_NET_RAW).
COPY ping /usr/local/bin/ping
RUN chmod +x /usr/local/bin/ping

COPY supervisord.conf /usr/local/etc/hostless-supervisord.conf

ENTRYPOINT []
CMD ["/usr/bin/supervisord", "-n", "-c", "/usr/local/etc/hostless-supervisord.conf"]
