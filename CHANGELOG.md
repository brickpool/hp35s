# Changelog
This CHANGELOG file is intended to help document all the details of HP35s development.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.6] - 2019-06-07
### Added
- syntax checking for EQN
- unicode und plantext support for EQN
- new key sequences
- optimization of key sequences

### Changed
- Trigraph `\h-` to `\023`
- option `--ascii`, `-a` to `--plain`, `-p`

### Fixed
- key sequence for `\->`, `(` and `)`

## [0.3.5] - 2019-06-04
### Added
- Charater-Set files to `extras`

### Changed
- trigraph `\Mi` to `\im`
- `&#x25B6;` to `&#x25BA;`
- `&#x1F132;` to `&#x1F172;`
- EQN character `%` and `,`
- instruction `EQN` to `eqn`

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
- adding trigraphs to key sequences
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
- fixing key sequences for CF, FIX, ... and EQN

## 0.3.0 - 2019-05-09
### Added
- key sequences (option `--shortcut` or `-s`)

### Fixed
- bugfix <-ENG

## 0.2.2 - 2019-05-08
### Added
- support r &theta; a

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
- bugfix GTO add parser (Parser::HPC)

## 0.1.2 - 2019-04-29
### Changed
- pre-alpha release of Parser::HPC

## 0.1.1 - 2019-04-12
### Added
- added parser Parser::HPC

## 0.1.0 - 2019-04-09
### Added
- Initial version created

[Unreleased]: https://github.com/brickpool/hp35s/compare/v0.3.6...HEAD
[0.3.6]: https://github.com/brickpool/hp35s/compare/v0.3.5...v0.3.6
[0.3.5]: https://github.com/brickpool/hp35s/compare/v0.3.4...v0.3.5
