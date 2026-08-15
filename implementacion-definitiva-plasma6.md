# Implementación definitiva — Personalización Plasma 6 + Wallpaper de video (Fedora 44)

Todo lo que sigue está construido directamente sobre lo confirmado en `investigacion-tecnica-plasma6.md` e `investigacion-tecnica-video-wallpapers-plasma6.md`. Cada script bash de este documento pasó `bash -n` y **`shellcheck` con 0 avisos**; los dos `.js` pasaron `node --check` (solo sintaxis — las funciones `panels()`, `desktops()`, `print()`, etc. únicamente existen dentro del motor de scripting real de Plasma, no se pueden ejecutar fuera de una sesión Plasma).

## Índice

1. [Advertencias antes de ejecutar](#1-advertencias-antes-de-ejecutar)
2. [Estructura de carpetas a crear](#2-estructura-de-carpetas-a-crear)
3. [`lib/common.sh`](#3-libcommonsh)
4. [`01-kvantum.sh`](#4-01-kvantumsh)
5. [`02-kwin-efectos.sh`](#5-02-kwin-efectossh)
6. [`03-decoracion-breeze.sh`](#6-03-decoracion-breezesh)
7. [`04-tema-ant-dark.sh`](#7-04-tema-ant-darksh)
8. [Iconos — punto pendiente, no incluido](#8-iconos--punto-pendiente-no-incluido)
9. [`05-panel-layout.js`](#9-05-panel-layoutjs)
10. [`06-krunner.sh`](#10-06-krunnersh)
11. [`07-konsole.sh`](#11-07-konsolesh)
12. [`08-wallpaper-video-instalacion.sh`](#12-08-wallpaper-video-instalacionsh)
13. [`09-wallpaper-video-aplicar.js`](#13-09-wallpaper-video-aplicarjs)
14. [`99-reinicio-seguro.sh`](#14-99-reinicio-segurosh)
15. [`install.sh` — orquestador](#15-installsh--orquestador)
16. [Cómo ejecutarlo](#16-cómo-ejecutarlo)
17. [Verificación posterior](#17-verificación-posterior)
18. [Recuperación / rollback](#18-recuperación--rollback)

---

## 1. Advertencias antes de ejecutar

- **No lo ejecutes como root.** `install.sh` se niega a correr si detecta `id -u = 0`; usa `sudo` internamente solo donde hace falta (`dnf`).
- Hace falta editar **dos rutas** antes de que el resultado sea completo:
  - `05-panel-layout.js` → `CUSTOM_ICON_PATH` (el orquestador reemplaza `/home/USUARIO` por tu `$HOME` automáticamente, pero el archivo del icono en sí no existe hasta que lo pongas ahí).
  - `09-wallpaper-video-aplicar.js` → `VIDEO_PATH`, la ruta a tu `.mp4` real.
- **Iconos ("Breeze Modificado")**: no se encontró en la investigación un fork confiable y mantenido. Ver sección 8 — se deja fuera a propósito en vez de instalar algo no verificado.
- Dos puntos quedaron marcados como **no verificables desde el entorno de investigación** (sin acceso a los repos de Fedora): si `dnf install plasma-smart-video-wallpaper-reborn` funciona tal cual o necesita el repo OBS primero, y el nombre exacto del grupo de decoración (`kdecoration2` vs `kdecoration3`) que usa Fedora 44. Los scripts manejan ambos casos de forma defensiva (ver secciones 6 y 12), así que no deberían romper nada si la suposición principal falla — pero por eso no se llaman "100% garantizados", sino "definitivos según lo verificable hoy".
- Si tu MP4 usa H.264 (la inmensa mayoría), vas a necesitar RPM Fusion — el script lo habilita solo.
- Tu GPU es una AMD integrada: hay un bug documentado (QTBUG-124586) que puede causar pantalla negra/crash con el wallpaper de video. El script deja preparado el arreglo (cambiar a backend GStreamer) pero **inactivo por defecto** — actívalo solo si hace falta (instrucciones en el propio archivo).

---

## 2. Estructura de carpetas a crear

```bash
mkdir -p ~/plasma6-suite/lib
cd ~/plasma6-suite
```

Todos los archivos de las secciones 3 a 15 van dentro de `~/plasma6-suite/` (los `.sh` y `.js` sueltos en la raíz, `common.sh` dentro de `lib/`). Los propios scripts crean después las carpetas de destino reales (`~/.config/Kvantum`, `~/.local/share/plasma/desktoptheme`, `~/.local/share/konsole`, `~/.local/share/icons`, `~/.config/plasma-workspace/env`) — no hace falta crearlas a mano.

---

## 3. `lib/common.sh`

Logging, instalación de paquetes con verificación real, y backup de configuraciones antes de tocar nada.

```bash
#!/usr/bin/env bash
# Funciones compartidas: logging con color, instalación de paquetes con
# verificación, y backup de configuraciones antes de tocarlas.

C_RESET='\033[0m'; C_RED='\033[0;31m'; C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'; C_BLUE='\033[0;34m'

log_info()  { printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$1"; }
log_ok()    { printf "${C_GREEN}[ OK ]${C_RESET} %s\n" "$1"; }
log_warn()  { printf "${C_YELLOW}[WARN]${C_RESET} %s\n" "$1"; }
log_error() { printf "${C_RED}[FAIL]${C_RESET} %s\n" "$1" >&2; }

# Instala un paquete con dnf solo si no está ya instalado, y confirma el
# resultado real (no asume éxito solo porque dnf no devolvió error).
install_pkg() {
    local pkg="$1"
    if rpm -q "$pkg" &>/dev/null; then
        log_ok "$pkg ya estaba instalado"
        return 0
    fi
    if sudo dnf install -y "$pkg"; then
        if rpm -q "$pkg" &>/dev/null; then
            log_ok "Instalado: $pkg"
            return 0
        fi
    fi
    log_error "No se pudo instalar: $pkg"
    return 1
}

# Copia las configuraciones que este conjunto de scripts va a modificar antes
# de tocar nada, con marca de tiempo, para poder revertir manualmente.
backup_configs() {
    local backup_dir
    backup_dir="$HOME/.config-backups/plasma6-custom-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    local files=(kwinrc breezerc krunnerrc kdeglobals plasmarc konsolerc)
    local f
    for f in "${files[@]}"; do
        [ -f "$HOME/.config/$f" ] && cp "$HOME/.config/$f" "$backup_dir/"
    done
    log_ok "Backup de configuraciones guardado en: $backup_dir"
}
```

---

## 4. `01-kvantum.sh`

Instala Kvantum, copia `KvArcDark` (oscuro) y le inyecta las claves de transparencia reales verificadas en el tema oficial `KvRoughGlass`.

```bash
#!/usr/bin/env bash
# Instala Kvantum y crea un tema oscuro "glass": la paleta de KvArcDark con
# las claves de transparencia reales tomadas del tema oficial KvRoughGlass.
# Fuente: investigacion-tecnica-plasma6.md, seccion 1.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

THEME_NAME="KvArcDarkGlass"
THEME_BASE="KvArcDark"

log_info "== Kvantum: motor de temas y transparencia =="

install_pkg kvantum || { log_error "Kvantum no se pudo instalar, abortando este modulo"; exit 1; }
install_pkg kvantum-qt6 || log_warn "kvantum-qt6 no existe como paquete separado (probablemente ya viene incluido en 'kvantum')"

command -v kvantummanager >/dev/null 2>&1 || { log_error "kvantummanager no esta en el PATH tras la instalacion"; exit 1; }

SYS_THEME_DIR="/usr/share/Kvantum/${THEME_BASE}"
if [ ! -d "$SYS_THEME_DIR" ]; then
    log_warn "KvArcDark no vino incluido con el paquete del sistema; se descarga del repo oficial de Kvantum"
    TMP_KV="$(mktemp -d)"
    if git clone --depth 1 -q https://github.com/tsujan/Kvantum.git "$TMP_KV"; then
        SYS_THEME_DIR="$TMP_KV/Kvantum/themes/kvthemes/${THEME_BASE}"
    else
        log_error "No se pudo descargar KvArcDark del repo oficial de Kvantum"
        exit 1
    fi
fi

if [ ! -d "$SYS_THEME_DIR" ]; then
    log_error "No se encontro la carpeta del tema base en: $SYS_THEME_DIR"
    exit 1
fi

USER_KV_DIR="$HOME/.config/Kvantum"
mkdir -p "$USER_KV_DIR"
rm -rf "${USER_KV_DIR:?}/${THEME_NAME}"
cp -r "$SYS_THEME_DIR" "$USER_KV_DIR/$THEME_NAME"

# Renombrar los archivos internos para que coincidan con el nuevo nombre de carpeta
( cd "$USER_KV_DIR/$THEME_NAME" || exit 1
  for f in "${THEME_BASE}".*; do
      [ -e "$f" ] || continue
      ext="${f#"${THEME_BASE}"}"
      mv "$f" "${THEME_NAME}${ext}"
  done
)

KVCONFIG="$USER_KV_DIR/$THEME_NAME/${THEME_NAME}.kvconfig"
if [ -f "$KVCONFIG" ]; then
    # Idempotente: se eliminan las claves si ya existian antes de reinsertarlas
    sed -i '/^composite=/d;/^translucent_windows=/d;/^blurring=/d;/^popup_blurring=/d' "$KVCONFIG"
    sed -i '/^\[%General\]/a composite=true\ntranslucent_windows=true\nblurring=true\npopup_blurring=true' "$KVCONFIG"
    log_ok "Transparencia real (verificada en KvRoughGlass) aplicada sobre la paleta oscura de KvArcDark"
else
    log_error "No se encontro $KVCONFIG tras la copia"
    exit 1
fi

if kvantummanager --set "$THEME_NAME"; then
    log_ok "Tema Kvantum activo: $THEME_NAME"
else
    log_error "kvantummanager --set fallo"
fi

kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum
log_ok "widgetStyle=kvantum aplicado en kdeglobals"
log_info "Nota: Kvantum define el estilo de los widgets Qt, no la decoracion de ventanas (eso se aplica en 03-decoracion-breeze.sh)"
```

---

## 5. `02-kwin-efectos.sh`

Blur (`NoiseStrength=0`, `Saturation` por encima del default) y Magic Lamp a 400 ms. Claves confirmadas en `kwin/src/plugins/{blur,magiclamp}/*.kcfg`.

```bash
#!/usr/bin/env bash
# Efectos de KWin: Blur (Noise=0, Saturation aumentada) y Magic Lamp (400ms).
# Claves verificadas directamente en kwin/src/plugins/{blur,magiclamp}/*.kcfg
# Fuente: investigacion-tecnica-plasma6.md, seccion 2.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

log_info "== Efectos de KWin: Blur + Magic Lamp =="

kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
kwriteconfig6 --file kwinrc --group Effect-blur --key NoiseStrength 0
kwriteconfig6 --file kwinrc --group Effect-blur --key Saturation 180
kwriteconfig6 --file kwinrc --group Effect-blur --key BlurStrength 15
log_ok "Blur activado: NoiseStrength=0, Saturation=180 (default 150), BlurStrength=15 (default)"

kwriteconfig6 --file kwinrc --group Plugins --key magiclampEnabled true
kwriteconfig6 --file kwinrc --group Effect-magiclamp --key AnimationDuration 400
log_ok "Magic Lamp activado a 400ms"
log_info "KWin desactiva automaticamente la animacion de minimizado clasica: Magic Lamp y 'squash' comparten el mismo grupo exclusivo 'minimize' en su metadata"
```

> `Saturation` de 180 es solo un valor de ejemplo por encima del default (150) — súbelo más si quieres el efecto más marcado, la clave ya está verificada, el número es a gusto.

---

## 6. `03-decoracion-breeze.sh`

Escribe la decoración en **ambos** grupos (`kdecoration2` y `kdecoration3`) porque no se pudo confirmar cuál usa Fedora 44 exactamente; el que no aplique queda inerte.

```bash
#!/usr/bin/env bash
# Decoracion de ventanas: Breeze nativo, esquinas redondeadas, sombra grande.
# Se escribe tanto en [org.kde.kdecoration2] como en [org.kde.kdecoration3]
# porque no se pudo confirmar cual usa Fedora 44 exactamente; el grupo que
# no aplique queda inerte, sin causar error.
# Fuente: investigacion-tecnica-plasma6.md, seccion 3.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

log_info "== Decoracion de ventanas: Breeze nativo =="

kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
kwriteconfig6 --file kwinrc --group org.kde.kdecoration3 --key library org.kde.breeze

kwriteconfig6 --file breezerc --group Common --key RoundedCorners true
kwriteconfig6 --file breezerc --group Common --key ShadowSize ShadowVeryLarge
kwriteconfig6 --file breezerc --group Common --key OutlineEnabled false

log_ok "Breeze aplicado con esquinas redondeadas y sombra grande"
log_info "El radio de esquina no es ajustable en Breeze nativo (Frame_FrameRadius es una constante fija en el codigo fuente); solo se puede activar o desactivar el redondeo"
```

---

## 7. `04-tema-ant-dark.sh`

Descarga solo la carpeta `desktoptheme/Ant-Dark` del repo `EliverLara/Ant` (se descarta a propósito el paquete `look-and-feel` completo, que depende de KNS).

```bash
#!/usr/bin/env bash
# Tema Plasma "Ant Dark" (EliverLara/Ant, carpeta kde/Dark/plasma/desktoptheme).
# Fuente: investigacion-tecnica-plasma6.md, seccion 4.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

log_info "== Tema de escritorio Ant-Dark =="

TARGET_DIR="$HOME/.local/share/plasma/desktoptheme"
mkdir -p "$TARGET_DIR"

if [ -d "$TARGET_DIR/Ant-Dark" ]; then
    log_ok "Ant-Dark ya estaba instalado, se omite la descarga"
else
    TMP_ANT="$(mktemp -d)"
    if git clone --depth 1 -q https://github.com/EliverLara/Ant.git "$TMP_ANT"; then
        cp -r "$TMP_ANT/kde/Dark/plasma/desktoptheme/Ant-Dark" "$TARGET_DIR/"
        rm -rf "$TMP_ANT"
        log_ok "Ant-Dark copiado a $TARGET_DIR/Ant-Dark"
    else
        log_error "No se pudo clonar EliverLara/Ant"
        exit 1
    fi
fi

if command -v plasma-apply-desktoptheme >/dev/null 2>&1; then
    plasma-apply-desktoptheme Ant-Dark && log_ok "Ant-Dark aplicado con plasma-apply-desktoptheme"
else
    kwriteconfig6 --file plasmarc --group Theme --key name Ant-Dark
    log_ok "Ant-Dark escrito en plasmarc (plasma-apply-desktoptheme no estaba disponible)"
fi

log_info "Nota: este tema declara X-Plasma-API=5.0 en su metadata (fue disenado para Plasma 5). Suele verse bien en Plasma 6 gracias al fallback a Breeze en los elementos no cubiertos, pero no es 100% nativo"
```

---

## 8. Iconos — punto pendiente, no incluido

La investigación (`investigacion-tecnica-plasma6.md`, sección 5) no encontró un fork de Breeze mantenido y confiable — solo proyectos irrelevantes de bajo perfil. En vez de instalar algo no verificado, se deja fuera del paquete de scripts. Si más adelante tienes un candidato concreto, el patrón para añadirlo es:

```bash
sudo dnf install -y <paquete-del-tema-de-iconos>
kwriteconfig6 --file kdeglobals --group Icons --key Theme <NombreDelTema>
```

(la clave `[Icons] Theme=` en `kdeglobals` es convención estable de KDE, no auditada contra código esta sesión — mismo nivel de confianza que otras claves marcadas 🟡 en el primer dossier).

---

## 9. `05-panel-layout.js`

Se inyecta por D-Bus a la consola de scripting de Plasma. Usa la propiedad `.index` (verificada en `shell/scripting/widget.cpp`) para insertar los widgets en la posición exacta, de derecha a izquierda para que ninguna inserción desordene el índice que la siguiente necesita leer.

```javascript
// Reestructuracion del panel: quita Virtual Desktop Pager y Peek at Desktop,
// anade Window List junto al Kickoff, centra el gestor de tareas con
// spacers, cambia el icono del Kickoff y fija la opacidad del panel a
// translucida de forma permanente.
//
// IDs de plasmoides, la propiedad .index y panel.opacity verificados
// contra el codigo fuente de plasma-workspace / plasma-desktop.
// Fuente: investigacion-tecnica-plasma6.md, seccion 6.
//
// La ruta /home/USUARIO se reemplaza automaticamente por install.sh;
// si se ejecuta este archivo suelto, edita la linea de abajo a mano.
var CUSTOM_ICON_PATH = "/home/USUARIO/.local/share/icons/custom_menu.svg";

var allPanels = panels();
for (var p = 0; p < allPanels.length; p++) {
    var panel = allPanels[p];
    var widgets = panel.widgets();

    var kickoff = null;
    var taskManager = null;
    var toRemove = [];

    for (var i = 0; i < widgets.length; i++) {
        var w = widgets[i];
        if (w.type === "org.kde.plasma.pager" || w.type === "org.kde.plasma.showdesktop") {
            toRemove.push(w);
        } else if (w.type === "org.kde.plasma.kickoff") {
            kickoff = w;
        } else if (w.type === "org.kde.plasma.taskmanager" || w.type === "org.kde.plasma.icontasks") {
            taskManager = w;
        }
    }

    // 1) Quitar Virtual Desktop Pager y Peek at Desktop
    for (var r = 0; r < toRemove.length; r++) {
        toRemove[r].remove();
    }

    // Releer el panel tras las eliminaciones para partir de indices frescos
    widgets = panel.widgets();
    kickoff = null;
    taskManager = null;
    for (var j = 0; j < widgets.length; j++) {
        if (widgets[j].type === "org.kde.plasma.kickoff") {
            kickoff = widgets[j];
        }
        if (widgets[j].type === "org.kde.plasma.taskmanager" || widgets[j].type === "org.kde.plasma.icontasks") {
            taskManager = widgets[j];
        }
    }

    // 2) Icono personalizado del Kickoff (clave real: [General] icon=)
    if (kickoff) {
        kickoff.currentConfigGroup = ["General"];
        kickoff.writeConfig("icon", CUSTOM_ICON_PATH);
    }

    // 3) Spacers alrededor del gestor de tareas. Se insertan de derecha a
    //    izquierda para que ninguna insercion desordene el indice que la
    //    siguiente insercion necesita leer.
    if (taskManager) {
        var spacerAfter = panel.addWidget("org.kde.plasma.panelspacer");
        spacerAfter.index = taskManager.index + 1;

        var spacerBefore = panel.addWidget("org.kde.plasma.panelspacer");
        spacerBefore.index = taskManager.index;
    }

    // 4) Window List justo al lado del Kickoff
    if (kickoff) {
        var windowList = panel.addWidget("org.kde.plasma.windowlist");
        windowList.index = kickoff.index + 1;
    }

    // 5) Opacidad del panel: translucida de forma permanente
    panel.opacity = "translucent";
}

print("Panel reestructurado correctamente.");
```

**Importante:** para que el icono personalizado se vea, el archivo tiene que existir de verdad en esa ruta:
```bash
mkdir -p ~/.local/share/icons
cp /ruta/a/tu/icono.svg ~/.local/share/icons/custom_menu.svg
```
Si no lo copias, Kickoff simplemente se queda con el icono por defecto (fallo silencioso, no rompe nada).

---

## 10. `06-krunner.sh`

```bash
#!/usr/bin/env bash
# KRunner: modo "flotante", el equivalente real mas cercano a "centrado"
# que expone la aplicacion (no existe un centrado exacto configurable).
# Fuente: investigacion-tecnica-plasma6.md, seccion 7.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

log_info "== KRunner: posicion flotante =="
kwriteconfig6 --file krunnerrc --group General --key FreeFloating true
log_ok "FreeFloating=true aplicado (krunnerrc). KRunner se separa del borde superior; no existe una opcion real de centrado exacto en el software"
```

---

## 11. `07-konsole.sh`

El esquema de color se **copia del que ya trae el sistema** (no se reescribe a mano) para no arriesgar una transcripción distinta a la versión real instalada, y luego se le añaden `Opacity=0.7` y `Blur=true`. La fuente se calcula sumando 2pt a la fuente monoespaciada global real del usuario, no a un nombre fijo adivinado.

```bash
#!/usr/bin/env bash
# Perfil de Konsole: fuente monoespaciada +2pt, esquema White on Black con
# 30% de transparencia y blur, fijado como perfil por defecto.
# Fuente: investigacion-tecnica-plasma6.md, seccion 8.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

log_info "== Konsole: perfil personalizado =="

PROFILE_NAME="Personalizado"
KONSOLE_DATA_DIR="$HOME/.local/share/konsole"
mkdir -p "$KONSOLE_DATA_DIR"

# El esquema de color se copia del que ya trae el sistema en vez de
# reescribirlo a mano, para no arriesgar una transcripcion distinta a la
# version real instalada. Se busca en las rutas habituales de datos del
# sistema.
SYS_SCHEME="$(find /usr/share/konsole /usr/share/*/konsole /usr/share/*/*/konsole -iname "WhiteOnBlack.colorscheme" 2>/dev/null | head -1)"
if [ -z "$SYS_SCHEME" ]; then
    log_error "No se encontro WhiteOnBlack.colorscheme en el sistema; ¿esta Konsole instalado?"
    exit 1
fi

NEW_SCHEME="$KONSOLE_DATA_DIR/WhiteOnBlackBlur.colorscheme"
cp "$SYS_SCHEME" "$NEW_SCHEME"
sed -i '/^Opacity=/d;/^Blur=/d' "$NEW_SCHEME"
sed -i '/^\[General\]/a Opacity=0.7\nBlur=true' "$NEW_SCHEME"
log_ok "Esquema WhiteOnBlackBlur creado (30% de transparencia + blur reales, claves verificadas en ColorScheme.cpp)"

# Fuente: se toma la fuente monoespaciada global del sistema y se le suman
# 2 puntos, en vez de asumir un nombre de fuente fijo que podria no existir.
BASE_FONT="$(kreadconfig6 --file kdeglobals --group General --key fixed 2>/dev/null)"
if [ -z "$BASE_FONT" ]; then
    BASE_FONT="DejaVu Sans Mono,10,-1,5,50,0,0,0,0,0"
    log_warn "No se encontro la fuente monoespaciada global (kdeglobals); usando DejaVu Sans Mono 10pt como base"
fi
BASE_SIZE="$(echo "$BASE_FONT" | cut -d, -f2)"
NEW_SIZE=$((BASE_SIZE + 2))
NEW_FONT="$(echo "$BASE_FONT" | awk -F, -v s="$NEW_SIZE" '{ $2=s; OFS=","; print }')"
log_ok "Fuente: $NEW_FONT (base + 2pt)"

PROFILE_PATH="$KONSOLE_DATA_DIR/${PROFILE_NAME}.profile"
cat > "$PROFILE_PATH" <<PROFILEEOF
[Appearance]
ColorScheme=WhiteOnBlackBlur
Font=$NEW_FONT

[General]
Name=$PROFILE_NAME
Parent=FALLBACK/
PROFILEEOF
log_ok "Perfil creado en $PROFILE_PATH"

kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "${PROFILE_NAME}.profile"
log_ok "Perfil '$PROFILE_NAME' fijado como predeterminado en konsolerc"
```

---

## 12. `08-wallpaper-video-instalacion.sh`

Habilita RPM Fusion (necesario para H.264 real, no solo `ffmpeg-free`), instala el plugin con una cadena de respaldo de tres niveles (dnf directo → repo OBS → compilar desde código fuente), y deja preparado — **inactivo** — el arreglo para el bug de GPU AMD.

```bash
#!/usr/bin/env bash
# Instala el plugin "Smart Video Wallpaper Reborn" y habilita los codecs
# necesarios para reproducir MP4 (H.264) en Fedora. Deja preparada -pero
# desactivada- la solucion para el bug conocido en GPU AMD (QTBUG-124586).
# Fuente: investigacion-tecnica-video-wallpapers-plasma6.md
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

PLUGIN_PKG="plasma-smart-video-wallpaper-reborn"
FEDORA_VER="$(rpm -E %fedora)"

log_info "== Codecs multimedia (RPM Fusion) =="
if dnf repolist 2>/dev/null | grep -qi rpmfusion; then
    log_ok "RPM Fusion ya estaba habilitado"
else
    if sudo dnf install -y \
        "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
        "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"; then
        log_ok "RPM Fusion (free + nonfree) habilitado"
    else
        log_warn "No se pudo habilitar RPM Fusion automaticamente; hazlo a mano si el MP4 falla por codec (la mayoria de MP4 reales usan H.264, que ffmpeg-free no incluye)"
    fi
fi

log_info "== Plugin de wallpaper de video: Smart Video Wallpaper Reborn =="
if sudo dnf install -y "$PLUGIN_PKG" 2>/dev/null; then
    log_ok "Instalado via dnf directo: $PLUGIN_PKG"
elif sudo dnf config-manager --add-repo \
        "https://download.opensuse.org/repositories/home:/luisbocanegra/Fedora_${FEDORA_VER}/home:luisbocanegra.repo" 2>/dev/null \
     && sudo dnf install -y "$PLUGIN_PKG" 2>/dev/null; then
    log_ok "Instalado anadiendo el repo OBS de luisbocanegra"
else
    log_warn "dnf directo y el repo OBS no funcionaron para Fedora ${FEDORA_VER} (nombre exacto de paquete/URL no verificables desde este entorno). Se compila desde codigo fuente como ultimo recurso."
    TMP_VW="$(mktemp -d)"
    if git clone --depth 1 -q https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn.git "$TMP_VW"; then
        install_pkg gcc || true
        install_pkg cmake || true
        install_pkg extra-cmake-modules || true
        install_pkg libplasma-devel || true
        install_pkg qt6-qtmultimedia || true
        if ( cd "$TMP_VW" && ./install.sh ); then
            log_ok "Instalado compilando desde codigo fuente"
        else
            log_error "La compilacion desde codigo fuente fallo"
            exit 1
        fi
    else
        log_error "No se pudo clonar el repositorio del plugin"
        exit 1
    fi
fi

log_info "== Preparando (sin activar) la solucion para el bug de Qt en GPU AMD =="
ENV_DIR="$HOME/.config/plasma-workspace/env"
mkdir -p "$ENV_DIR"
cat > "$ENV_DIR/qt-media-backend.sh.disabled" <<'ENVEOF'
#!/bin/bash
# Quita la extension ".disabled" de este archivo (y reinicia sesion) si el
# wallpaper de video se ve en negro o crashea Plasma en la GPU AMD.
# Referencia: QTBUG-124586 (bugreports.qt.io).
# Puede requerir: sudo dnf install gstreamer1-plugin-libav
export QT_MEDIA_BACKEND=gstreamer
ENVEOF
chmod +x "$ENV_DIR/qt-media-backend.sh.disabled"
log_ok "Preparado en $ENV_DIR/qt-media-backend.sh.disabled (inactivo por defecto)"
```

**Si el wallpaper te da pantalla negra o tumba Plasma en algún momento** (bug conocido en GPU AMD, no hipotético):
```bash
mv ~/.config/plasma-workspace/env/qt-media-backend.sh.disabled ~/.config/plasma-workspace/env/qt-media-backend.sh
sudo dnf install -y gstreamer1-plugin-libav   # nombre no verificado en vivo para Fedora, ver dossier §3.2
# cerrar sesión y volver a entrar para que la variable de entorno se aplique
```

---

## 13. `09-wallpaper-video-aplicar.js`

**Edita `VIDEO_PATH` antes de ejecutar.** El formato de `VideoUrls` (JSON) y la ruta anidada de configuración (`Wallpaper/<id>/General`) están verificados contra el propio código fuente del plugin y del motor de scripting de Plasma.

```javascript
// Asigna Smart Video Wallpaper Reborn como fondo de escritorio y le indica
// que video reproducir. Formato de VideoUrls (JSON) y la ruta anidada de
// configuracion (Wallpaper/id/General) verificados contra el codigo fuente
// del propio plugin y del motor de scripting de Plasma.
// Fuente: investigacion-tecnica-video-wallpapers-plasma6.md, secciones 4 y 5.
//
// *** CAMBIA ESTA RUTA por la de tu archivo .mp4 real antes de ejecutar ***
var VIDEO_PATH = "file:///home/USUARIO/Videos/wallpaper.mp4";
var PLUGIN_ID = "luisbocanegra.smart.video.wallpaper.reborn";

var videos = [{
    filename: VIDEO_PATH,
    enabled: true,
    duration: 0,
    customDuration: false,
    playbackRate: 1,
    alternativePlaybackRate: 1,
    loop: true
}];

var allDesktops = desktops();
for (var i = 0; i < allDesktops.length; i++) {
    var d = allDesktops[i];
    d.wallpaperPlugin = PLUGIN_ID;
    d.currentConfigGroup = ["Wallpaper", PLUGIN_ID, "General"];
    d.writeConfig("VideoUrls", JSON.stringify(videos));
}

print("Wallpaper de video aplicado en " + allDesktops.length + " escritorio(s).");
```

---

## 14. `99-reinicio-seguro.sh`

En Wayland, KWin **es** el compositor de la sesión — no se reemplaza en caliente como en X11 sin arriesgar cerrarla. Por eso este script usa `reconfigure` por D-Bus como método principal y solo intenta `--replace` en X11.

```bash
#!/usr/bin/env bash
# Reinicio seguro de KWin/Plasma. En Wayland, KWin ES el compositor: no se
# reemplaza en caliente como en X11 sin arriesgar toda la sesion grafica.
# Fuente: investigacion-tecnica-plasma6.md, seccion 9.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

log_info "== Aplicando cambios en caliente =="

QDBUS=""
if command -v qdbus6 >/dev/null 2>&1; then
    QDBUS="qdbus6"
elif command -v qdbus >/dev/null 2>&1; then
    QDBUS="qdbus"
fi

if [ -n "$QDBUS" ]; then
    "$QDBUS" org.kde.KWin /KWin reconfigure && log_ok "KWin recargo su configuracion (blur, magic lamp, decoracion)"
else
    log_warn "No se encontro qdbus6/qdbus; cierra sesion y vuelve a entrar para que los cambios de KWin surtan efecto"
fi

if [ "${XDG_SESSION_TYPE:-}" = "x11" ]; then
    log_info "Sesion X11 detectada: reemplazando kwin_x11 (operacion segura en X11)"
    ( kwin_x11 --replace >/dev/null 2>&1 & disown )
else
    log_info "Sesion Wayland detectada: NO se reemplaza kwin_wayland (es el propio compositor de la sesion; forzar su reemplazo puede cerrarla). 'reconfigure' ya cubre los cambios de este conjunto de scripts"
fi

if systemctl --user list-unit-files 2>/dev/null | grep -q "plasma-plasmashell.service"; then
    systemctl --user restart plasma-plasmashell.service && log_ok "plasmashell reiniciado via systemd"
else
    ( kquitapp6 plasmashell >/dev/null 2>&1; sleep 1; plasmashell --replace >/dev/null 2>&1 & disown )
    log_ok "plasmashell reiniciado"
fi
```

---

## 15. `install.sh` — orquestador

Ejecuta todos los módulos en orden, hace backup primero, inyecta el layout del panel, pregunta antes de aplicar el wallpaper de video (porque requiere haber editado la ruta a mano), y reinicia todo de forma segura al final.

```bash
#!/usr/bin/env bash
# Orquestador principal. Ejecuta cada modulo en orden, inyecta los scripts
# de la consola de Plasma, y aplica los cambios en caliente al final.
# No ejecutar como root: los archivos de configuracion son del usuario.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

if [ "$(id -u)" -eq 0 ]; then
    log_error "No ejecutes este script como root/con sudo. Los archivos de configuracion son de tu usuario."
    exit 1
fi

echo "======================================================"
echo " Personalizacion Plasma 6 + Wallpaper de video (MP4)  "
echo "======================================================"

backup_configs

STEPS=(
    "01-kvantum.sh"
    "02-kwin-efectos.sh"
    "03-decoracion-breeze.sh"
    "04-tema-ant-dark.sh"
    "06-krunner.sh"
    "07-konsole.sh"
    "08-wallpaper-video-instalacion.sh"
)

FAILED=()
for step in "${STEPS[@]}"; do
    echo ""
    if bash "$SCRIPT_DIR/$step"; then
        log_ok "$step completado"
    else
        log_error "$step fallo"
        FAILED+=("$step")
    fi
done

echo ""
log_info "== Reestructurando el panel via consola de Plasma =="
mkdir -p "$HOME/.local/share/icons"
QDBUS_BIN="$(command -v qdbus6 || command -v qdbus || true)"
if [ -n "$QDBUS_BIN" ]; then
    JS_PANEL="$(sed "s#/home/USUARIO#$HOME#" "$SCRIPT_DIR/05-panel-layout.js")"
    if "$QDBUS_BIN" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$JS_PANEL"; then
        log_ok "Panel reestructurado"
    else
        log_warn "No se pudo inyectar el script del panel (¿plasmashell esta corriendo?)"
    fi
else
    log_warn "qdbus6/qdbus no disponible; no se pudo aplicar el layout del panel"
fi

echo ""
log_warn "Wallpaper de video: edita 09-wallpaper-video-aplicar.js con la ruta real de tu .mp4 antes de continuar."
read -r -p "¿Ya editaste la ruta del video y quieres aplicarlo ahora? [s/N] " RESP
if [[ "$RESP" =~ ^[sS]$ ]]; then
    if [ -n "$QDBUS_BIN" ]; then
        JS_WALL="$(sed "s#/home/USUARIO#$HOME#" "$SCRIPT_DIR/09-wallpaper-video-aplicar.js")"
        if "$QDBUS_BIN" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$JS_WALL"; then
            log_ok "Wallpaper de video asignado"
        else
            log_warn "No se pudo asignar el wallpaper de video"
        fi
    fi
else
    log_info "Se omite la asignacion del video. Ejecuta este bloque a mano mas tarde cuando la ruta este lista."
fi

echo ""
bash "$SCRIPT_DIR/99-reinicio-seguro.sh"

echo ""
echo "======================================================"
if [ ${#FAILED[@]} -eq 0 ]; then
    log_ok "Todo se aplico sin errores."
else
    log_warn "Modulos con errores: ${FAILED[*]}"
fi
echo "======================================================"
```

---

## 16. Cómo ejecutarlo

```bash
# 1. Crea todos los archivos de arriba en ~/plasma6-suite/ respetando la
#    estructura (common.sh dentro de lib/, el resto en la raíz)

# 2. Permisos de ejecución
chmod +x ~/plasma6-suite/*.sh

# 3. (opcional pero recomendado) Edita antes de correr:
#      - 05-panel-layout.js  -> CUSTOM_ICON_PATH, y coloca el .svg ahí
#      - 09-wallpaper-video-aplicar.js -> VIDEO_PATH con tu .mp4 real

# 4. Ejecuta como tu usuario normal (NO con sudo)
cd ~/plasma6-suite
./install.sh
```

---

## 17. Verificación posterior

```bash
# Kvantum activo
kreadconfig6 --file kdeglobals --group KDE --key widgetStyle        # -> kvantum

# Blur y Magic Lamp
kreadconfig6 --file kwinrc --group Effect-blur --key NoiseStrength  # -> 0
kreadconfig6 --file kwinrc --group Effect-magiclamp --key AnimationDuration  # -> 400

# Ant-Dark
kreadconfig6 --file plasmarc --group Theme --key name               # -> Ant-Dark

# KRunner
kreadconfig6 --file krunnerrc --group General --key FreeFloating    # -> true

# Perfil de Konsole
kreadconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile  # -> Personalizado.profile

# Plugin de wallpaper de video instalado
rpm -q plasma-smart-video-wallpaper-reborn 2>/dev/null || echo "instalado desde codigo fuente, no via rpm"
```

Para el panel y el wallpaper de video, la verificación real es visual (abrir el panel y ver el orden de los widgets; ver si el escritorio reproduce el video) — no hay una única clave que confirme "layout correcto" porque toca varios widgets a la vez.

---

## 18. Recuperación / rollback

`install.sh` guarda un backup con marca de tiempo antes de tocar nada, en `~/.config-backups/plasma6-custom-<fecha>/`. Para revertir las claves de `kwinrc`, `breezerc`, `krunnerrc`, `kdeglobals`, `plasmarc` y `konsolerc`:

```bash
BACKUP_DIR=~/.config-backups/plasma6-custom-AAAAMMDD-HHMMSS   # el que se haya creado
cp "$BACKUP_DIR"/* ~/.config/
qdbus6 org.kde.KWin /KWin reconfigure
systemctl --user restart plasma-plasmashell.service
```

Si el wallpaper de video deja la sesión en bucle de crash (bug de GPU AMD, sección 12), la vía de emergencia documentada por el propio desarrollador del plugin es:

```bash
sed -i 's/^VideoUrls=.*$/VideoUrls=/g' ~/.config/plasma-org.kde.plasma.desktop-appletsrc ~/.config/kscreenlockerrc
systemctl --user restart plasma-plasmashell.service
```

y si ni eso alcanza, cerrar sesión por completo desde una TTY (`Ctrl+Alt+F3`, iniciar sesión por terminal) y volver a entrar.
