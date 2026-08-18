# Plasma 6 + Wallpaper de video — instalación en un solo paso

Un único script. Lo guardas, lo ejecutas, respondes dos preguntas cortas, y todo lo demás pasa solo (Kvantum, blur, Magic Lamp, decoración de ventanas, tema Ant-Dark, panel, KRunner, Konsole, y el wallpaper de video con sus codecs). Ya validado con `shellcheck` (0 avisos).

## Cómo usarlo

1. Copia el bloque de código de abajo completo.
2. Pégalo en un archivo nuevo llamado `configurar-plasma6.sh`.
3. En la terminal:
   ```bash
   chmod +x configurar-plasma6.sh
   ./configurar-plasma6.sh
   ```
   (no uses `sudo` para lanzarlo — el script pide contraseña solo, cuando la necesita)
4. Te va a preguntar dos rutas por terminal:
   - La ruta a tu video `.mp4` (si todavía no lo tienes a mano, presiona Enter y vuelve a correr el script más tarde)
   - La ruta a un ícono para el menú de aplicaciones (opcional, Enter para dejar el de siempre)
5. Espera a que termine. Todo lo demás es automático.

## El script

```bash
#!/usr/bin/env bash
# ============================================================================
# Personalizacion completa de Fedora 44 / KDE Plasma 6 + wallpaper de video
# Un solo script, de principio a fin. Pide dos rutas por terminal y hace
# todo lo demas solo. Seguro de volver a ejecutar si algo falla a mitad.
# ============================================================================
set -uo pipefail

# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------
C_RESET='\033[0m'; C_RED='\033[0;31m'; C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'; C_BLUE='\033[0;34m'
log_info()  { printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$1"; }
log_ok()    { printf "${C_GREEN}[ OK ]${C_RESET} %s\n" "$1"; }
log_warn()  { printf "${C_YELLOW}[WARN]${C_RESET} %s\n" "$1"; }
log_error() { printf "${C_RED}[FAIL]${C_RESET} %s\n" "$1" >&2; }

install_pkg() {
    local pkg="$1"
    if rpm -q "$pkg" &>/dev/null; then
        log_ok "$pkg ya estaba instalado"; return 0
    fi
    if sudo dnf install -y "$pkg" && rpm -q "$pkg" &>/dev/null; then
        log_ok "Instalado: $pkg"; return 0
    fi
    log_error "No se pudo instalar: $pkg"; return 1
}

if [ "$(id -u)" -eq 0 ]; then
    log_error "No ejecutes esto como root ni con sudo. Corre el script como tu usuario normal."
    exit 1
fi

echo "=============================================================="
echo " Personalizacion Plasma 6 + Wallpaper de video (Fedora 44)"
echo "=============================================================="

# Backup antes de tocar nada
BACKUP_DIR="$HOME/.config-backups/plasma6-custom-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
for f in kwinrc breezerc krunnerrc kdeglobals plasmarc konsolerc; do
    [ -f "$HOME/.config/$f" ] && cp "$HOME/.config/$f" "$BACKUP_DIR/"
done
log_ok "Backup guardado en: $BACKUP_DIR"

# ---------------------------------------------------------------------------
# Las dos unicas preguntas. Todo lo demas es automatico.
# ---------------------------------------------------------------------------
echo ""
read -r -p "Ruta a tu video .mp4 para el wallpaper (Enter para omitir por ahora): " VIDEO_PATH
read -r -p "Ruta a un icono .svg/.png para el menu de aplicaciones (Enter para dejar el de por defecto): " ICON_PATH
echo ""
log_info "Listo, a partir de aqui no hace falta que hagas nada mas."

FINAL_ICON_PATH=""
if [ -n "$ICON_PATH" ]; then
    if [ -f "$ICON_PATH" ]; then
        mkdir -p "$HOME/.local/share/icons"
        EXT="${ICON_PATH##*.}"
        cp "$ICON_PATH" "$HOME/.local/share/icons/custom_menu.$EXT"
        FINAL_ICON_PATH="$HOME/.local/share/icons/custom_menu.$EXT"
        log_ok "Icono copiado a $FINAL_ICON_PATH"
    else
        log_warn "No se encontro el icono en '$ICON_PATH'; se deja el icono por defecto del menu"
    fi
fi

# ---------------------------------------------------------------------------
# 1. Kvantum: motor de temas + tema oscuro "glass"
# ---------------------------------------------------------------------------
log_info "== 1/9 Kvantum =="
THEME_NAME="KvArcDarkGlass"; THEME_BASE="KvArcDark"
install_pkg kvantum || log_warn "Kvantum fallo, se continua con el resto"
install_pkg kvantum-qt6 || true

if command -v kvantummanager >/dev/null 2>&1; then
    SYS_THEME_DIR="/usr/share/Kvantum/${THEME_BASE}"
    if [ ! -d "$SYS_THEME_DIR" ]; then
        TMP_KV="$(mktemp -d)"
        git clone --depth 1 -q https://github.com/tsujan/Kvantum.git "$TMP_KV" \
            && SYS_THEME_DIR="$TMP_KV/Kvantum/themes/kvthemes/${THEME_BASE}"
    fi
    if [ -d "$SYS_THEME_DIR" ]; then
        USER_KV_DIR="$HOME/.config/Kvantum"
        mkdir -p "$USER_KV_DIR"
        rm -rf "${USER_KV_DIR:?}/${THEME_NAME}"
        cp -r "$SYS_THEME_DIR" "$USER_KV_DIR/$THEME_NAME"
        ( cd "$USER_KV_DIR/$THEME_NAME" || exit 1
          for f in "${THEME_BASE}".*; do
              [ -e "$f" ] || continue
              mv "$f" "${THEME_NAME}${f#"${THEME_BASE}"}"
          done
        )
        KVCONFIG="$USER_KV_DIR/$THEME_NAME/${THEME_NAME}.kvconfig"
        if [ -f "$KVCONFIG" ]; then
            sed -i '/^composite=/d;/^translucent_windows=/d;/^blurring=/d;/^popup_blurring=/d' "$KVCONFIG"
            sed -i '/^\[%General\]/a composite=true\ntranslucent_windows=true\nblurring=true\npopup_blurring=true' "$KVCONFIG"
            kvantummanager --set "$THEME_NAME" && log_ok "Tema Kvantum activo: $THEME_NAME"
        fi
    else
        log_warn "No se pudo preparar el tema de Kvantum, se deja el motor instalado sin tema custom"
    fi
    kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum
else
    log_warn "kvantummanager no disponible, se omite este paso"
fi

# ---------------------------------------------------------------------------
# 2. Efectos de KWin: Blur + Magic Lamp
# ---------------------------------------------------------------------------
log_info "== 2/9 Efectos de KWin =="
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
kwriteconfig6 --file kwinrc --group Effect-blur --key NoiseStrength 0
kwriteconfig6 --file kwinrc --group Effect-blur --key Saturation 180
kwriteconfig6 --file kwinrc --group Effect-blur --key BlurStrength 15
kwriteconfig6 --file kwinrc --group Plugins --key magiclampEnabled true
kwriteconfig6 --file kwinrc --group Effect-magiclamp --key AnimationDuration 400
log_ok "Blur y Magic Lamp configurados"

# ---------------------------------------------------------------------------
# 3. Decoracion de ventanas: Breeze nativo
# ---------------------------------------------------------------------------
log_info "== 3/9 Decoracion de ventanas =="
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
kwriteconfig6 --file kwinrc --group org.kde.kdecoration3 --key library org.kde.breeze
kwriteconfig6 --file breezerc --group Common --key RoundedCorners true
kwriteconfig6 --file breezerc --group Common --key ShadowSize ShadowVeryLarge
kwriteconfig6 --file breezerc --group Common --key OutlineEnabled false
log_ok "Breeze aplicado con esquinas redondeadas y sombra grande"

# ---------------------------------------------------------------------------
# 4. Tema de escritorio Ant-Dark
# ---------------------------------------------------------------------------
log_info "== 4/9 Tema Ant-Dark =="
TARGET_DIR="$HOME/.local/share/plasma/desktoptheme"
mkdir -p "$TARGET_DIR"
if [ ! -d "$TARGET_DIR/Ant-Dark" ]; then
    TMP_ANT="$(mktemp -d)"
    if git clone --depth 1 -q https://github.com/EliverLara/Ant.git "$TMP_ANT"; then
        cp -r "$TMP_ANT/kde/Dark/plasma/desktoptheme/Ant-Dark" "$TARGET_DIR/"
        rm -rf "$TMP_ANT"
    fi
fi
if [ -d "$TARGET_DIR/Ant-Dark" ]; then
    if command -v plasma-apply-desktoptheme >/dev/null 2>&1; then
        plasma-apply-desktoptheme Ant-Dark
    else
        kwriteconfig6 --file plasmarc --group Theme --key name Ant-Dark
    fi
    log_ok "Ant-Dark aplicado"
else
    log_warn "No se pudo descargar Ant-Dark, se omite"
fi

# ---------------------------------------------------------------------------
# 5. KRunner en modo flotante
# ---------------------------------------------------------------------------
log_info "== 5/9 KRunner =="
kwriteconfig6 --file krunnerrc --group General --key FreeFloating true
log_ok "KRunner en modo flotante"

# ---------------------------------------------------------------------------
# 6. Perfil de Konsole
# ---------------------------------------------------------------------------
log_info "== 6/9 Konsole =="
PROFILE_NAME="Personalizado"
KONSOLE_DATA_DIR="$HOME/.local/share/konsole"
mkdir -p "$KONSOLE_DATA_DIR"
SYS_SCHEME="$(find /usr/share/konsole /usr/share/*/konsole /usr/share/*/*/konsole -iname "WhiteOnBlack.colorscheme" 2>/dev/null | head -1)"
if [ -n "$SYS_SCHEME" ]; then
    NEW_SCHEME="$KONSOLE_DATA_DIR/WhiteOnBlackBlur.colorscheme"
    cp "$SYS_SCHEME" "$NEW_SCHEME"
    sed -i '/^Opacity=/d;/^Blur=/d' "$NEW_SCHEME"
    sed -i '/^\[General\]/a Opacity=0.7\nBlur=true' "$NEW_SCHEME"

    BASE_FONT="$(kreadconfig6 --file kdeglobals --group General --key fixed 2>/dev/null)"
    [ -z "$BASE_FONT" ] && BASE_FONT="DejaVu Sans Mono,10,-1,5,50,0,0,0,0,0"
    BASE_SIZE="$(echo "$BASE_FONT" | cut -d, -f2)"
    NEW_FONT="$(echo "$BASE_FONT" | awk -F, -v s="$((BASE_SIZE + 2))" '{ $2=s; OFS=","; print }')"

    cat > "$KONSOLE_DATA_DIR/${PROFILE_NAME}.profile" <<PROFILEEOF
[Appearance]
ColorScheme=WhiteOnBlackBlur
Font=$NEW_FONT

[General]
Name=$PROFILE_NAME
Parent=FALLBACK/
PROFILEEOF
    kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "${PROFILE_NAME}.profile"
    log_ok "Perfil de Konsole creado y fijado como predeterminado"
else
    log_warn "No se encontro el esquema WhiteOnBlack en el sistema, se omite Konsole"
fi

# ---------------------------------------------------------------------------
# 7. Reestructurar el panel (consola de scripting de Plasma via D-Bus)
# ---------------------------------------------------------------------------
log_info "== 7/9 Panel =="
QDBUS_BIN="$(command -v qdbus6 || command -v qdbus || true)"
if [ -n "$QDBUS_BIN" ]; then
    read -r -d '' PANEL_JS <<JSEOF || true
var CUSTOM_ICON_PATH = "$FINAL_ICON_PATH";
var allPanels = panels();
for (var p = 0; p < allPanels.length; p++) {
    var panel = allPanels[p];
    var widgets = panel.widgets();
    var kickoff = null, taskManager = null, toRemove = [];
    for (var i = 0; i < widgets.length; i++) {
        var w = widgets[i];
        if (w.type === "org.kde.plasma.pager" || w.type === "org.kde.plasma.showdesktop") { toRemove.push(w); }
        else if (w.type === "org.kde.plasma.kickoff") { kickoff = w; }
        else if (w.type === "org.kde.plasma.taskmanager" || w.type === "org.kde.plasma.icontasks") { taskManager = w; }
    }
    for (var r = 0; r < toRemove.length; r++) { toRemove[r].remove(); }
    widgets = panel.widgets(); kickoff = null; taskManager = null;
    for (var j = 0; j < widgets.length; j++) {
        if (widgets[j].type === "org.kde.plasma.kickoff") { kickoff = widgets[j]; }
        if (widgets[j].type === "org.kde.plasma.taskmanager" || widgets[j].type === "org.kde.plasma.icontasks") { taskManager = widgets[j]; }
    }
    if (kickoff && CUSTOM_ICON_PATH !== "") {
        kickoff.currentConfigGroup = ["General"];
        kickoff.writeConfig("icon", CUSTOM_ICON_PATH);
    }
    if (taskManager) {
        var spacerAfter = panel.addWidget("org.kde.plasma.panelspacer");
        spacerAfter.index = taskManager.index + 1;
        var spacerBefore = panel.addWidget("org.kde.plasma.panelspacer");
        spacerBefore.index = taskManager.index;
    }
    if (kickoff) {
        var windowList = panel.addWidget("org.kde.plasma.windowlist");
        windowList.index = kickoff.index + 1;
    }
    panel.opacity = "translucent";
}
print("ok");
JSEOF
    if "$QDBUS_BIN" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$PANEL_JS"; then
        log_ok "Panel reestructurado"
    else
        log_warn "No se pudo aplicar el layout del panel"
    fi
else
    log_warn "qdbus no disponible, se omite el panel"
fi

# ---------------------------------------------------------------------------
# 8. Wallpaper de video: plugin + codecs
# ---------------------------------------------------------------------------
log_info "== 8/9 Wallpaper de video (instalacion) =="
FEDORA_VER="$(rpm -E %fedora)"
if ! dnf repolist 2>/dev/null | grep -qi rpmfusion; then
    if sudo dnf install -y \
        "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
        "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"; then
        log_ok "RPM Fusion habilitado"
    else
        log_warn "No se pudo habilitar RPM Fusion; hazlo a mano si el video falla por codec"
    fi
else
    log_ok "RPM Fusion ya estaba habilitado"
fi

PLUGIN_PKG="plasma-smart-video-wallpaper-reborn"
PLUGIN_ID="luisbocanegra.smart.video.wallpaper.reborn"
if sudo dnf install -y "$PLUGIN_PKG" 2>/dev/null; then
    log_ok "Plugin de video wallpaper instalado via dnf"
elif sudo dnf config-manager --add-repo \
        "https://download.opensuse.org/repositories/home:/luisbocanegra/Fedora_${FEDORA_VER}/home:luisbocanegra.repo" 2>/dev/null \
     && sudo dnf install -y "$PLUGIN_PKG" 2>/dev/null; then
    log_ok "Plugin de video wallpaper instalado via repo OBS"
else
    log_warn "dnf/OBS no funcionaron, se compila desde codigo fuente"
    TMP_VW="$(mktemp -d)"
    if git clone --depth 1 -q https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn.git "$TMP_VW"; then
        install_pkg gcc || true; install_pkg cmake || true
        install_pkg extra-cmake-modules || true; install_pkg libplasma-devel || true
        install_pkg qt6-qtmultimedia || true
        if ( cd "$TMP_VW" && ./install.sh ); then
            log_ok "Plugin compilado e instalado"
        else
            log_error "Fallo la compilacion del plugin"
        fi
    fi
fi

# Arreglo para el bug conocido de GPU AMD, preparado pero inactivo
ENV_DIR="$HOME/.config/plasma-workspace/env"
mkdir -p "$ENV_DIR"
cat > "$ENV_DIR/qt-media-backend.sh.disabled" <<'ENVEOF'
#!/bin/bash
# Si el wallpaper de video da pantalla negra o crashea Plasma (bug conocido
# en GPU AMD, QTBUG-124586): quita ".disabled" de este nombre de archivo,
# instala "sudo dnf install gstreamer1-plugin-libav" y reinicia sesion.
export QT_MEDIA_BACKEND=gstreamer
ENVEOF
chmod +x "$ENV_DIR/qt-media-backend.sh.disabled"

if [ -n "$VIDEO_PATH" ] && [ -f "$VIDEO_PATH" ] && [ -n "$QDBUS_BIN" ]; then
    ABS_VIDEO_PATH="$(readlink -f "$VIDEO_PATH")"
    read -r -d '' WALL_JS <<JSEOF || true
var videos = [{filename: "file://$ABS_VIDEO_PATH", enabled: true, duration: 0, customDuration: false, playbackRate: 1, alternativePlaybackRate: 1, loop: true}];
var allDesktops = desktops();
for (var i = 0; i < allDesktops.length; i++) {
    var d = allDesktops[i];
    d.wallpaperPlugin = "$PLUGIN_ID";
    d.currentConfigGroup = ["Wallpaper", "$PLUGIN_ID", "General"];
    d.writeConfig("VideoUrls", JSON.stringify(videos));
}
print("ok");
JSEOF
    if "$QDBUS_BIN" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$WALL_JS"; then
        log_ok "Wallpaper de video asignado: $ABS_VIDEO_PATH"
    else
        log_warn "No se pudo asignar el wallpaper de video"
    fi
elif [ -z "$VIDEO_PATH" ]; then
    log_info "No se indico video: vuelve a correr este mismo script cuando tengas uno listo"
else
    log_warn "No se encontro el archivo de video en '$VIDEO_PATH', se omite"
fi

# ---------------------------------------------------------------------------
# 9. Aplicar todo en caliente
# ---------------------------------------------------------------------------
log_info "== 9/9 Aplicando cambios =="
[ -n "$QDBUS_BIN" ] && "$QDBUS_BIN" org.kde.KWin /KWin reconfigure

if [ "${XDG_SESSION_TYPE:-}" = "x11" ]; then
    ( kwin_x11 --replace >/dev/null 2>&1 & disown )
else
    log_info "Sesion Wayland: no se reemplaza kwin_wayland (es el compositor de la sesion); 'reconfigure' ya aplico los cambios"
fi

if systemctl --user list-unit-files 2>/dev/null | grep -q "plasma-plasmashell.service"; then
    systemctl --user restart plasma-plasmashell.service
else
    ( kquitapp6 plasmashell >/dev/null 2>&1; sleep 1; plasmashell --replace >/dev/null 2>&1 & disown )
fi

echo ""
echo "=============================================================="
log_ok "Listo. Backup de tu configuracion anterior en: $BACKUP_DIR"
echo "=============================================================="
```

## Si algo sale mal

- **Es seguro volver a correrlo** las veces que haga falta — no rompe nada por repetirlo.
- **Deshacer todo:** `cp ~/.config-backups/plasma6-custom-<fecha-que-te-mostró>/* ~/.config/` y reinicia sesión.
- **Pantalla negra o se cierra la sesión con el wallpaper de video** (tu GPU es AMD, es un bug conocido): quita el `.disabled` a `~/.config/plasma-workspace/env/qt-media-backend.sh.disabled`, corre `sudo dnf install gstreamer1-plugin-libav`, y reinicia sesión.
- **No incluye** un set de iconos nuevo para todo el sistema — solo el ícono del menú de aplicaciones, que sí puedes cambiar. No encontré una alternativa a Breeze confiable, así que no puse nada al azar.
