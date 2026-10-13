#!/usr/bin/env bash
# fedora-clean.sh — Actualiza y limpia Fedora a fondo (dnf4/dnf5, flatpak, journal, cachés...)
# Uso: sudo ./fedora-clean.sh [opciones]
#   -n, --dry-run      Muestra lo que haría sin ejecutar nada destructivo
#   -y, --yes          No pedir confirmaciones (-y a dnf)
#   -a, --aggressive   Limpieza extra: journal 3d, ~/.cache completo, podman/docker prune -a, pip/npm/cargo caches
#   -k, --keep-kernels N  Kernels a conservar (por defecto 2)
#   -h, --help
set -uo pipefail

# ---------- Config ----------
KEEP_KERNELS=2
JOURNAL_DAYS=7
JOURNAL_MAX="200M"
DRY=0; YES=0; AGGR=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) DRY=1 ;;
    -y|--yes) YES=1 ;;
    -a|--aggressive) AGGR=1; JOURNAL_DAYS=3; JOURNAL_MAX="100M" ;;
    -k|--keep-kernels) shift; KEEP_KERNELS="${1:-2}" ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "Opción desconocida: $1"; exit 1 ;;
  esac
  shift
done

# ---------- Helpers ----------
R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; B=$'\e[34m'; N=$'\e[0m'
log()  { echo -e "${B}==>${N} $*"; }
ok()   { echo -e "${G} ✔${N} $*"; }
warn() { echo -e "${Y} !${N} $*"; }
run()  { if (( DRY )); then echo -e "${Y}[dry]${N} $*"; else eval "$@"; fi; }
have() { command -v "$1" &>/dev/null; }

if [[ $EUID -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

REAL_USER="${SUDO_USER:-root}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
DNF_Y=""; (( YES )) && DNF_Y="-y"
as_user() { sudo -u "$REAL_USER" env HOME="$REAL_HOME" "$@"; }

DNF_VER=4
if dnf --version 2>/dev/null | grep -qi 'dnf5'; then DNF_VER=5; fi

used_before=$(df --output=used -B1 / | tail -1)
LOG="/var/log/fedora-clean-$(date +%F_%H%M).log"
exec > >(tee -a "$LOG") 2>&1
log "Fedora $(rpm -E %fedora) | dnf$DNF_VER | usuario: $REAL_USER | dry-run=$DRY aggressive=$AGGR"
log "Log: $LOG"

# ---------- 1. Actualización ----------
log "Actualizando paquetes del sistema"
run "dnf $DNF_Y upgrade --refresh"

if have fwupdmgr; then
  log "Firmware (fwupd)"
  run "fwupdmgr refresh --force >/dev/null 2>&1"
  run "fwupdmgr get-updates >/dev/null 2>&1 && fwupdmgr update ${YES:+--assume-yes --no-reboot-check} || true"
fi

if have flatpak; then
  log "Flatpak: actualizar, reparar y quitar runtimes sin uso"
  run "flatpak update -y"
  run "flatpak uninstall --unused -y"
  run "flatpak repair"
  as_user flatpak --user list &>/dev/null && {
    run "as_user flatpak --user update -y"
    run "as_user flatpak --user uninstall --unused -y"
  }
fi

if have snap; then
  log "Snap: eliminar revisiones desactivadas"
  snap list --all | awk '/disabled/{print $1, $3}' | while read -r name rev; do
    run "snap remove '$name' --revision='$rev'"
  done
fi

# ---------- 2. Paquetes ----------
log "Eliminando dependencias huérfanas"
run "dnf $DNF_Y autoremove"

log "Eliminando kernels antiguos (conservando $KEEP_KERNELS)"
if (( DNF_VER == 5 )); then
  run "dnf $DNF_Y remove --oldinstallonly --setopt=installonly_limit=$KEEP_KERNELS || true"
else
  old=$(dnf repoquery --installonly --latest-limit=-"$KEEP_KERNELS" -q 2>/dev/null)
  [[ -n "$old" ]] && run "dnf $DNF_Y remove $old" || ok "No hay kernels antiguos"
fi

log "Paquetes duplicados / dependencias rotas"
run "dnf check 2>&1 | head -20 || true"
run "dnf $DNF_Y distro-sync --refresh 2>/dev/null || true"

log "Archivos .rpmnew/.rpmsave pendientes de revisar (no se borran)"
find /etc -xdev \( -name '*.rpmnew' -o -name '*.rpmsave' \) 2>/dev/null | sed 's/^/   /'

log "Limpiando caché de dnf"
run "dnf clean all"
run "rm -rf /var/cache/libdnf5/* /var/cache/dnf/* 2>/dev/null || true"

# ---------- 3. Logs y volcados ----------
log "Journal: máx. ${JOURNAL_DAYS} días / ${JOURNAL_MAX}"
run "journalctl --rotate"
run "journalctl --vacuum-time=${JOURNAL_DAYS}d --vacuum-size=${JOURNAL_MAX}"

log "Core dumps y logs rotados"
run "rm -rf /var/lib/systemd/coredump/* 2>/dev/null || true"
run "find /var/log -type f \( -name '*.gz' -o -name '*.[0-9]' -o -name '*.old' -o -name '*-20*' \) -delete 2>/dev/null || true"
have abrt-cli && run "rm -rf /var/spool/abrt/* /var/tmp/abrt/* 2>/dev/null || true"

# ---------- 4. Temporales ----------
log "Temporales antiguos (/tmp >3d, /var/tmp >7d)"
run "find /tmp -xdev -type f -atime +3 -delete 2>/dev/null || true"
run "find /var/tmp -xdev -type f -atime +7 -delete 2>/dev/null || true"

# ---------- 5. Caché y basura del usuario ----------
log "Limpieza de usuario ($REAL_USER)"
run "rm -rf '$REAL_HOME/.local/share/Trash/'* 2>/dev/null || true"
run "rm -rf '$REAL_HOME/.cache/thumbnails/'* 2>/dev/null || true"
run "find '$REAL_HOME/.cache' -type f -atime +30 -delete 2>/dev/null || true"
run "rm -f '$REAL_HOME/.xsession-errors'* 2>/dev/null || true"

# Cachés de herramientas de desarrollo
if have pip3; then run "as_user pip3 cache purge 2>/dev/null || true"; fi
if have npm;  then run "as_user npm cache clean --force 2>/dev/null || true"; fi
if have yarn; then run "as_user yarn cache clean 2>/dev/null || true"; fi
if have cargo-cache; then run "as_user cargo cache -a 2>/dev/null || true"; fi

# Contenedores
for ct in podman docker; do
  if have "$ct"; then
    log "$ct: prune"
    if (( AGGR )); then
      run "$ct system prune -af --volumes"
      [[ $ct == podman ]] && run "as_user podman system prune -af --volumes 2>/dev/null || true"
    else
      run "$ct system prune -f"
    fi
  fi
done

if (( AGGR )); then
  warn "Modo agresivo: borrando ~/.cache completo y cachés de navegador"
  run "rm -rf '$REAL_HOME/.cache/'* 2>/dev/null || true"
  have gem && run "as_user gem cleanup 2>/dev/null || true"
fi

# ---------- 6. Sistema ----------
if have fstrim; then
  log "fstrim en todos los sistemas de ficheros"
  run "fstrim -av"
fi

have updatedb && { log "Reconstruyendo base de datos locate"; run "updatedb"; }
run "systemctl --failed --no-pager || true"

# ---------- Resumen ----------
used_after=$(df --output=used -B1 / | tail -1)
freed=$(( (used_before - used_after) / 1024 / 1024 ))
echo
ok "Limpieza terminada. Espacio liberado en /: ~${freed} MiB"
df -h / | tail -1

if have dnf; then
  if ! dnf needs-restarting -r &>/dev/null; then
    warn "Se recomienda REINICIAR (kernel/librerías críticas actualizadas)"
  fi
fi
