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

## Future Improvements
- [ ] Support additional export formats (OBJ, 3MF)
- [ ] Improve watch mode to detect new files
- [ ] Add unit tests for CLI parsing
- [ ] Add `update` command to pull latest and rebuild

## Potential Features
- [ ] Import OBJ files for boolean operations
- [ ] Text/font extrusion support
- [ ] Parametric preview in terminal (ASCII art)
- [ ] Web-based viewer integration
- [ ] Support for multiple CAD kernels (OpenCascade, etc.)
