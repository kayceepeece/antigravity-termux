# Antigravity CLI Universal Termux Installer

A unified, automated installer for running the Antigravity CLI on Android/Termux environments across varying CPU architectures (including older ARMv8.0-A devices lacking Large System Extensions) and memory layouts.

## What It Resolves

This installer addresses three primary barriers to running the standard Linux binary on Termux:
1. **SSL/Linker Out-of-Sync Errors (`SSL_set_quic_tls_transport_params`)**: Solved via a clean system package upgrade.
2. **Virtual Address Space Limit (TCMalloc `MmapAligned` failure)**: Solved by applying a pattern-based memory patch shifting pointers from 48-bit to 39-bit memory maps.
3. **Missing Hardware Atomic Instructions (`sigill-fail-fast`)**: Solved by wrapping execution with QEMU AArch64 emulation (`-cpu max`).

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

## License

This project is open-source and licensed under the MIT License.
