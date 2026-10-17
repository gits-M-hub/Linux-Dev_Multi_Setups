# Kali Linux - Configuración y Herramientas de Hacking

Documentación específica para la configuración de Kali Linux en este proyecto.

## Visión General

Kali Linux tiene una configuración especial optimizada para hacking y pentesting. El script detecta automáticamente Kali y ofrece opciones personalizadas.

## Diferencias con Otras Distribuciones

### Herramientas NO Instaladas

Las siguientes herramientas de desarrollo no se instalan en Kali (innecesarias para hacking):

- Java/Kotlin/SDKMAN
- PostgreSQL

### Herramientas Mantenidas

Herramientas de desarrollo que sí se instalan en Kali:

- Zsh, Oh My Zsh, Starship
- LazyGit, Yazi
- Docker
- VS Code
- GCC
- Git

## Perfiles de Herramientas de Hacking

El script de Kali permite seleccionar entre 4 perfiles de herramientas de hacking:

### 1. Todas las herramientas (all)

Incluye herramientas de todas las categorías:

**Pentesting:**
- Nmap - Escáner de red
- Metasploit - Framework de pentesting
- Nikto - Escáner de vulnerabilidades web
- OWASP ZAP - Proxy de seguridad web

**Análisis de Red:**
- Wireshark - Analizador de protocolos de red
- tcpdump - Captura de paquetes
- netcat - Utilidad de red
- mitmproxy - Proxy HTTP/HTTPS

**Web Hacking:**
- sqlmap - Inyección SQL automática
- dirb - Escáner de directorios web
- gobuster - Enumeración de directorios
- ffuf - Fuzzing web
- wpscan - Escáner de seguridad WordPress

### 2. Solo Pentesting (pentesting)

- Nmap
- Metasploit
- Nikto
- OWASP ZAP

### 3. Solo Análisis de Red (network)

- Wireshark
- tcpdump
- netcat
- mitmproxy

### 4. Solo Web Hacking (web)

- sqlmap
- dirb
- gobuster
- ffuf
- wpscan

## Instalación

```bash
git clone https://github.com/gits-M-hub/Linux_Pop_Os-Dev-Setup.git ~/Projects/linux-dev-setup
cd ~/Projects/linux-dev-setup
./scripts/install/setup.sh
```

El script detectará automáticamente Kali Linux y te pedirá seleccionar el perfil de herramientas de hacking.

## Notas Importantes

### Burp Suite

Burp Suite Community requiere instalación manual desde el sitio web de PortSwigger:

1. Descarga desde: https://portswigger.net/burp/communitydownload
2. Instala el archivo descargado

### Wireshark

Para usar Wireshark sin sudo, necesitas:

1. Cerrar sesión y volver a entrar (se añade al grupo wireshark automáticamente)
2. Verificar que estás en el grupo: `groups`

### Uso Ético

Todas las herramientas de hacking deben usarse de manera ética y responsable:

- Solo para propósitos legítimos
- Siempre obtener autorización antes de realizar pruebas
- Respetar las leyes y regulaciones locales
- Reportar vulnerabilidades de manera responsable

## Scripts Específicos de Kali

El directorio `scripts/install/kali/` contiene:

- `setup.sh` - Script principal (detecta y ejecuta los demás)
- `install-base-tools.sh` - Herramientas base de terminal
- `install-dev-tools.sh` - Herramientas de desarrollo (sin Java/Kotlin/PostgreSQL)
- `install-hacking-tools.sh` - Herramientas de hacking según perfil

## Estructura de Directorios

```
scripts/install/kali/
├── setup.sh                    # Script principal
├── install-base-tools.sh       # Herramientas base
├── install-dev-tools.sh       # Herramientas de desarrollo
└── install-hacking-tools.sh    # Herramientas de hacking
```

---

**Volver al [Índice](../index.md)**
