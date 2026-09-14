# template-php-project

Template for PHP 8.5 applications with strict static analysis, testing, and coding standards.

## Stack

- Language: PHP 8.5
- Runtime: GNU/Linux
- Libraries: none (template skeleton)
- Package managers: composer, npm

## Toolchain

- Format: php-cs-fixer 3.x, prettier 3.x, trimmer
- Lint: eslint 10.x, phpstan 2.x
- Test: phpunit 13.x with coverage gate
- Audit: composer audit, roave advisories, npm audit

## Devcontainer

- Base: official PHP CLI
- User: devcontainer
- Sidecars: mysql (migrations target), valkey (cache)
- Up: `make up`
- Execute: `devcontainer exec --workspace-folder . <command>`
- Down: `make down`

## Makefile

- `update` — refresh locks, only tool that may touch them
- `fix` — auto-fix, may dirty tree
- `check` — full gate: doctor + lint + analyze + coverage + audit
- `doctor` — tree and toolchain ok
- `lint` — eslint + php-cs-fixer + prettier + trimmer checks
- `analyze` — npm + composer + phpstan checks
- `test` — phpunit suite
- `coverage` — coverage gate
- `audit` — composer + npm audits
- `postcreate` — first-time setup, runs automatically on create
- `stop` — stop container, keep it
- `down` — stop and remove container
- `destroy` — tear down volumes and sidecars
- `clean` — drop generated files
- `distclean` — drop everything rebuildable
- `rebuild` — full rebuild, only when broken

## Layout

├── Makefile
├── .editorconfig
├── .devcontainer/
├── composer.json
├── phpstan.neon
├── phpunit.xml
├── package.json
├── eslint.config.js
├── prettier.config.js
├── LICENSE
├── AUTHORS.md
├── public/
│   └── index.php
├── src/
│   └── Main.php
└── tests/
