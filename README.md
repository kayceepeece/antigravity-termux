# Antigravity CLI Universal Termux Installer

A unified, automated installer for running the Antigravity CLI on Android/Termux environments across varying CPU architectures (including older ARMv8.0-A devices lacking Large System Extensions) and memory layouts.

## What It Resolves

This installer addresses three primary barriers to running the standard Linux binary on Termux:
1. **SSL/Linker Out-of-Sync Errors (`SSL_set_quic_tls_transport_params`)**: Solved via a clean system package upgrade.
2. **Virtual Address Space Limit (TCMalloc `MmapAligned` failure)**: Solved by applying a pattern-based memory patch shifting pointers from 48-bit to 39-bit memory maps.
3. **Missing Hardware Atomic Instructions (`sigill-fail-fast`)**: Solved by wrapping execution with QEMU AArch64 emulation (`-cpu max`).

## Prerequisites

> [!WARNING]
> **Do not use the Google Play Store version of Termux.** The Play Store build has been deprecated since 2020. The package manager repositories are broken, and modern binaries will fail to execute due to Android API constraints.
>
> You must install a clean, up-to-date version of Termux from one of these official sources:
> * **[F-Droid](https://f-droid.org/en/packages/com.termux/)**
> * **[GitHub Releases](https://github.com/termux/termux-app/releases)**

## Installation

Run the following command directly in your Termux terminal to install:

```bash
curl -fsSL https://raw.githubusercontent.com/kayceepeece/antigravity-termux/main/install.sh | bash
```

After the installation completes:
1. Reload your shell configuration:
   ```bash
   source ~/.bashrc
   ```
2. Verify the installation:
   ```bash
   agy --version
   ```

## Updating

To quickly update the Antigravity CLI without upgrading all system packages again, you can run the update alias:
```bash
agy-update
```

Alternatively, you can run the update command manually:
```bash
curl -fsSL https://raw.githubusercontent.com/kayceepeece/antigravity-termux/main/install.sh | bash -s -- --update
```

## License

This project is open-source and licensed under the MIT License.
