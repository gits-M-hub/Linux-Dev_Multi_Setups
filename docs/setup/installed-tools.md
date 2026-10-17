# Herramientas Instaladas

Lista completa de herramientas instaladas en el entorno de desarrollo.

## Tabla de Contenidos

- [Terminal](#terminal)
- [Desarrollo](#desarrollo)
- [Kali Linux - Herramientas de Hacking](#kali-linux---herramientas-de-hacking)
- [Gestores](#gestores)
- [Scripts propios](#scripts-propios)

---

## Terminal

| Herramienta | Estado | Descripción                                 |
| ----------- | ------ | ------------------------------------------- |
| Zsh         | OK     | Shell principal del sistema                 |
| Oh My Zsh   | OK     | Framework para configuración de Zsh         |
| Starship    | OK     | Prompt moderno y configurable               |
| Tree        | OK     | Visualización de estructuras de directorios |
| Bat         | OK     | Reemplazo moderno de `cat` con resaltado    |
| Btop        | OK     | Monitor interactivo del sistema             |
| LazyGit     | OK     | Interfaz de Git para terminal               |
| Yazi        | OK     | Administrador de archivos moderno           |

Para más detalles, consulta [`../terminal/tools.md`](../terminal/tools.md).

---

## Desarrollo

| Herramienta | Estado | Descripción                     |
| ----------- | ------ | ------------------------------- |
| Git         | OK     | Sistema de control de versiones |
| GitHub SSH  | OK     | Autenticación SSH con GitHub    |
| Docker      | OK     | Contenedores y virtualización   |
| Java        | OK     | Lenguaje Java (via SDKMAN!)     |
| Kotlin      | OK     | Lenguaje Kotlin (via SDKMAN!)   |
| Gradle      | OK     | Sistema de build automatizado   |
| VS Code     | OK     | Editor de código                |
| GCC         | OK     | Compilador C/C++                |

**Nota para Kali Linux:** Java/Kotlin/SDKMAN y PostgreSQL NO se instalan en Kali (innecesarios para hacking).

---

## Kali Linux - Herramientas de Hacking

### Pentesting

| Herramienta | Estado | Descripción |
| ----------- | ------ | ----------- |
| Nmap | OK | Escáner de red |
| Metasploit | OK | Framework de pentesting |
| Nikto | OK | Escáner de vulnerabilidades web |
| OWASP ZAP | OK | Proxy de seguridad web |

### Análisis de Red

| Herramienta | Estado | Descripción |
| ----------- | ------ | ----------- |
| Wireshark | OK | Analizador de protocolos de red |
| tcpdump | OK | Captura de paquetes |
| netcat | OK | Utilidad de red |
| mitmproxy | OK | Proxy HTTP/HTTPS |

### Web Hacking

| Herramienta | Estado | Descripción |
| ----------- | ------ | ----------- |
| sqlmap | OK | Inyección SQL automática |
| dirb | OK | Escáner de directorios web |
| gobuster | OK | Enumeración de directorios |
| ffuf | OK | Fuzzing web |
| wpscan | OK | Escáner de seguridad WordPress |

---

## Gestores

| Herramienta | Estado | Descripción                            |
| ----------- | ------ | -------------------------------------- |
| SDKMAN!     | OK     | Gestor de SDKs para Java/Kotlin/Groovy |

---

## Scripts propios

- [`doctor.sh`](../../scripts/doctor.sh) - Script de verificación del sistema

---

**Volver al [Índice](../index.md)**
