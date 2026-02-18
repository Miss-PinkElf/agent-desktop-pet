#!/usr/bin/env python3
import os
import re
import shutil
import subprocess
import sys


def read_text(path):
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as handle:
            return handle.read()
    except OSError:
        return ""


def run(cmd, timeout=6):
    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=timeout,
            check=False,
        )
        return result.returncode, result.stdout.strip()
    except Exception as exc:
        return 1, f"{type(exc).__name__}: {exc}"


def section(title):
    print(f"\n== {title} ==")


def main():
    print("WSL GPU/WebGL diagnostics")

    section("Environment")
    osrelease = read_text("/proc/sys/kernel/osrelease")
    is_wsl = "microsoft" in osrelease.lower()
    print(f"WSL detected: {is_wsl}")
    print(f"/dev/dxg exists: {os.path.exists('/dev/dxg')}")
    print(f"/mnt/wslg exists: {os.path.exists('/mnt/wslg')}")
    print(f"WAYLAND_DISPLAY: {os.environ.get('WAYLAND_DISPLAY', '')}")
    print(f"DISPLAY: {os.environ.get('DISPLAY', '')}")
    print(f"XDG_SESSION_TYPE: {os.environ.get('XDG_SESSION_TYPE', '')}")
    print(f"LIBGL_ALWAYS_SOFTWARE: {os.environ.get('LIBGL_ALWAYS_SOFTWARE', '')}")

    section("GPU tools")
    for tool in ["nvidia-smi", "glxinfo", "vulkaninfo", "lspci"]:
        print(f"{tool}: {shutil.which(tool) or 'not found'}")

    if shutil.which("nvidia-smi"):
        code, out = run(["nvidia-smi", "-L"], timeout=8)
        print("nvidia-smi -L:")
        print(out if out else f"(exit {code})")

    if shutil.which("glxinfo"):
        code, out = run(["glxinfo", "-B"], timeout=8)
        print("glxinfo -B:")
        print(out if out else f"(exit {code})")
        renderer = ""
        version = ""
        for line in out.splitlines():
            if "OpenGL renderer string" in line:
                renderer = line.split(":", 1)[-1].strip()
            if "OpenGL version string" in line:
                version = line.split(":", 1)[-1].strip()
        if renderer:
            print(f"Renderer: {renderer}")
        if version:
            print(f"Version: {version}")

    if shutil.which("vulkaninfo"):
        code, out = run(["vulkaninfo"], timeout=8)
        print("vulkaninfo (first 30 lines):")
        lines = out.splitlines()
        print("\n".join(lines[:30]) if lines else f"(exit {code})")

    if shutil.which("lspci"):
        code, out = run(["lspci"], timeout=8)
        print("lspci (GPU lines):")
        gpu_lines = [line for line in out.splitlines() if re.search(r"vga|3d|display", line, re.I)]
        print("\n".join(gpu_lines) if gpu_lines else "(no GPU lines)")

    section("Notes")
    print("- If /dev/dxg exists but WebGL is still unsupported, WSLg GPU may not be fully enabled.")
    print("- Ensure Windows has the official WSL-compatible GPU driver installed.")
    print("- Run 'wsl --update' on Windows, then restart WSL.")
    print("- If glxinfo shows 'llvmpipe' or 'swiftshader', you are on software rendering.")
    print("- If you set LIBGL_ALWAYS_SOFTWARE=1, unset it to allow GPU.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
