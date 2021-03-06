# Changelog
This CHANGELOG file is intended to help document all the details of `HP35S` development.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.2] - 2020-08-14
### Added
- example triangle `T`
- predefined equate `??date` and `??time`

## [0.4.1] - 2020-04-28
### Added
- example weekday `W`
- folder `/extras/doc-images` with keystroke images

### Fixed
- install dir in `examples/Makefile`
- README-files in the example folder
- Constant `pi` (`\pi` is not an trigraph anymore)
- Constant `i` (`0\im1`)

### Changed
- Constant Planck constant over 2 pi (`\h-` => `hbar`)

## [0.4.0] - 2020-04-01
### Added
- `Makefile.PL` for the Parser `HPC.pm`
- `README.pod` in the example folder

### Changed
- move content from `/src/README.md` to `/README.pod`
- Move the Assembler `asm2hpc.pl` from folder `/src` to the root folder
- Move emulation files `*.ep` from root folder to `/AppData`
- Rename folder `/macros` to `/AppData/Macros`
- Rename folder `/tools` to `/extras/tools`
- Rename folder `/src` to `/examples`
- Rename folder `/src/Parser` to `/lib/Parser`
- Rename folder `/src/third-party` to `/examples/3rd-party`
- Generating `cmd` to `dmake` (`generate.cmd` to `Makefile`)

## [0.3.12] - 2020-03-27
### Added
- support of the 41 physics built-in constants (CONST Menu)
- keystroke optimization for jump to `LBL` => `GTO A` or `XEQ A`

### Fixed
- keystroke `RCL 0` => `RCL (I)`
- keystroke `RCL .` => `RCL (J)`

## [0.3.11] - 2020-03-02
### Added
- keystroke optimization for vector expressions => `eqn '[A,B]'`

### Fixed
- keystroke `[` => `\+> [] \.> \BS`
- keystroke `]` => `\+> [] \BS \.>`

## [0.3.10] - 2020-02-19
### Added
- keystroke support for expressions => `eqn 'TEXT'`

### Fixed
- key code `\CC` => `0x26`
- keystroke `\|>` => `\+> STO \CC`
- cross-program jump labels
- successive jump labels (Parser `HPC.pm`)
- option `--shortcut` or `-s`

## [0.3.9] - 2020-02-07
### Added
- keystrokes support for clear programs (option `--clear` or `-c`)
- key code support `PRGM` => `04`
- new `macro` directory with macros (`*.mac`) for the HP emulation software
- new `tool` directory for OS indepedent tools
- add some new emulation files `*.ep`

### Changed
- Update text in `README.pod`
- Update checksum in `*.asm`
- Update `src\generate.cmd`
- Update _switch case_ syntax in perl source files
- Update emulation file `ee.ep` (`ee` => `electric enginering`)
- Uu encodes output format for option `--encoded` or `-e`

### Fixed
- key `10^x` => `\<+ 10\^x` (secound try)
- key `ALOG` => `\<+ 10\^x`
- key code `y\^x` => `0x10`
- key code `1/x` => `0x11`

## [0.3.8] - 2020-01-31
### Added
- key code output support (option `--encoded` or `-e`) Uu encoded format
- keystrokes support for complex and vector statement's

### Changed
- File extensions from `*.asc` to `*.raw`

### Fixed
- del `ISG` from `@functions`
- line numbering: `$loc = $0;` => `$loc = 0;`
- retuning from sub's `sprintf_*`: `next;` => `return '';`
- key `\R|v` => `R\|v` for `REGX`, `REGY`, `REGZ` and `REGT`
- key exp `E` => `e`, char `E` => `RCL E` and hex `E` => `y^x`
- key `->LB` => `\<+ \->lb`
- key `->MILE` => `\<+ \->MILE`
- key `->IN` => `\+> \->in`
- key `10^x` => `\<+ 10\^x`
- key `,` => `\<+ ,`
- key `SOLVE` => `\+> SOLVE`
- key `RND` => `\+> RND`

## [0.3.7] - 2019-06-13
### Added
- markdown output support (option `--markdown` or `-m`)
- `*` for jump targets (option `--jumpmark` or `-j`), by Paul Dale

### Changed
- `@` support for labels
- `eqn` output, by Paul Dale

### Fixed
- optimization of ALOG for EQN

## [0.3.6] - 2019-06-07
### Added
- syntax checking for EQN
- unicode und plantext support for EQN
- new keystrokes
- optimization of keystrokes

### Changed
- Trigraph `\h-` to `\023`
- option `--ascii`, `-a` to `--plain`, `-p`

### Fixed
- keystrokes for `\->`, `(` and `)`

## [0.3.5] - 2019-06-04
### Added
- Charater-Set files to `extras`

### Changed
- trigraph `\Mi` to `\im`
- `&#x25B6;` to `&#x25BA;`
- `&#x1F132;` to `&#x1F172;`
- EQN character `%` and `,`
- rename instruction `EQN` to `eqn`, by Paul Dale

### Fixed
- fixing output of `ENG->`
- fixing syntax for `RANDOM`

### Remove
- EQN character `a` and `u`

## 0.3.4 - 2019-05-17
### Added
- support vectors and register

## 0.3.3 - 2019-05-17
### Added
- correct handling of numbers

## 0.3.2 - 2019-05-15
### Added
- adding trigraphs to keystrokes
- output can be trigraph, ascii-text or unicode
- add functions to statements

### Changed
- trigraph `\=x` to `\x-`
- trigraph `\=y` to `\y-`
- trigraph `\^x` to `\x^`
- trigraph `\^y` to `\y^`

## 0.3.1 - 2019-05-10
### Changed
- test for unknown characters at EQU

### Fixed
- fixing keystrokes for CF, FIX, ... and EQN

## 0.3.0 - 2019-05-09
### Added
- keystrokes (option `--shortcut` or `-s`)

### Fixed
- bugfix `<-ENG`

## 0.2.2 - 2019-05-08
### Added
- support 'r &theta; a'

## 0.2.1 - 2019-05-07
### Fixed
- Several bug fixes

## 0.2.1 - 2019-05-06
### Fixed
- fixing unicode handling
- '0' instruction
- non escaping for 'token_string'

## 0.2.0 - 2019-05-02
### Changed
- Rename File
- use of Parser::HPC

### Fixed
- bugfix GTO in Parser::HPC

## 0.1.2 - 2019-04-29
### Changed
- pre-alpha release of Parser::HPC

## 0.1.1 - 2019-04-12
### Added
- added parser Parser::HPC

## 0.1.0 - 2019-04-09
### Added
- Initial version created

[Unreleased]: https://github.com/brickpool/hp35s/compare/v0.4.2...HEAD
[0.4.2]: https://github.com/brickpool/hp35s/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/brickpool/hp35s/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/brickpool/hp35s/compare/v0.3.12...v0.4.0
[0.3.12]: https://github.com/brickpool/hp35s/compare/v0.3.11...v0.3.12
[0.3.11]: https://github.com/brickpool/hp35s/compare/v0.3.10...v0.3.11
[0.3.10]: https://github.com/brickpool/hp35s/compare/v0.3.9...v0.3.10
[0.3.9]: https://github.com/brickpool/hp35s/compare/v0.3.8...v0.3.9
[0.3.8]: https://github.com/brickpool/hp35s/compare/v0.3.7...v0.3.8
[0.3.7]: https://github.com/brickpool/hp35s/compare/v0.3.6...v0.3.7
[0.3.6]: https://github.com/brickpool/hp35s/compare/v0.3.5...v0.3.6
[0.3.5]: https://github.com/brickpool/hp35s/compare/v0.3.4...v0.3.5
