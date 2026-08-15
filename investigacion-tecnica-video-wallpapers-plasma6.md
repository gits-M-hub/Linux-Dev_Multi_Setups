# Dossier técnico — Investigación: Wallpapers de video (MP4) en Fedora 44 / KDE Plasma 6

## Propósito de este documento

Mismo enfoque que el dossier anterior (`investigacion-tecnica-plasma6.md`): antes de escribir un solo script, se investigó **contra fuentes verificables** — el código fuente real del propio plugin candidato, su README/CHANGELOG, y el motor de scripting de Plasma ya auditado en la sesión anterior — en vez de responder de memoria. Esto tampoco son los scripts finales; es el registro de qué se investigó, qué se confirmó, y qué queda por decidir antes de escribirlos.

Mismo sistema de confianza:
- 🟢 **Verificado esta sesión** contra código/documentación real, con archivo y cita exacta.
- 🟡 **Conocimiento previo de alta confianza**, no verificable en vivo desde este sandbox (sigue siendo un contenedor Ubuntu sin Fedora ni sesión gráfica, y sin acceso a los dominios de Fedora/RPM Fusion/openSUSE Build Service).
- 🔴 **Sin resolver / requiere decisión.**

---

## Metodología

El estado del sandbox de la sesión anterior **persistió** (mismo contenedor), así que los repos ya clonados (`kwin`, `plasma-workspace`, `plasma-desktop`, `breeze`, `konsole`, `krunner`, `kvantum-src`) seguían disponibles y se reutilizaron donde aplicaba — en particular, el motor de scripting de Plasma (`plasma-workspace/shell/scripting/`) auditado en la sesión anterior resultó directamente relevante otra vez.

Búsqueda adicional: GitHub (API REST) por plugins de wallpaper de video reales para Plasma, filtrando por estrellas, descripción explícita de compatibilidad con Plasma 6, y fecha del último commit (para descartar proyectos abandonados). El candidato ganador se clonó completo y se auditó: `metadata.json`, esquema de configuración (`config/main.xml`), QML de configuración y reproducción, `install.sh`, `README.md` y `CHANGELOG.md`.

---

## 1. El plugin recomendado: Smart Video Wallpaper Reborn

### 1.1 Por qué este y no otro

Búsqueda en GitHub (`plasma video wallpaper`, ordenado por estrellas):

| Repo | ⭐ | Última actividad | Veredicto |
|---|---|---|---|
| **`luisbocanegra/plasma-smart-video-wallpaper-reborn`** | **556** | **2026-08-13 (ayer)** | ✅ **Elegido** — Plasma 6 explícito, mantenimiento activo diario, paquete Fedora propio |
| `WuSiYu/PlasmaVideoWallpaper` | 119 | 2021-08-08 | ❌ Descartado — "Plasma 5" en el propio nombre del proyecto, sin actividad desde 2021 |
| `DibbayajyotiRoy/Fresco` | 27 | 2026-08-07 | Alternativa de arquitectura distinta, ver sección 7 — no es la recomendación principal para Fedora |
| `antony-jr/VideoWall` | 5 | 2024-05-05 | Descartado — baja adopción y sin actividad reciente |
| `kaloca/plasma-dynamic-video-wallpaper` | 1 | 2026-05-05 | Nicho (rotación por hora del día); no evaluado a fondo, mencionado por completitud |

La diferencia de tracción y de fecha de actividad entre el primero y el resto es lo bastante grande como para no necesitar más comparación — sobre todo tras confirmar que trae paquete propio para Fedora (ver 1.3), algo que ninguno de los otros ofrece.

### 1.2 Identidad del plugin

`package/metadata.json`:
```json
{
    "KPackageStructure": "Plasma/Wallpaper",
    "KPlugin": {
        "Id": "luisbocanegra.smart.video.wallpaper.reborn",
        "Name": "Smart Video Wallpaper Reborn",
        "Version": "2.13.0",
        "License": "GPLv2+"
    },
    "X-KDE-ParentApp": "org.kde.plasmashell",
    "X-Plasma-API-Minimum-Version": "6.0"
}
```
- ID real del plugin: **`luisbocanegra.smart.video.wallpaper.reborn`** 🟢
- Declara explícitamente `X-Plasma-API-Minimum-Version: 6.0` — compatibilidad con Plasma 6 confirmada por el propio autor, no inferida. 🟢
- `KPackageStructure: Plasma/Wallpaper` confirma que se instala/gestiona igual que cualquier paquete de wallpaper de Plasma (mismo mecanismo de `kpackagetool6` que cualquier otro KPackage). 🟢

### 1.3 Instalación en Fedora — confirmado directamente por el proyecto

Del propio `README.md`:

> ### Fedora
> Use dnf to install plasma-smart-video-wallpaper-reborn: `sudo dnf in plasma-smart-video-wallpaper-reborn`. The package will, by default, install ffmpeg-free if it isn't installed which should work for most videos. In case of issues, follow the instructions to install additional codecs from RPMfusion.

- Nombre real del paquete: **`plasma-smart-video-wallpaper-reborn`** 🟢
- El proyecto mantiene build específico para Fedora vía openSUSE Build Service (OBS), con insignias que muestran build activo para **Fedora 43** y **Fedora Rawhide** en el propio README. **No hay una insignia específica para Fedora 44** en lo que se pudo ver — dado que sí cubren la estable anterior (43) y la de desarrollo (Rawhide), es razonable esperar que 44 también esté cubierta, pero no es algo confirmado literalmente. 🟡
- **Ambigüedad honesta:** el texto no dice explícitamente si `dnf install` funciona con los repositorios de Fedora tal cual vienen de fábrica, o si primero hay que añadir el repo del proyecto en OBS (la sección inmediatamente anterior del README, "openSUSE Build Service packages (Fedora, openSUSE)", sugiere que sí podría requerir añadir ese repo primero). El script final tendrá que manejar ambos casos: intentar `dnf install` directo, y si el paquete no se encuentra, añadir el repo de OBS documentado (`home:luisbocanegra`) antes de reintentar. 🔴 → a resolver con lógica defensiva en el script, no asumiendo un único camino.

### 1.4 Instalación manual desde código fuente (alternativa 100% CLI, sin depender de dnf/OBS)

`install.sh` del propio repo (íntegro):
```sh
#!/bin/sh
set -e
if [ "$(whoami)" = root ]; then
    echo "Please do not run this script as root or using sudo"
    exit 1
fi
if [ -d "build" ]; then rm -rf build; fi
cmake -B build -S .
cmake --build build
sudo cmake --install build
sudo chmod 755 "/usr/share/plasma/wallpapers/luisbocanegra.smart.video.wallpaper.reborn/contents/ui/tools/gdbus_get_signal.sh"
rm -r "$HOME/.local/share/plasma/wallpapers/luisbocanegra.smart.video.wallpaper.reborn/" 2>/dev/null || true
```

Puntos a tener en cuenta:
- El propio script **rechaza ejecutarse como root/sudo** directamente (usa `sudo` internamente solo para el paso de instalación). 🟢
- Instala en `/usr/share/plasma/wallpapers/luisbocanegra.smart.video.wallpaper.reborn/` (todo el sistema), y **elimina explícitamente** cualquier instalación previa en `~/.local/share/plasma/wallpapers/...` para que no haya conflicto entre una versión de usuario y una de sistema (Plasma prioriza `~/.local/share/` sobre `/usr/share/` si ambas existen). 🟢 — importante: si el script final usa este método, no debe mezclarlo con una instalación por `dnf` a la vez.
- El propio README lista las dependencias reales para compilar: `git gcc cmake extra-cmake-modules libplasma qt6-multimedia qt6-multimedia-ffmpeg`. 🟢

### 1.5 Nota: instalación por KDE Store (mencionada pero descartada como método a scriptear)

El README también documenta instalarlo desde **Obtener nuevos complementos** (GUI, KNS). Se descarta como método a automatizar por ser una vía gráfica, no de terminal — coherente con el mismo criterio aplicado en el dossier anterior.

---

## 2. Codecs multimedia en Fedora — el obstáculo real

Esta es, con diferencia, la parte más específica de Fedora de todo el tema, y viene confirmada por el propio proyecto, no solo por conocimiento general:

> "The package will, by default, install **ffmpeg-free** if it isn't installed which should work for most videos. In case of issues, follow the instructions to install additional codecs from **RPMfusion**."

- **`ffmpeg-free`**: la build de FFmpeg que Fedora puede distribuir en sus repos oficiales porque excluye codecs con patentes (H.264/AAC entre otros). Suficiente para *algunos* MP4, no para todos. 🟢 (confirmado por el propio proyecto)
- **RPM Fusion** (repos `free` + `nonfree`): de ahí sale el `ffmpeg` completo con soporte H.264/AAC — el codec de vídeo más común en archivos `.mp4` reales. Dado que la inmensa mayoría de archivos MP4 "normales" (exportados de móviles, editores de video, YouTube, etc.) usan H.264, **es muy probable que el usuario necesite RPM Fusion tarde o temprano**, no como un caso límite. 🟡 (mecanismo bien establecido, no verificable en vivo desde este sandbox — sin acceso a los dominios de RPM Fusion).
- Comando estándar y estable para habilitar RPM Fusion (usa `rpm -E %fedora` para detectar la versión automáticamente, por eso no depende de que sea la 44 exacta):
  ```sh
  sudo dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
  ```
  🟡 — no se pudo verificar que la URL siga activa desde este sandbox (dominio no permitido), pero es un patrón extremadamente estable usado así desde hace muchísimas versiones de Fedora.

---

## 3. ⚠️ Advertencia específica para este hardware: bug conocido en GPU AMD

Esto apareció directamente en el README del proyecto, sin haberlo buscado a propósito, y es relevante porque el equipo del usuario usa gráficos **AMD Radeon 680M** integrados:

> "There may be some issues with Qt Causing crashes on AMD GPUs, this is currently being investigated in [QTBUG-124586 - QML video media player segmentation fault on AMD GPU with FFMPEG]"

### 3.1 El bug

- Referencia real: **QTBUG-124586**, ticket abierto en el rastreador oficial de bugs de Qt — "QML video media player segmentation fault on AMD GPU with FFMPEG". 🟢 (citado tal cual en el README del proyecto)
- Backend por defecto de Qt6 Multimedia: **FFmpeg**. Es justo ese backend el que tiene el problema documentado en GPU AMD.

### 3.2 La solución documentada por el propio proyecto: cambiar a GStreamer

Paquetes adicionales (Fedora, por analogía con lo que el README describe para Arch/openSUSE — no hay una lista específica de paquetes Fedora en el README, marcado como hueco abierto en la sección 9): `qt6-multimedia` + backend GStreamer + `gstreamer1-plugin-libav` (equivalente Fedora del `gst-libav`/`gstreamer-plugins-libav` que sí se documenta para Arch/openSUSE). 🟡

Mecanismo real para forzar el backend, confirmado en el README (`~/.config/plasma-workspace/env/` es un directorio real que Plasma lee al iniciar sesión para cargar variables de entorno):

```sh
# ~/.config/plasma-workspace/env/qt-media-backend.sh
#!/bin/bash
export QT_MEDIA_BACKEND=gstreamer
```

Requiere **reiniciar sesión** (no basta con recargar Plasma) para que la variable de entorno se aplique — confirmado también en el README. 🟢

### 3.3 Procedimiento de recuperación si ya crasheó / pantalla negra en bucle

Texto literal encontrado tanto en el README como en un tooltip del propio QML de configuración (`config.qml`), es decir, viene del propio desarrollador como vía de emergencia oficial:

```sh
sed -i 's/^VideoUrls=.*$/VideoUrls=/g' $HOME/.config/plasma-org.kde.plasma.desktop-appletsrc $HOME/.config/kscreenlockerrc
```
seguido de reiniciar sesión, o `systemctl --user restart plasma-plasmashell.service`, o `plasmashell --replace` como último recurso. 🟢

Este mismo comando revela, de paso, dos datos que se necesitan para la sección 5: la clave `VideoUrls` vive tanto en `plasma-org.kde.plasma.desktop-appletsrc` (escritorio) como en `kscreenlockerrc` (pantalla de bloqueo).

**Recomendación para el script final:** dado que este bug es una posibilidad real y documentada en el hardware exacto del usuario (no un caso hipotético), el script debería dejar preparado — aunque sea deshabilitado/comentado — el archivo `qt-media-backend.sh` con GStreamer, para que activarlo sea cambiar una línea si aparecen crashes, en vez de tener que investigarlo desde cero en el momento.

---

## 4. Esquema real de configuración del plugin

`package/contents/config/main.xml` (kcfg), grupo único `[General]`. Claves relevantes confirmadas (hay más, de efectos secundarios como blur/batería — se listan solo las centrales para el objetivo pedido):

| Clave | Tipo | Default | Qué hace |
|---|---|---|---|
| `VideoUrls` | String (JSON) | `[]` | Lista de videos — ver formato exacto abajo |
| `FillMode` | Int | `2` | Modo de ajuste del video al monitor (0/1/2/3… — mapeo exacto no confirmado en este repo, ver nota) |
| `Volume` | Double | `1` | Volumen (0–1) |
| `PlaybackRate` | Double | `1` | Velocidad de reproducción |
| `RandomMode` | Bool | `False` | Orden aleatorio si hay varios videos |
| `MuteMode` | Int (enum) | `5` | 0=maximizada/pantalla completa, 1=ventana visible activa, 2=ventana visible, 4=nunca, 5=siempre (silenciado) |
| `PauseMode` | Int (enum) | `0` | Igual patrón de enum que MuteMode, para pausar el video |
| `BackgroundColor` | String | `#000000` | Color de relleno detrás del video si no cubre toda la pantalla |
| `ResumeLastVideo` | Bool | `True` | Retoma el último video al iniciar sesión |
| `CrossfadeEnabled` / `CrossfadeDuration` | Bool / Int | `False` / `1000` | Transición entre videos (beta, según el propio README) |

Nota sobre `FillMode`: en el QML se usa como `fillMode: main.configuration.FillMode` directamente sobre el elemento de video de Qt Quick — el mapeo 0/1/2/3 más probable coincide con el enum estándar de Qt Quick (`Stretch`, `PreserveAspectFit`, `PreserveAspectCrop`, `Tile`…), con lo que `2` por defecto sería "recortar preservando proporción" — pero no se encontró un comentario explícito en este repo que lo confirme al 100%, a diferencia de `MuteMode`/`PauseMode` que sí traen el mapeo comentado en el propio `.kcfg`. 🟡

### 4.1 Formato exacto de `VideoUrls`

Confirmado en `package/contents/ui/config.qml`:
```js
videos.push({
    filename: item.filename,
    enabled: item.enabled,
    duration: item.duration,
    customDuration: item.customDuration,
    playbackRate: item.playbackRate,
    alternativePlaybackRate: item.alternativePlaybackRate,
    loop: item.loop
});
cfg_VideoUrls = JSON.stringify(videos);
```
→ Es un **string JSON** con un array de objetos, uno por video, con esos 7 campos. `filename` es la ruta/URL del archivo (a confirmar en la práctica si espera `file:///ruta/al/video.mp4` o una ruta plana — el propio `sed` de recuperación de emergencia trata la clave completa como una sola línea `VideoUrls=<json plano>`). 🟢

---

## 5. Cómo activar y configurar el wallpaper por script (enlazando con la investigación anterior)

Aquí es donde el trabajo de la sesión anterior sobre el motor de scripting de Plasma (`shell/scripting/`) se vuelve directamente reutilizable.

### 5.1 Asignar el plugin como wallpaper activo

Ya confirmado en el dossier anterior — `Containment` (la clase base de `Panel` y también del escritorio/`desktop`) expone:
```cpp
Q_PROPERTY(QString wallpaperPlugin READ wallpaperPlugin WRITE setWallpaperPlugin)
Q_PROPERTY(QString wallpaperMode READ wallpaperMode WRITE setWallpaperMode)
```
→ Desde la consola de Plasma: `desktop.wallpaperPlugin = "luisbocanegra.smart.video.wallpaper.reborn"` 🟢

### 5.2 Navegar hasta la configuración anidada del plugin — confirmado en el motor mismo

Se revisó `shell/scripting/applet.cpp::setCurrentConfigGroup()`, y contiene esto, que es una confirmación directa y muy concreta:
```cpp
void Applet::setCurrentConfigGroup(const QStringList &groupNames)
{
    d->configGroup = app->config();
    d->configGroupPath = groupNames;
    for (const QString &groupName : groupNames) {
        d->configGroup = KConfigGroup(&d->configGroup, groupName);
    }
    d->inWallpaperConfig = !groupNames.isEmpty() && groupNames.first() == QLatin1String("Wallpaper");
}
```
El motor de scripting **reconoce explícitamente** `"Wallpaper"` como primer elemento del grupo — no es una suposición, es un caso especial contemplado en el propio código. Combinado con la ruta real de la clave vista en la sección 3.3 (`plasma-org.kde.plasma.desktop-appletsrc`), el patrón queda así:

```js
desktop.currentConfigGroup = ["Wallpaper", "luisbocanegra.smart.video.wallpaper.reborn", "General"]
desktop.writeConfig("VideoUrls", JSON.stringify([{
    filename: "file:///home/balam/Videos/wallpaper.mp4",
    enabled: true,
    duration: 0,
    customDuration: false,
    playbackRate: 1,
    alternativePlaybackRate: 1,
    loop: true
}]))
```
🟢 — cadena completa verificada (aunque no ejecutada en vivo, al no haber sesión Plasma real en este sandbox).

### 5.3 Pantalla de bloqueo

El mismo plugin soporta usarse como wallpaper de la pantalla de bloqueo (confirmado en README y en el propio comando de recuperación, que toca `kscreenlockerrc` además de `appletsrc`). La ruta de configuración exacta dentro de `kscreenlockerrc` no se auditó línea por línea esta sesión — queda como algo a verificar si se decide incluir esta parte en el script. 🔴 (parcial: se sabe que existe y en qué archivo vive, no se verificó el grupo anidado exacto).

---

## 6. Aceleración por hardware (descodificación por GPU)

El README recomienda verificar que la descodificación ocurra por GPU y no por CPU, con herramientas reales (no inventadas):
- `nvtop` (también sirve para AMD/Intel pese al nombre)
- `intel_gpu_top` (Intel)
- `nvidia-smi dmon` (Nvidia)
- `amdgpu_top` (AMD — relevante para este equipo)

Y enlaza a la wiki de Fedora sobre aceleración de hardware. No se pudo abrir ese enlace desde este sandbox (dominio no permitido), pero por conocimiento general 🟡: en Fedora, la aceleración VA-API completa para muchos codecs/GPUs (incluyendo buena parte del soporte AMD) también pasa por RPM Fusion (paquete tipo `mesa-va-drivers-freeworld`), por el mismo motivo de patentes que el propio ffmpeg. Es decir, RPM Fusion no es algo que aplique solo a la reproducción del archivo MP4 en sí, sino potencialmente también a que esa reproducción use la GPU en vez de la CPU.

---

## 7. Alternativa de arquitectura distinta: Fresco

Se clonó y revisó `DibbayajyotiRoy/Fresco` para caracterizarlo con precisión en vez de solo nombrarlo:

| | Smart Video Wallpaper Reborn | Fresco |
|---|---|---|
| Arquitectura | Plugin nativo de Plasma (QML, `Plasma/Wallpaper`) | App independiente (Rust + GTK4/libadwaita + libmpv), corre aparte de Plasma |
| Integración | Vía "Tipo de fondo de pantalla" nativo de Plasma | Ventana propia usando layer-shell, por fuera del sistema de wallpaper de Plasma |
| Paquete Fedora | Sí, confirmado (`dnf`, ver sección 1.3) | **No** — su tabla de "Distros" solo lista Ubuntu/Pop!\_OS/Mint/Debian/elementary/Deepin (`.deb`); para Fedora tocaría compilar desde código fuente (Rust/Cargo) |
| Formatos | mp4 (vía Qt Multimedia) | mp4, webm, mkv, avi, mov, GIF, imágenes — más amplio |
| Extras | Pausa/blur condicional, modo batería, multi-monitor, pantalla de bloqueo | Letras sincronizadas, reloj, visualizador de audio superpuestos al fondo |

**Conclusión:** Fresco es un proyecto real y activo (27⭐, actualizado el 2026-08-07), pero al no tener paquete Fedora nativo y requerir compilar un binario Rust desde cero, es una opción de mayor fricción para este caso concreto. Se documenta como alternativa legítima, no como la recomendación principal.

---

## 8. Candidato descartado explícitamente

**`WuSiYu/PlasmaVideoWallpaper`** (119⭐) — se descarta sin más análisis: el propio proyecto se describe como "A KDE Plasma **5** wallpaper plugin", sin actividad desde 2021-08-08. Con casi 5 años sin mantenimiento y dirigido a una API de Plasma distinta a la actual, no es una base segura para Plasma 6 en Fedora 44.

---

## 9. Tabla resumen de comandos y claves

| Acción | Comando/clave | Confianza |
|---|---|---|
| Instalar (Fedora, camino principal) | `sudo dnf install -y plasma-smart-video-wallpaper-reborn` | 🟢 nombre / 🔴 si requiere repo OBS primero |
| Instalar (fuente, camino alterno) | `git clone` + `./install.sh` (repo `luisbocanegra/plasma-smart-video-wallpaper-reborn`) | 🟢 |
| Habilitar RPM Fusion (codecs completos) | `sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm` | 🟡 |
| ID del plugin | `luisbocanegra.smart.video.wallpaper.reborn` | 🟢 |
| Activar como wallpaper (script JS) | `desktop.wallpaperPlugin = "luisbocanegra.smart.video.wallpaper.reborn"` | 🟢 |
| Configurar video (script JS) | `desktop.currentConfigGroup = ["Wallpaper","luisbocanegra.smart.video.wallpaper.reborn","General"]; desktop.writeConfig("VideoUrls", JSON.stringify([...]))` | 🟢 |
| Backend de video por defecto | `QT_MEDIA_BACKEND` (default `ffmpeg`) | 🟢 |
| Cambiar a GStreamer (fix bug AMD) | Crear `~/.config/plasma-workspace/env/qt-media-backend.sh` con `export QT_MEDIA_BACKEND=gstreamer` + reiniciar sesión | 🟢 |
| Recuperación de emergencia (crash loop) | `sed -i 's/^VideoUrls=.*$/VideoUrls=/g' ~/.config/plasma-org.kde.plasma.desktop-appletsrc ~/.config/kscreenlockerrc` | 🟢 |
| Reinicio seguro de plasmashell | `systemctl --user restart plasma-plasmashell.service` (confirma lo ya documentado en el dossier anterior) | 🟢 |

---

## 10. Fuentes consultadas

- `https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn` — plugin recomendado (clonado completo: metadata, config.qml, main.qml, install.sh, README, CHANGELOG)
- `https://github.com/DibbayajyotiRoy/Fresco` — alternativa evaluada (clonado, solo README/estructura)
- `https://github.com/WuSiYu/PlasmaVideoWallpaper` — candidato descartado (solo metadatos vía búsqueda, no clonado)
- `https://github.com/KDE/plasma-workspace` (`shell/scripting/`) — reutilizado de la sesión anterior, para confirmar el mecanismo de `currentConfigGroup`/`writeConfig`/`wallpaperPlugin`
- Referencia citada dentro del propio README del plugin: QTBUG-124586 (bugreports.qt.io) — no visitada directamente, citada tal como aparece en la fuente primaria

---

## 11. Próximos pasos / pendientes antes de escribir el script

1. **Decidir la lógica de instalación en Fedora** (🔴 sección 1.3): intentar `dnf install` directo primero; si el paquete no aparece, documentar y/o automatizar el añadido del repo OBS de `home:luisbocanegra` como respaldo, dejando claro en el script cuál de los dos caminos se usó.
2. **Confirmar paquetes exactos de GStreamer para Fedora** (🟡 sección 3.2) — el README solo da nombres de paquete para Arch/openSUSE, no para Fedora; falta el equivalente exacto (`gstreamer1-plugin-libav` es la suposición razonada, no confirmada).
3. **Decidir si se incluye soporte de pantalla de bloqueo** (🔴 sección 5.3) — el mecanismo existe pero no se auditó su grupo de configuración anidado exacto dentro de `kscreenlockerrc`.
4. Con esto ya resuelto, escribir el script (instalación defensiva + backend GStreamer pre-configurado pero inactivo + inyección del `.js` vía consola de Plasma para asignar el video), validado con `shellcheck` igual que el dossier anterior.
