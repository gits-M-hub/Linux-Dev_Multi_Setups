# Soporte Multi-Distribución

Este proyecto soporta múltiples distribuciones de Linux, permitiendo que el entorno de desarrollo sea reproducible en diferentes sistemas.

## Distribuciones Soportadas

### Familia Debian
- Ubuntu (todas las versiones)
- Pop!_OS
- Linux Mint
- Kubuntu
- Xubuntu
- Debian

### Kali Linux
- Kali Linux (con herramientas de hacking opcionales)

### Familia Arch
- Arch Linux
- Manjaro

### Familia Fedora
- Fedora
- RHEL (Red Hat Enterprise Linux)
- CentOS

## Kali Linux - Configuración Especial

Kali Linux tiene una configuración especial optimizada para hacking y pentesting:

### Características Específicas de Kali

**Herramientas de Desarrollo (mantenidas):**
- Zsh, Oh My Zsh, Starship
- LazyGit, Yazi
- Docker
- VS Code
- GCC
- Git

**Herramientas NO instaladas (innecesarias para hacking):**
- Java/Kotlin/SDKMAN
- PostgreSQL

**Herramientas de Hacking (opcionales):**

El script de Kali permite seleccionar entre 4 perfiles:

1. **Todas las herramientas (all):**
   - Pentesting: Nmap, Metasploit, Nikto, OWASP ZAP
   - Análisis de Red: Wireshark, tcpdump, netcat, mitmproxy
   - Web Hacking: sqlmap, dirb, gobuster, ffuf, wpscan

2. **Solo Pentesting (pentesting):**
   - Nmap, Metasploit, Nikto, OWASP ZAP

3. **Solo Análisis de Red (network):**
   - Wireshark, tcpdump, netcat, mitmproxy

4. **Solo Web Hacking (web):**
   - sqlmap, dirb, gobuster, ffuf, wpscan

### Instalación en Kali Linux

```bash
git clone https://github.com/gits-M-hub/Linux_Pop_Os-Dev-Setup.git ~/Projects/linux-dev-setup
cd ~/Projects/linux-dev-setup
./scripts/install/setup.sh
```

El script detectará automáticamente Kali Linux y te pedirá seleccionar el perfil de herramientas de hacking.

### Notas Importantes

- Kali Linux viene con muchas herramientas de hacking preinstaladas
- Este script añade herramientas base de desarrollo y permite instalar herramientas adicionales según el perfil
- Burp Suite Community requiere instalación manual desde el sitio web de PortSwigger
- Para usar Wireshark sin sudo, necesitas cerrar sesión y volver a entrar (se añade al grupo wireshark)
- Todas las herramientas deben usarse de manera ética y responsable

## 🚀 Instalación

El script principal detecta automáticamente tu distribución y ejecuta el script de instalación correspondiente:

```bash
# Clonar el repositorio
git clone https://github.com/gits-M-hub/Linux_Pop_Os-Dev-Setup.git ~/Projects/linux-dev-setup
cd ~/Projects/linux-dev-setup

# Ejecutar instalación (detecta distro automáticamente)
./scripts/install/setup.sh
```

## Estructura de Scripts

```
scripts/install/
├── setup.sh                    # Script principal (detecta distro)
├── debian/                    # Scripts para Debian/Ubuntu/Pop!_OS
│   ├── setup.sh
│   ├── install-base-tools.sh
│   └── install-dev-tools.sh
├── kali/                      # Scripts para Kali Linux
│   ├── setup.sh
│   ├── install-base-tools.sh
│   ├── install-dev-tools.sh
│   └── install-hacking-tools.sh
├── arch/                      # Scripts para Arch Linux/Manjaro
│   ├── setup.sh
│   ├── install-base-tools.sh
│   └── install-dev-tools.sh
└── fedora/                    # Scripts para Fedora/RHEL/CentOS
    ├── setup.sh
    ├── install-base-tools.sh
    └── install-dev-tools.sh
```

## 🔧 Diferencias por Distribución

### Gestores de Paquetes

| Familia | Gestor | Ejemplo |
|---------|--------|---------|
| Debian | apt | `sudo apt install paquete` |
| Kali | apt | `sudo apt install paquete` |
| Arch | pacman | `sudo pacman -S paquete` |
| Fedora | dnf | `sudo dnf install paquete` |

### Herramientas Específicas

**Kali Linux:**
- Usa `apt` como gestor principal (basado en Debian)
- Viene con muchas herramientas de hacking preinstaladas
- NO instala Java/Kotlin/SDKMAN ni PostgreSQL (innecesarios para hacking)
- Mantiene GCC, Docker, VS Code, y herramientas de terminal
- Permite seleccionar perfil de herramientas de hacking (all, pentesting, network, web)
- `bat` → `batcat` (requiere symlink)
- `fd-find` → `fdfind` (requiere symlink)

**Arch Linux:**
- Usa `yay` como AUR helper para paquetes adicionales
- `bat` y `fd` tienen nombres estándar (no batcat/fdfind)
- Docker y VS Code se instalan desde AUR

**Fedora:**
- Usa `dnf` como gestor principal
- `fd-find` requiere symlink a `fd`
- Docker se instala desde repositorio oficial de Fedora
- VS Code se instala desde RPM de Microsoft

**Debian/Ubuntu:**
- Usa `apt` como gestor principal
- `bat` → `batcat` (requiere symlink)
- `fd-find` → `fdfind` (requiere symlink)
- Docker y VS Code se instalan desde repositorios oficiales

## 🎯 Arch Linux vs Pop!_OS

### Arch Linux

**Ventajas:**
- 🎨 **Personalización máxima** - Control total sobre el sistema
- 📦 **Rolling release** - Siempre con las últimas versiones
- 📚 **Arch Wiki** - Mejor documentación de Linux
- 🔧 **AUR (Arch User Repository)** - Acceso a miles de paquetes
- ⚡ **Rendimiento** - Sistema minimalista y rápido
- 🎯 **Perfecto para aprender** - Te obliga a entender Linux

**Desventajas:**
- 📈 Curva de aprendizaje alta
- 🔨 Requiere más mantenimiento manual
- ⚠️ Menos estable (rolling release)

### Pop!_OS

**Ventajas:**
- 🛡️ **Muy estable** - Basado en Ubuntu LTS
- 🎨 **Interfaz moderna** - GNOME con mejoras
- 📚 **Gran comunidad** - Ubuntu detrás
- 🔧 **Fácil de usar** - Ideal para principiantes
- 🏢 Soporte corporativo (System76)

**Desventajas:**
- Menos personalización que Arch
- Paquetes más antiguos (LTS)
- Menos control sobre el sistema

## 🤔 ¿Es Arch Linux Mejor que Pop!_OS?

**Depende de tus objetivos:**

### Elige Arch Linux si:
- ✅ Quieres aprender profundamente Linux
- ✅ Valoras la personalización máxima
- ✅ Prefieres las últimas versiones de software
- ✅ No te importa invertir tiempo en mantenimiento
- ✅ Quieres control total sobre tu sistema

### Elige Pop!_OS si:
- ✅ Prefieres estabilidad sobre todo
- ✅ Quieres un sistema "funciona fuera de la caja"
- ✅ No quieres dedicar tiempo a mantenimiento
- ✅ Eres principiante en Linux
- ✅ Necesitas compatibilidad garantizada

## 📈 Compatibilidad del Proyecto

### Fedora: ✅ 92% Compatible (Edición Especial Mejorada)

El proyecto soporta Fedora con scripts específicos y mejoras avanzadas de estabilidad:

- ✅ Todas las herramientas base (Zsh, Oh My Zsh, Starship, etc.)
- ✅ LazyGit (prioriza repositorios de Fedora, fallback a GitHub)
- ✅ Yazi (prioriza repositorios de Fedora, fallback a cargo)
- ✅ SDKMAN!, Java, Kotlin, Gradle
- ✅ Docker (con verificación de estado y mejor manejo de errores)
- ✅ VS Code (desde RPM de Microsoft)
- ✅ PostgreSQL (con verificación de estado y manejo de errores)
- ✅ Todas las configuraciones

**Mejoras de estabilidad en Fedora (Edición Especial):**
- **Detección de versión:** Verifica versión de Fedora (mínimo 35 soportado)
- **Verificación de dependencias:** Valida e instala dependencias faltantes automáticamente
- **Verificación de salud del sistema:**
  - Espacio en disco (mínimo 10GB recomendado)
  - Memoria RAM (mínimo 4GB recomendado)
  - Conexión a internet
  - Permisos sudo
- **Mecanismo de rollback:** Desinstala paquetes y detiene servicios si falla la instalación
- **Verificación de servicios systemd:** Confirma que Docker y PostgreSQL están corriendo
- **Manejo robusto de errores en descargas:** Verifica archivos descargados antes de instalar
- **Fallback inteligente:** Prioriza repositorios de Fedora antes de usar métodos externos
- **Registro de cambios:** Rastrea paquetes y servicios instalados para rollback

### Diferencias en Arch:

1. **AUR Helper (yay):**
   - El script instala automáticamente `yay` si no está presente
   - `yay` se usa para instalar paquetes desde AUR (LazyGit, Yazi, VS Code)

2. **Nombres de paquetes:**
   - `bat` → `bat` (no batcat)
   - `fd` → `fd` (no fdfind)

3. **Servicios systemd:**
   - Docker y PostgreSQL requieren habilitar servicios con `systemctl`

## 🎈 Recomendación Personal

**Para ti como estudiante:**

Si quieres **personalizar al máximo la terminal** y **aprender profundamente Linux**, **Arch Linux es la mejor opción**.

**Por qué:**
- Te obliga a entender cómo funciona Linux
- Tienes control total sobre cada aspecto del sistema
- La comunidad de Arch es excelente para aprender
- Arch Wiki es la mejor documentación de Linux
- Puedes personalizar todo, especialmente la terminal

**Curva de aprendizaje:**
- Alta al principio (2-3 semanas)
- Luego se vuelve más fácil que otras distros
- Aprendizaje que dura toda la vida

## 📚 Recursos para Arch Linux

- [Arch Wiki](https://wiki.archlinux.org/) - Mejor documentación de Linux
- [Arch Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [AUR (Arch User Repository)](https://aur.archlinux.org/)
- [Arch Forums](https://bbs.archlinux.org/)

## 🔧 Migración a Arch Linux

Si decides migrar a Arch Linux:

1. **Backup de datos:**
   ```bash
   # Backup de configuraciones importantes
   cp -r ~/.config ~/.config-backup
   cp -r ~/.zshrc ~/.zshrc-backup
   ```

2. **Instalación de Arch:**
   - Sigue la [Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
   - O usa una distro basada en Arch más fácil (Manjaro, EndeavourOS)

3. **Ejecutar este proyecto:**
   ```bash
   git clone https://github.com/gits-M-hub/Linux_Pop_Os-Dev-Setup.git ~/Projects/linux-dev-setup
   cd ~/Projects/linux-dev-setup
   ./scripts/install/setup.sh  # Detectará Arch automáticamente
   ```

4. **Restaurar configuraciones:**
   ```bash
   # Restaurar configuraciones si es necesario
   cp -r ~/.config-backup/* ~/.config/
   ```

---

**Volver al [Índice](../index.md)**
