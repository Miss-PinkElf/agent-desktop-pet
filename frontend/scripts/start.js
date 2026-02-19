#!/usr/bin/env node
const { spawn } = require('node:child_process');
const fs = require('node:fs');

const isWsl = () => {
  if (process.platform !== 'linux') return false;
  if (process.env.WSL_DISTRO_NAME || process.env.WSL_INTEROP) return true;
  try {
    const osrelease = fs.readFileSync('/proc/sys/kernel/osrelease', 'utf8');
    return osrelease.toLowerCase().includes('microsoft');
  } catch {
    return false;
  }
};

const env = { ...process.env };
if (isWsl()) {
  env.MESA_LOADER_DRIVER_OVERRIDE = 'd3d12';
  env.GALLIUM_DRIVER = 'd3d12';
  env.LIBGL_ALWAYS_SOFTWARE = '0';
}

const child = spawn('electron-forge', ['start'], {
  stdio: 'inherit',
  shell: true,
  env,
});

child.on('exit', (code) => {
  process.exit(code ?? 0);
});
