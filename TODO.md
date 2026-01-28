# Luametry TODO

## Completed
- [x] Binary output to `bin/` (gitignored)
- [x] CLI with `run`, `watch`, `live` commands
- [x] `--viewer` option and `LUAMETRY_VIEWER` env var
- [x] License alignment verified (MIT compatible)
- [x] STEP export support (AP214 compliant)
- [x] Automated test suite with 100% feature coverage
- [x] STL import (`from_stl`) for boolean operations
- [x] CLI `--output` flag to override default output path
- [x] Refactored API (removed legacy/redundant features)
- [x] CLI `install` command support
- [x] Config file support (`~/.config/luametry/settings.lua`)
- [x] Improved error reporting with line numbers
- [x] OBJ export and import support
- [x] Dynamic watch mode (detects new files in `src/`)
- [x] CLI unit tests for stability
- [x] `update` command to pull and rebuild
- [x] **3MF export** support
- [x] **Text/font extrusion** support (`cad.text`)
- [x] **PNG Screenshot support** (`luametry screenshot`)
- [x] ~~ASCII terminal preview~~ (Replaced by high-quality screenshot)

## Future Improvements
- [ ] Support for multiple CAD kernels (OpenCascade, etc.)
- [ ] Improve watch mode to use native OS events (inotify/fsevents)
- [ ] Web-based viewer integration
- [ ] Support for texture coordinates in OBJ export

## Potential Features
- [ ] Chamfer/Fillet operations (2D & 3D)
- [ ] STL repair/optimization utilities
- [ ] SVG import support
