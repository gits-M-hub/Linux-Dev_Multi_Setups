# Dossier técnico — Investigación previa a los scripts de personalización de Plasma 6

## Propósito de este documento

Antes de escribir una sola línea de bash, se hizo un trabajo de **verificación contra el código fuente real de KDE** (KWin, Breeze, KRunner, Konsole, plasma-workspace, plasma-desktop, Kvantum), en lugar de confiar en memoria/entrenamiento que podría estar desactualizada o ser directamente incorrecta para Plasma 6. Este documento es el registro completo de esa investigación: qué se buscó, qué se encontró, qué hipótesis iniciales resultaron **incorrectas y fueron corregidas**, y qué quedó **sin resolver**.

**Esto NO son los scripts finales.** Es el dossier de evidencia que va a servir de fuente de verdad para escribirlos a continuación. Cada clave de configuración que aparece aquí está etiquetada con un nivel de confianza:

- 🟢 **Verificado esta sesión** contra el código fuente real (archivo y ruta exactos citados).
- 🟡 **Conocimiento previo de alta confianza**, no re-verificado esta sesión (no hay forma de probarlo en un Fedora/Plasma real dentro de este sandbox, que corre Ubuntu sin entorno gráfico).
- 🔴 **Sin resolver / pendiente.**

---

## Metodología

El entorno de ejecución (sandbox) es un contenedor Ubuntu sin Fedora ni sesión gráfica, con acceso de red restringido a una lista blanca de dominios (`github.com`, `api.github.com`, `raw.githubusercontent.com`, `codeload.github.com`, repos de pip/npm/cargo, espejos de Ubuntu). **No incluye los repositorios de paquetes de Fedora**, así que los nombres exactos de paquetes `dnf` para Fedora 44 no se pudieron verificar en vivo.

Lo que sí se pudo hacer:

1. Confirmar que KDE mantiene **espejos públicos en GitHub** de sus repositorios oficiales (`github.com/KDE/*`), de solo lectura pero con el código fuente real.
2. Clonar (`git clone --depth 1`) los repos relevantes: `kwin`, `breeze`, `krunner`, `plasma-workspace`, `plasma-desktop`, `konsole`, y el repo upstream de `tsujan/Kvantum`.
3. Buscar directamente los archivos `.kcfg` (esquemas de configuración de KDE — la fuente de verdad para saber qué claves existen, en qué grupo, y con qué valor por defecto), los `metadata.json`/`metadata.desktop` (para IDs de plugins/plasmoides), y el código C++ donde no había `.kcfg` (como KRunner o el motor de scripting de Plasma).
4. Instalar `shellcheck` (vía `apt`, dominios de Ubuntu permitidos) para validar sintácticamente los scripts bash una vez escritos.
5. Buscar en GitHub (API REST, con rate-limit no autenticado) los temas visuales pedidos por nombre ("Ant Dark") en vez de asumir una URL.

La API REST de GitHub sin autenticar devolvió `403` (rate limit) en el primer intento; se resolvió usando el protocolo `git` directamente (`git ls-remote` / `git clone`), que no tiene ese límite, y reintentando la API más tarde para las búsquedas semánticas puntuales que sí la necesitaban.

---

## Limitaciones generales que aplican a todo lo demás

- **Corte de conocimiento fiable: fines de enero de 2026.** Hoy es 14 de agosto de 2026. "Fedora 44" puede ser ya la versión real y actual, pero cae fuera de mi ventana de conocimiento verificado, y no hay acceso de red a los espejos de paquetes de Fedora desde este sandbox para confirmarlo en vivo.
- Los repos clonados son el **HEAD de desarrollo actual** de cada proyecto (rama por defecto), que puede estar *por delante* de lo que realmente está empaquetado y estable en Fedora 44. Esto importa especialmente en la decoración de ventanas (ver sección 3.2).
- Ningún comando `kwriteconfig6`, `qdbus6`, `dnf` o `kvantummanager` se pudo **ejecutar de verdad** contra una sesión Plasma real — este sandbox no tiene entorno gráfico ni Fedora. Toda la verificación es a nivel de código fuente, no de ejecución en vivo.

---

## 1. Kvantum — motor de temas y transparencia

### 1.1 Paquete y soporte Qt6

En `CMakeLists.txt` del repo oficial (`tsujan/Kvantum`):

```
option(ENABLE_QT4 "Building Qt4 plugin." OFF)
option(ENABLE_QT5 "Building Qt5 plugin." OFF)
```

Con ambas apagadas por defecto, la build por defecto de Kvantum **es Qt6**. Esto reduce bastante el riesgo de que el paquete `kvantum` de Fedora sea una build vieja incompatible con Plasma 6. 🟢 (confirmado en el CMakeLists real) — pero el nombre exacto del paquete RPM en Fedora 44 sigue siendo 🟡 (no verificable desde este sandbox).

### 1.2 Ubicaciones reales de los temas (corrección de una duda interna)

Durante la investigación dudé si los temas de usuario van en `~/.local/share/Kvantum/` o en `~/.config/Kvantum/`. El código fuente (`kvantummanager/KvantumManager.cpp`, `KvCommand.cpp`) lo zanja:

```cpp
themeDir = QString("%1/.themes/%2/Kvantum").arg(homeDir).arg(themeName);
themeDir = QString("%1/.local/share/themes/%2/Kvantum").arg(homeDir).arg(themeName);
// y en KvCommand.cpp:
QDir kv = QDir(QString("%1/Kvantum").arg(xdg_config_home));
```

- Temas de usuario (los que vamos a instalar): **`~/.config/Kvantum/<NombreTema>/`** 🟢
- Temas del sistema (los que trae el paquete `kvantum`): `/usr/share/Kvantum/<NombreTema>/` 🟢
- Config del motor (tema activo): `~/.config/Kvantum/kvantum.kvconfig` 🟢

### 1.3 Herramienta CLI oficial (mejor que editar el kvconfig a mano)

`kvantummanager/main.cpp` expone un modo de línea de comandos documentado en su propio `--help`:

```
Activar un tema:       kvantummanager --set THEME
Asignar tema a apps:   kvantummanager --assign THEME APP1 APP2 ...
```

`KvCommand.cpp::setTheme()` confirma que esto simplemente escribe `theme=<THEME>` en `~/.config/Kvantum/kvantum.kvconfig` (vía `QSettings`, formato nativo = INI, sin grupo explícito = `[General]` implícito) — pero usar el binario oficial es más robusto que tocar el archivo a mano. **Este será el método preferido en el script.** 🟢

### 1.4 Decisión de diseño: qué tema "glass" usar

El propio repo de Kvantum trae temas empaquetados en `themes/kvthemes/`. Se inspeccionaron dos:

**`KvRoughGlass`** (el único oficial con nombre "glass"):
```ini
[%General]
comment=A translucent light Kvantum theme with rough glass windows
composite=true
translucent_windows=true
blurring=true
popup_blurring=true
```
Problema: es un tema **claro** (`window.color=#dcdcdc`, `base.color=#fbfbfb`), no encaja con la estética oscura que se pidió en el resto de la tarea (y con la preferencia estética oscura ya conocida).

**`KvArcDark`** (oscuro, basado en la paleta Arc Dark muy conocida): `window.color=#383c4a`, pero trae la transparencia **apagada** por defecto:
```ini
translucent_windows=false
blurring=false
popup_blurring=false
```

**Decisión tomada:** en vez de usar cualquiera de los dos tal cual, el script va a copiar `KvArcDark` a `~/.config/Kvantum/` con otro nombre y parchear su `[%General]` con las mismas claves de transparencia verificadas en `KvRoughGlass` (`translucent_windows=true`, `blurring=true`, `popup_blurring=true`, `composite=true`). Resultado: oscuro (coincide con la estética pedida) + transparencia real y verificada (no inventada) + construido sobre una base oficial y mantenida del propio proyecto Kvantum, no un tema de terceros de procedencia dudosa — exactamente el tipo de riesgo que causó el incidente con Darkly. 🟢 (claves confirmadas en el código; la combinación es una decisión de diseño, no un hallazgo).

### 1.5 Aplicar Kvantum como estilo de aplicación

No re-verificado esta sesión (no hay forma de probarlo sin una sesión Plasma real), pero es una convención KDE muy estable y de larga data: 🟡

```ini
# kdeglobals
[KDE]
widgetStyle=kvantum
```

### 1.6 Importante: Kvantum NO controla la decoración de ventanas

Kvantum es un motor de **estilo de widgets Qt** (botones, menús, scrollbars), no un plugin de decoración de KWin. La petición original de "establecer Kvantum como estilo de aplicación y decoración de ventanas" mezcla dos subsistemas distintos. La decoración (bordes, título, esquinas redondeadas) se resuelve en la sección 3 con Breeze nativo, tal como se autorizó como alternativa.

---

## 2. Efectos de KWin (Blur y Magic Lamp)

Encontrados directamente en `kwin/src/plugins/blur/blur.kcfg` y `kwin/src/plugins/magiclamp/magiclamp.kcfg` del repo oficial `KDE/kwin`.

### 2.1 Efecto Blur

```xml
<group name="Effect-blur">
    <entry name="BlurStrength" type="Int"><default>15</default></entry>
    <entry name="NoiseStrength" type="Int"><default>5</default></entry>
    <entry name="Saturation" type="Int"><default>150</default></entry>
</group>
```

→ Archivo `kwinrc`, grupo `[Effect-blur]`, claves `BlurStrength`, `NoiseStrength`, `Saturation`. 🟢

`metadata.json` del plugin confirma `"EnabledByDefault": true` — Blur ya viene activado en Plasma por defecto, así que forzar `[Plugins] blurEnabled=true` es solo una confirmación explícita, no algo crítico. 🟢

### 2.2 Corrección de una hipótesis inicial: "Saturation" NO es un efecto aparte

Antes de mirar el código fuente, la hipótesis de trabajo era que "Noise" pertenecía al efecto Blur pero "Saturation" pertenecía a un efecto distinto ("Background Contrast", usado por Latte Dock y similares para el look "vibrancy"). **El `.kcfg` real demuestra que esa hipótesis era incorrecta**: `Saturation` vive dentro del propio grupo `[Effect-blur]`, junto a `NoiseStrength`. No hace falta tocar ningún efecto adicional — la petición del usuario ("Blur con Noise en 0 y Saturation aumentada") se resuelve con un único grupo de configuración. Se documenta este giro porque es exactamente el tipo de detalle que un tutorial no verificado suele dar por hecho mal.

### 2.3 Efecto Magic Lamp

```xml
<group name="Effect-magiclamp">
    <entry name="AnimationDuration" type="Int"><default>0</default></entry>
</group>
```

→ Archivo `kwinrc`, grupo `[Effect-magiclamp]`, clave `AnimationDuration` (el `0` por defecto es un valor centinela que significa "usar la duración por defecto del sistema"; para forzar 400 ms hay que escribir `400` explícitamente). 🟢

`metadata.json` del plugin aporta dos datos clave:
- `"EnabledByDefault": false` → hay que activarlo explícitamente (`magiclampEnabled=true` en `[Plugins]`).
- `"exclusiveGroup": "minimize"` → KWin gestiona automáticamente la exclusión mutua entre efectos de minimizado. **No hace falta desactivar a mano la animación de minimizado clásica** ("squash"); al activar Magic Lamp, KWin la desplaza solo. 🟢

### 2.4 Clave `[Plugins]` para activar/desactivar efectos

El patrón `<idDelPlugin>Enabled=true/false` en el grupo `[Plugins]` de `kwinrc` es la convención estándar de KWin. Los IDs (`blur`, `magiclamp`) se infieren del nombre del directorio/target de compilación de cada plugin, consistente con años de scripts y dotfiles de la comunidad KDE. 🟡 (patrón, no una clave literal encontrada en un `.kcfg`).

---

## 3. Decoración de ventanas (Breeze nativo)

Investigado en `breeze/kdecoration/` del repo oficial `KDE/breeze`.

### 3.1 ID real de la librería de decoración

```
# breeze/kdecoration/CMakeLists.txt
add_library(breezedecoration MODULE ...)
set_target_properties(breezedecoration PROPERTIES OUTPUT_NAME org.kde.breeze)
```

→ El valor correcto para `library=` es **`org.kde.breeze`**. 🟢

### 3.2 Ambigüedad detectada: KDecoration2 vs KDecoration3

El `metadata.json` de la decoración Breeze en el HEAD actual del repo referencia `"org.kde.kdecoration3"`, no `"org.kde.kdecoration2"` (que fue el estándar durante toda la vida de Plasma 6 hasta donde llega mi conocimiento verificado). Como el clon es la rama de desarrollo actual, es posible que esto sea un cambio muy reciente que **todavía no esté** en la versión estable que trae Fedora 44, o que sí lo esté. No hay forma de confirmarlo desde este sandbox.

**Mitigación adoptada:** el script va a escribir `library=org.kde.breeze` en **ambos** grupos posibles de `kwinrc` (`[org.kde.kdecoration2]` y `[org.kde.kdecoration3]`). Escribir un grupo INI que KWin no lee no causa ningún error — simplemente queda inerte — así que esta redundancia es una cobertura barata frente a la incertidumbre de versión, no un intento de adivinar. 🟡

### 3.3 Opciones reales y configurables (`breezesettingsdata.kcfg`)

```xml
<group name="Common">
    <entry name="ShadowStrength" type="Int"><default>255</default><min>25</min><max>255</max></entry>
    <entry name="ShadowSize" type="Enum">
        <choices><choice name="ShadowNone"/><choice name="ShadowSmall"/><choice name="ShadowMedium"/>
                 <choice name="ShadowLarge"/><choice name="ShadowVeryLarge"/></choices>
        <default>ShadowLarge</default>
    </entry>
    <entry name="OutlineEnabled" type="Bool"><default>true</default></entry>
    <entry name="RoundedCorners" type="Bool"><default>true</default></entry>
</group>
```

→ Archivo `breezerc`, grupo `[Common]`. `RoundedCorners` es la clave real para esquinas redondeadas nativas. 🟢

### 3.4 Limitación honesta: el radio de esquina NO es ajustable

```cpp
// breeze/kdecoration/breeze.h
static constexpr qreal Frame_FrameRadius = 2.5;
```

Es una constante fija en tiempo de compilación, no una entrada de `.kcfg`. Con Breeze nativo se puede **activar/desactivar** el redondeo (`RoundedCorners`), pero **no** controlar cuánto radio tiene — viene fijo. Si en algún momento se quisiera un radio más pronunciado y ajustable, la alternativa real sería un decorador de terceros (p. ej. Klassy), pero eso está fuera del alcance porque el usuario pidió explícitamente ceñirse a Breeze nativo o Kvantum. Se documenta para que quede claro que no es una omisión sino un límite real del software. 🟢

---

## 4. Tema Plasma "Ant Dark"

### 4.1 Búsqueda

Los intentos directos de adivinar la URL (`EliverLara/Ant-Dark`, `PlasmaDesign/ant-dark`, `vinceliuice/Ant-Dark`, `psifidotos/ant-dark`, `tsmnc02/ant-dark`) fallaron — ninguno existe. La búsqueda por scraping de la página HTML de GitHub tampoco dio resultados aprovechables (la página de resultados se renderiza con JS). La búsqueda que sí funcionó fue vía API REST de GitHub con términos más amplios (`ant dark plasma desktoptheme`), que encontró:

**`EliverLara/Ant`** — "A flat and light theme with a modern look", del mismo autor del tema Nordic (ampliamente conocido y mantenido en el ecosistema de temas Linux).

### 4.2 Estructura confirmada dentro del repo

```
kde/Dark/plasma/desktoptheme/Ant-Dark/metadata.desktop
kde/Dark/plasma/look-and-feel/Ant-Dark/   (paquete completo, look-and-feel — fuera de alcance)
```

`metadata.desktop` del desktoptheme:
```ini
[Desktop Entry]
Name=Ant-Dark
Comment=A dark and modern theme for plasma.
Comment[es]=Un tema oscuro y moderno para plasma.
X-KDE-PluginInfo-Name=Ant-Dark
X-KDE-PluginInfo-Version=1.0.0
X-Plasma-API=5.0

[AdaptiveTransparency]
enabled=true
```

- El ID real a usar es **`Ant-Dark`** (con guion, mayúsculas tal cual). 🟢
- Trae `[AdaptiveTransparency] enabled=true` de fábrica — encaja bien con el objetivo de translucidez del resto de la tarea. 🟢

### 4.3 Advertencia honesta: metadata para API de Plasma 5

`X-Plasma-API=5.0` indica que este tema fue escrito para la API de Plasma 5. Un *desktoptheme* es sobre todo un paquete de assets SVG (fondos de panel, widgets, diálogos), así que normalmente sigue funcionando razonablemente en Plasma 6 — cuando falta un elemento SVG específico de Plasma 6, el sistema hace *fallback* al tema Breeze por defecto para esa pieza en concreto, en vez de romperse. Pero **no hay garantía de una integración 100% nativa y pixel-perfect** en Plasma 6. Se prefiere avisar de esto ahora a que el usuario lo descubra como una sorpresa visual. 🟢 (el hecho está confirmado en el metadata; la consecuencia práctica es una inferencia razonable, no una prueba).

### 4.4 Alcance deliberadamente limitado

El repo también ofrece un paquete `look-and-feel/Ant-Dark` completo (con dependencias KNS a wallpaper, tema SDDM, cursores, etc. vía `store.kde.org`). **Se descarta a propósito** — la tarea pidió solo el tema del panel/entorno, y KNS implica llamadas a un servicio externo que no es fiable de scriptear de forma desatendida. Solo se usará la carpeta `desktoptheme/Ant-Dark/`, copiada a `~/.local/share/plasma/desktoptheme/Ant-Dark/`.

Aplicación: `plasma-apply-desktoptheme Ant-Dark` (herramienta CLI oficial de Plasma) como método principal, con `kwriteconfig6 --file plasmarc --group Theme --key name Ant-Dark` + recarga como respaldo. 🟡 (la existencia y comportamiento de `plasma-apply-desktoptheme` es conocimiento previo, no re-verificado en código esta sesión).

---

## 5. Set de iconos ("Breeze Modificado") — 🔴 PENDIENTE

Estado real al momento de escribir este documento: **sin resolver**. Se intentaron dos búsquedas en la API de GitHub (`breeze icon fork dark`, `"breeze" icon theme in:name`) y solo devolvieron proyectos irrelevantes de bajo perfil (`fleger/calibre-breeze-icon-theme`, `burlog/grub2-theme-breeze-icon`). Ningún resultado es un fork de iconos Breeze real, mantenido y con volumen de uso significativo. Este punto quedó abierto cuando se interrumpió la investigación para redactar este documento.

**Antes de escribir esa parte del script hace falta, en este orden de preferencia:**
1. Otra ronda de búsqueda con términos distintos (p. ej. temas conocidos y bien mantenidos que son variantes/derivados de Breeze en espíritu, aunque no literalmente un "fork" — evaluar candidatos concretos antes de asumir ninguno).
2. Si no aparece nada satisfactorio, documentar explícitamente en el script que "Breeze Modificado" se sustituyó por una alternativa concreta y nombrarla con claridad, en vez de dejarlo ambiguo — tal como pidió el usuario con el "o similar".

---

## 6. Scripting del panel (consola JS de Plasma)

Investigado en `plasma-workspace/shell/scripting/` (motor real que ejecuta lo que se manda vía `evaluateScript` por D-Bus) y en los `CMakeLists.txt`/`metadata.json` de los applets en `plasma-desktop/applets/` y `plasma-workspace/applets/`.

### 6.1 IDs reales de los plasmoides (confirmados por `plasma_add_applet(...)` en CMake o `Id` explícito en metadata.json)

| Widget | ID interno | Repo | Fuente de la confirmación |
|---|---|---|---|
| Application Launcher (Kickoff) | `org.kde.plasma.kickoff` | plasma-desktop/applets/kickoff | `plasma_add_applet(org.kde.plasma.kickoff` |
| Pager (indicador de escritorios virtuales) | `org.kde.plasma.pager` | plasma-desktop/applets/pager | ídem |
| Peek at Desktop | `org.kde.plasma.showdesktop` | plasma-desktop/applets/showdesktop | ídem |
| Icons-and-Text Task Manager | `org.kde.plasma.taskmanager` | plasma-desktop/applets/taskmanager | ídem |
| Icons-Only Task Manager | `org.kde.plasma.icontasks` | plasma-desktop/applets/icontasks | `"Id": "org.kde.plasma.icontasks"` explícito en metadata.json |
| Window List | `org.kde.plasma.windowlist` | plasma-desktop/applets/window-list | `plasma_add_applet(org.kde.plasma.windowlist` |
| Panel Spacer (el flexible, el correcto) | `org.kde.plasma.panelspacer` | plasma-workspace/applets/panelspacer | metadata.json → `"Name": "Panel Spacer"` |
| *(descartado)* Margins Separator — parecido pero NO es el spacer pedido | — | plasma-workspace/applets/margins-separator | metadata.json → `"Name": "Margins Separator"` (separador de márgenes fijo, no expansible) |

Todo 🟢. Nota de diseño: como no se puede saber de antemano si el panel real del usuario usa `taskmanager` o `icontasks` como gestor de tareas por defecto, el script tiene que **detectar cuál está presente en vivo** en vez de asumir uno de los dos.

### 6.2 API de scripting verificada (`shell/scripting/containment.h`, `panel.h`, `widget.h`)

```cpp
// Containment (clase base de Panel)
Q_INVOKABLE QJSValue addWidget(const QJSValue &v, qreal x=-1, qreal y=-1, qreal w=-1, qreal h=-1, const QVariantList &args);
Q_INVOKABLE QJSValue widgets(const QString &widgetType = QString()) const;
Q_INVOKABLE QJSValue widgetById(const QJSValue &paramId) const;

// Panel : Containment — propiedades propias
Q_PROPERTY(QString opacity READ opacity WRITE setOpacity)   // ← relevante para "opacidad translúcida permanente"
Q_PROPERTY(QString alignment READ alignment WRITE setAlignment)
Q_PROPERTY(int length READ length WRITE setLength)
```

`panel.opacity` es una propiedad de cadena de escritura directa — es el mecanismo real para fijar la opacidad del panel a translúcido vía script, sin tocar archivos de configuración a mano. 🟢

### 6.3 Hallazgo clave: la propiedad `index` de `Widget` (resuelve el posicionamiento exacto)

```cpp
// shell/scripting/widget.h
Q_PROPERTY(int index WRITE setIndex READ index)
```

```cpp
// shell/scripting/widget.cpp — setIndex() real
KConfigGroup cg = c->config();
cg = KConfigGroup(&cg, "General");
const QString orderString = cg.readEntry("AppletOrder", QString());
// ...quita el applet de donde esté, lo reinserta en la posición pedida...
QMetaObject::invokeMethod(containmentItem, "reorderApplets", Q_ARG(QVariant, QVariant::fromValue(order)));
```

Esto es el hallazgo más valioso de toda la sesión para la sección 4 de la tarea original: existe una propiedad **legible y escribible** que reordena widgets en el panel de forma fiable, leyendo/escribiendo directamente la clave `AppletOrder` del contenedor y aplicando el cambio en caliente. Con esto, "poner Window List justo al lado de Kickoff" o "insertar un spacer antes y después del task manager" deja de ser una aproximación y pasa a ser una operación determinista:

```js
var kickoffIdx = kickoffWidget.index;
var wl = panel.addWidget("org.kde.plasma.windowlist");
wl.index = kickoffIdx + 1;
```

🟢 — es, con diferencia, el descubrimiento con más impacto práctico de todo el dossier.

---

## 7. KRunner — posicionamiento en pantalla

### 7.1 Dónde vive realmente KRunner

El repo `github.com/KDE/krunner` es solo el **framework** (la librería de plugins "runner"), no la aplicación con interfaz que aparece en pantalla. Esa aplicación vive dentro de `plasma-workspace/krunner/` (`main.cpp`, `view.cpp`, `view.h`). No tiene archivo `.kcfg` propio — su configuración se lee de forma imperativa con `KConfigGroup`.

### 7.2 Clave `FreeFloating` confirmada en el código

```cpp
// plasma-workspace/krunner/view.cpp
m_config = KConfigGroup(KSharedConfig::openConfig(), "General");
// ...
setFreeFloating(m_config.readEntry("FreeFloating", false));
```

`KSharedConfig::openConfig()` sin nombre de archivo explícito abre el `.rc` propio de la aplicación — en este caso, **`krunnerrc`**.

→ Archivo `krunnerrc`, grupo `[General]`, clave **`FreeFloating`** (booleano, por defecto `false`). 🟢

### 7.3 Qué hace realmente `FreeFloating=true` (aviso honesto)

```cpp
QMargins View::margins() {
    if (m_floating) {
        const QRect r = screen()->availableGeometry();
        return QMargins({0, r.height() / 3, 0, 0});   // margen superior = 1/3 de la pantalla
    }
    return {};
}
```

Con `FreeFloating=true`, KRunner se despega del borde superior y "flota" con un margen equivalente a un tercio de la altura de la pantalla — visualmente es la opción "centrada/flotante" que ofrece el propio KRunner, con centrado horizontal. **No existe** en el código una opción de posicionamiento arbitrario o de centrado vertical exacto — esto es lo más cercano a "centro de la pantalla" que el software realmente soporta. Se documenta así para no prometer un centrado píxel-perfecto que no existe. 🟢

---

## 8. Konsole — perfil, fuente, esquema de color y transparencia

Investigado en `konsole/src/profile/Profile.cpp`, `ProfileWriter.cpp`, `colorscheme/ColorScheme.cpp`, `profile/ProfileManager.cpp`.

### 8.1 Formato real de un `.profile`

Tabla de propiedades (`Profile::DefaultProperties`) confirma nombres de grupo literales:
```cpp
static const char GENERAL_GROUP[] = "General";
static const char APPEARANCE_GROUP[] = "Appearance";
// ...
{Font, "Font", APPEARANCE_GROUP, QFont()},
{ColorScheme, "ColorScheme", APPEARANCE_GROUP, QLatin1String("Breeze")},
```

→ `Font` y `ColorScheme` van en el grupo **`[Appearance]`** del `.profile`. El valor por defecto de `ColorScheme` es literalmente `"Breeze"`, lo que confirma que ese es el nombre del esquema incorporado. 🟢

`ProfileWriter::getPath()` confirma la ruta de guardado real:
```cpp
QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/konsole" + "/" + nombre + ".profile"
```
→ **`~/.local/share/konsole/<Nombre>.profile`** 🟢 (coincide exactamente con lo que pidió el usuario).

### 8.2 Corrección de una suposición inicial: la transparencia/blur NO están en el `.profile`

La suposición inicial era que "transparencia con blur al 30%" sería una propiedad del perfil (`.profile`). El código demuestra que es **incorrecto**: viven en el archivo del **esquema de color** (`.colorscheme`), no en el perfil.

`ColorScheme.cpp::read()`:
```cpp
KConfigGroup configGroup = config.group("General");
setOpacity(configGroup.readEntry("Opacity", 1.0));   // 1.0 = opaco. 0.7 = 70% opaco = 30% transparente
_blur = configGroup.readEntry("Blur", false);
```

Y se confirmó inspeccionando el esquema `WhiteOnBlack.colorscheme` real (existe tal cual, sin necesidad de adaptarlo de nombre):
```ini
[General]
Description=White on Black
Opacity=1
```
(sin clave `Blur`, es decir, por defecto está apagado).

→ Para lograr "White on Black + 30% transparencia + blur", hay que **copiar** este esquema a `~/.local/share/konsole/` con otro nombre y añadirle `Opacity=0.7` y `Blur=true` en `[General]` — no modificar el original del sistema (que además suele ser de solo lectura). 🟢

### 8.3 Perfil por defecto

```cpp
// ProfileManager.cpp
KConfigGroup group = m_config->group("Desktop Entry");
QString defaultProfileFileName = group.readEntry("DefaultProfile", "");
```

→ Archivo `konsolerc`, grupo `[Desktop Entry]`, clave `DefaultProfile` = nombre del archivo `.profile` (p. ej. `MiPerfil.profile`). 🟢

---

## 9. Reinicio seguro de KWin y Plasma

Esto no se verificó contra código esta sesión (no aplica — es una cuestión de arquitectura de sesión, no de una clave de config), pero es importante dejarlo documentado porque afecta directamente a un requisito explícito del usuario y tiene relación directa con el tipo de incidente que ya sufrió con Darkly:

- **X11:** `kwin_x11` es un cliente más de un X server separado. Reemplazarlo en caliente (`kwin_x11 --replace &`) es una operación segura y de uso común desde hace años.
- **Wayland:** `kwin_wayland` **es** el compositor/servidor de pantalla. No existe un "reemplazo en caliente" seguro equivalente al de X11 — forzarlo puede tumbar toda la sesión gráfica en curso. Dado que el usuario tiene una AMD Radeon 680M (con muy buen soporte Wayland) en Fedora KDE, lo más probable es que su sesión sea Wayland por defecto, así que este matiz aplica directamente.
- **Alternativa segura y ampliamente documentada para ambos casos:** `qdbus6 org.kde.KWin /KWin reconfigure` recarga la configuración de KWin (blur, magic lamp, decoración) en caliente sin tocar el proceso del compositor, tanto en X11 como en Wayland.
- **`plasmashell`** no es el compositor en ningún caso (es un cliente normal), así que `kquitapp6 plasmashell` + relanzar es seguro siempre.

🟡 — Estrategia planeada, no una cita textual de código fuente.

---

## 10. Tabla resumen — todas las claves de configuración verificadas

| Archivo | Grupo | Clave | Notas / valor propuesto | Confianza |
|---|---|---|---|---|
| `kwinrc` | `[Effect-blur]` | `NoiseStrength` | `0` | 🟢 |
| `kwinrc` | `[Effect-blur]` | `Saturation` | por encima de 150 (default) | 🟢 |
| `kwinrc` | `[Effect-blur]` | `BlurStrength` | sin tocar (15 default) salvo que se pida | 🟢 |
| `kwinrc` | `[Plugins]` | `blurEnabled` | `true` | 🟡 patrón |
| `kwinrc` | `[Effect-magiclamp]` | `AnimationDuration` | `400` | 🟢 |
| `kwinrc` | `[Plugins]` | `magiclampEnabled` | `true` | 🟡 patrón |
| `kwinrc` | `[org.kde.kdecoration2]` *y* `[org.kde.kdecoration3]` | `library` | `org.kde.breeze` (escribir en ambos) | 🟢 id / 🟡 grupo |
| `breezerc` | `[Common]` | `RoundedCorners` | `true` | 🟢 |
| `breezerc` | `[Common]` | `ShadowSize` | `ShadowVeryLarge` (elección estética) | 🟢 clave real |
| `krunnerrc` | `[General]` | `FreeFloating` | `true` | 🟢 |
| `<Perfil>.profile` | `[Appearance]` | `Font` | fuente monoespaciada del sistema, +2pt | 🟢 |
| `<Perfil>.profile` | `[Appearance]` | `ColorScheme` | nombre del esquema custom (basado en WhiteOnBlack) | 🟢 |
| `<Esquema>.colorscheme` | `[General]` | `Opacity` | `0.7` (30% transparencia) | 🟢 |
| `<Esquema>.colorscheme` | `[General]` | `Blur` | `true` | 🟢 |
| `konsolerc` | `[Desktop Entry]` | `DefaultProfile` | `<Nombre>.profile` | 🟢 |
| `kvantum.kvconfig` | `[General]` (implícito) | `theme` | nombre del tema custom (o usar `kvantummanager --set`) | 🟢 |
| `kdeglobals` | `[KDE]` | `widgetStyle` | `kvantum` | 🟡 |
| `plasmarc` | `[Theme]` | `name` | `Ant-Dark` | 🟡 |

---

## 11. Fuentes consultadas (repos oficiales clonados durante esta sesión)

- `https://github.com/KDE/kwin` — efectos Blur y Magic Lamp
- `https://github.com/KDE/breeze` — decoración de ventanas y estilo Qt
- `https://github.com/KDE/krunner` — framework de runners (no la app)
- `https://github.com/KDE/plasma-workspace` — app real de KRunner, motor de scripting del shell, applets (panelspacer, systemtray, etc.)
- `https://github.com/KDE/plasma-desktop` — applets del panel (kickoff, pager, showdesktop, taskmanager, icontasks, window-list)
- `https://github.com/KDE/konsole` — formato de perfiles y esquemas de color
- `https://github.com/tsujan/Kvantum` — motor Kvantum, temas empaquetados, `kvantummanager`
- `https://github.com/EliverLara/Ant` — tema Plasma "Ant Dark" (carpeta `kde/Dark/plasma/desktoptheme/Ant-Dark/`)

---

## 12. Próximos pasos

1. Cerrar el punto pendiente del set de iconos (sección 5) con otra ronda de búsqueda dirigida, o documentar explícitamente la sustitución elegida.
2. Escribir los scripts modulares (bash + el `.js` para la consola de Plasma) usando **este documento como fuente de verdad** para cada clave, grupo y ruta.
3. Validar sintaxis con `shellcheck` (ya instalado en el sandbox) antes de entregar.
4. Incluir en el propio script las comprobaciones defensivas señaladas como 🟡 (nombre de paquete `dnf`, grupo de decoración kdecoration2/3, `widgetStyle`) en vez de asumirlas ciegamente, dado que no se pudieron verificar en vivo contra Fedora 44 real.
