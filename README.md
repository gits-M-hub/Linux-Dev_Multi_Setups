# Linux Multi-Distro Dev Setup

Entorno de desarrollo reproducible para múltiples distribuciones de Linux.

Enfoque en: Java, Kotlin, Android, Desarrollo Web, Docker, Git, VS Code y Linux.

## Tabla de Contenidos

- [Estructura](#estructura)
- [Documentación](#documentación)
- [Herramientas Instaladas](#herramientas-instaladas)
- [Scripts](#scripts)
- [Licencia](#licencia)
- [Contribuir](#contribuir)

---

## Objetivos

- Documentar un entorno de desarrollo
- Centralizar configuraciones, scripts y documentación
- Versionar cambios importantes
- Automatizar la instalación del entorno

Setup reproducible para reinstalar rápidamente el entorno en múltiples distribuciones de Linux.

## Distribuciones Soportadas

- Debian/Ubuntu: Ubuntu, Pop!_OS, Linux Mint, Debian
- Kali Linux: Kali (con herramientas de hacking opcionales)
- Arch Linux: Arch Linux, Manjaro
- Fedora: Fedora, RHEL, CentOS

El script detecta automáticamente tu distribución y ejecuta la instalación correspondiente.

## Instalación Rápida

Para instalar el entorno completo, ejecuta:

```bash
# Clonar el repositorio
git clone https://github.com/gits-M-hub/Linux_Pop_Os-Dev-Setup.git ~/Projects/linux-dev-setup
cd ~/Projects/linux-dev-setup

# Ejecutar script de instalación
./scripts/install/setup.sh
```

El script instalará automáticamente:

- Herramientas base (Zsh, Oh My Zsh, Starship, LazyGit, Yazi)
- Herramientas de desarrollo (SDKMAN, Java, Kotlin, Docker, VS Code, PostgreSQL, GCC)
- Configuraciones (Zsh, Starship, Git, VS Code)
- Alias de terminal

**Nota para Kali Linux:** En Kali se omiten Java/Kotlin/SDKMAN y PostgreSQL, pero se añaden herramientas de hacking opcionales.

## Estructura

```
linux-dev-setup/
├── configs/           # Archivos de configuración
│   ├── aliases/      # Alias de terminal
│   ├── exports/      # Variables de entorno
│   ├── git/          # Configuración de Git
│   ├── starship/     # Configuración de Starship
│   ├── vscode/       # Configuración de VS Code
│   └── zsh/          # Configuración de Zsh
├── docs/              # Documentación
│   ├── postgresql/   # Guías de PostgreSQL
│   ├── setup/        # Guías de instalación
│   └── terminal/     # Comandos y herramientas
├── scripts/          # Scripts de automatización
│   ├── docker/       # Scripts de Docker
│   └── install/      # Scripts de instalación
│       ├── debian/   # Scripts para Debian/Ubuntu
│       ├── kali/     # Scripts para Kali Linux
│       ├── arch/     # Scripts para Arch Linux
│       └── fedora/   # Scripts para Fedora
├── .gitignore        # Archivos ignorados por Git
├── LICENSE           # Licencia del proyecto
└── README.md         # Este archivo
```

---

## Documentación

Toda la documentación se encuentra en la carpeta [`docs/`](docs/).

Comienza por [`docs/index.md`](/docs/index.md) - Índice principal de la documentación.

Documentación disponible:

- [`docs/linux-survival-guide.md`](/docs/linux-survival-guide.md) - Guía de supervivencia en Linux
- [`docs/setup/installed-tools.md`](/docs/setup/installed-tools.md) - Herramientas instaladas
- [`docs/terminal/navigation.md`](/docs/terminal/navigation.md) - Navegación en terminal
- [`docs/terminal/tools.md`](/docs/terminal/tools.md) - Herramientas de terminal
- [`docs/terminal/aliases.md`](/docs/terminal/aliases.md) - Alias configurados

---

## Documentación del Proyecto

Documentación para contribuidores y usuarios del proyecto:

- [`CONTRIBUTING.md`](CONTRIBUTING.md) - Guía para contribuir al proyecto
- [`CHANGELOG.md`](CHANGELOG.md) - Historial de cambios por versión
- [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) - Código de conducta de la comunidad

---

## Herramientas Instaladas

### Desarrollo

- Git
- GitHub SSH
- Docker
- Java (SDKMAN!)
- Kotlin
- Gradle
- VS Code
- GCC

### Terminal

- Zsh
- Oh My Zsh
- Starship
- LazyGit
- Yazi
- Tree
- Bat
- Btop

Para más detalles, consulta [`docs/setup/installed-tools.md`](/docs/setup/installed-tools.md).

---

## Scripts

Los scripts del proyecto se encuentran en [`scripts/`](/scripts/).

### Instalación

- [`scripts/install/setup.sh`](scripts/install/setup.sh) - Script principal de instalación completa
- [`scripts/install/install-base-tools.sh`](scripts/install/install-base-tools.sh) - Instalación de herramientas base (Zsh, Oh My Zsh, Starship, LazyGit, Yazi)
- [`scripts/install/install-dev-tools.sh`](scripts/install/install-dev-tools.sh) - Instalación de herramientas de desarrollo (SDKMAN, Java, Kotlin, Docker, VS Code, PostgreSQL)
- [`scripts/install/install-aliases.sh`](scripts/install/install-aliases.sh) - Instalación de alias en ~/.zshrc

### Docker

- `scripts/docker/docker-doctor.sh` - Verificación de instalación de Docker
- `scripts/docker/docker-clean.sh` - Limpieza de recursos de Docker
- `scripts/docker/docker-reset.sh` - Reset completo de Docker
- `scripts/docker/docker-backup-volumes.sh` - Backup de volúmenes Docker

### Sistema

- `scripts/doctor.sh` - Script de verificación del sistema
- `scripts/update-system.sh` - Actualización del sistema

## Filosofía

- Configuración reproducible
- Documentación clara
- Automatización antes que repetición
- Uso de herramientas oficiales
- Entender el porqué

---

## Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](/LICENSE) para más detalles.

---

## Contribuir

Las contribuciones son bienvenidas:

1. Lee la [guía para contribuidores](CONTRIBUTING.md)
2. Revisa el [código de conducta](CODE_OF_CONDUCT.md)
3. Abre un issue para discutir cambios grandes
4. Haz fork del repositorio y crea una rama para tu feature
5. Envía un pull request con descripción clara

---
