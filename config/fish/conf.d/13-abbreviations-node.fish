#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███╗   ██╗ ██████╗ ██████╗ ███████╗      ██╗███████╗                          ║
# ║  ████╗  ██║██╔═══██╗██╔══██╗██╔════╝      ██║██╔════╝                          ║
# ║  ██╔██╗ ██║██║   ██║██║  ██║█████╗        ██║███████╗                          ║
# ║  ██║╚██╗██║██║   ██║██║  ██║██╔══╝   ██   ██║╚════██║                          ║
# ║  ██║ ╚████║╚██████╔╝██████╔╝███████╗ ╚█████╔╝███████║                          ║
# ║  ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝  ╚════╝ ╚══════╝                          ║
# ║                                                                                  ║
# ║   ⬡ NODE.JS ABBREVIATIONS — ASH Dotfiles v5.0 OMEGA                            ║
# ║   Node • npm • pnpm • yarn • bun • deno • vite • vitest • eslint • prettier     ║
# ║                                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_abbr_node_initialized && exit 0
set -g __ash_abbr_node_initialized 1

command -sq node || command -sq deno || command -sq bun || exit 0


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⬡ NODE — Runtime
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq node
    abbr -a node   "node"
    abbr -a nodei  "node --inspect"
    abbr -a nodeb  "node --inspect-brk"            # Break before first line
    abbr -a nodets "node --loader ts-node/esm"     # TypeScript with ts-node
    abbr -a nodev  "node --version"
    abbr -a nodew  "node --watch"                  # Node built-in watch mode
    abbr -a nodee  "node --eval"                   # Run inline JS
    abbr -a nodep  "node --print"                  # Print expression result

    # REPL with preloads
    abbr -a noderepl "node --require esm"           # ESM in REPL
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔃 VERSION MANAGEMENT — fnm, nvm, n
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── fnm — Fast Node Manager (Rust) ───────────────────────────────────────────
if command -sq fnm
    abbr -a fnm    "fnm"
    abbr -a fnml   "fnm list"
    abbr -a fnmla  "fnm list-remote"
    abbr -a fnmi   "fnm install"
    abbr -a fnmilts "fnm install --lts"
    abbr -a fnmlts "fnm install lts-latest"
    abbr -a fnmu   "fnm use"
    abbr -a fnmul  "fnm use --lts"
    abbr -a fnmd   "fnm default"
    abbr -a fnmr   "fnm uninstall"
    abbr -a fnmenv "fnm env"
    abbr -a fnmver "fnm --version"
    abbr -a fnmpin "fnm use --install-if-missing"  # Pin + install if needed
    abbr -a fnmcur "fnm current"
end

# ── nvm ───────────────────────────────────────────────────────────────────────
if test -d $NVM_DIR
    abbr -a nvmi   "nvm install"
    abbr -a nvmil  "nvm install --lts"
    abbr -a nvmu   "nvm use"
    abbr -a nvmul  "nvm use --lts"
    abbr -a nvmd   "nvm alias default"
    abbr -a nvml   "nvm list"
    abbr -a nvmla  "nvm list-remote"
    abbr -a nvmr   "nvm uninstall"
    abbr -a nvmcur "nvm current"
    abbr -a nvmrun "nvm run"
    abbr -a nvmexec "nvm exec"
    abbr -a nvmver "nvm --version"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📦 NPM — Node Package Manager
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq npm
    abbr -a n      "npm"
    abbr -a ni     "npm install"
    abbr -a nia    "npm install --save-dev"
    abbr -a nig    "npm install --global"
    abbr -a nie    "npm install --save-exact"
    abbr -a nid    "npm install --save-dev"
    abbr -a nip    "npm install --save-peer"
    abbr -a niu    "npm install --save-optional"
    abbr -a niO    "npm install --no-save"
    abbr -a nidr   "npm install --dry-run"
    abbr -a nci    "npm ci"                        # Clean install from lockfile
    abbr -a ncil   "npm ci --legacy-peer-deps"
    abbr -a nr     "npm run"
    abbr -a nrb    "npm run build"
    abbr -a nrd    "npm run dev"
    abbr -a nrs    "npm run start"
    abbr -a nrt    "npm run test"
    abbr -a nrtw   "npm run test:watch"
    abbr -a nrl    "npm run lint"
    abbr -a nrlf   "npm run lint:fix"
    abbr -a nrfmt  "npm run format"
    abbr -a nrp    "npm run preview"
    abbr -a nrbld  "npm run build && npm run preview"
    abbr -a nrtb   "npm run typecheck"
    abbr -a nrclean "npm run clean"
    abbr -a nrstory "npm run storybook"
    abbr -a nre2e  "npm run e2e"
    abbr -a nrcov  "npm run test:coverage"
    abbr -a nrpkg  "npm run package"
    abbr -a nrdocs "npm run docs"
    abbr -a nrun   "npm run"                       # Explicit run alias

    abbr -a nu     "npm update"
    abbr -a nupd   "npm update"
    abbr -a noutd  "npm outdated"
    abbr -a nrm    "npm uninstall"
    abbr -a nrmg   "npm uninstall --global"
    abbr -a nls    "npm list"
    abbr -a nlsg   "npm list --global"
    abbr -a nlsd   "npm list --depth=0"
    abbr -a nsdp   "npm list --global --depth=0"
    abbr -a nf     "npm show"                      # Package info
    abbr -a ns     "npm search"
    abbr -a nsc    "npm scripts"
    abbr -a npkg   "npm pack"
    abbr -a npub   "npm publish"
    abbr -a npubd  "npm publish --dry-run"
    abbr -a nlink  "npm link"
    abbr -a nunlink "npm unlink"
    abbr -a nfix   "npm audit fix"
    abbr -a nfixf  "npm audit fix --force"
    abbr -a naudit "npm audit"
    abbr -a nautitj "npm audit --json | jq"
    abbr -a ndd    "npm dedupe"
    abbr -a nprune "npm prune"
    abbr -a nver   "npm --version"
    abbr -a nnv    "node --version && npm --version"
    abbr -a nconf  "npm config list"
    abbr -a ncg    "npm config get"
    abbr -a ncs    "npm config set"
    abbr -a ninit  "npm init"
    abbr -a ninit! "npm init --yes"
    abbr -a nwhy   "npm explain"
    abbr -a nfund  "npm fund"
    abbr -a nhome  "npm home"                      # Open package homepage
    abbr -a nrepo  "npm repo"                      # Open package repo
    abbr -a nbug   "npm bugs"                      # Open issue tracker
    abbr -a nstar  "npm star"
    abbr -a ntoken "npm token list"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📦 PNPM — Performant Node Package Manager
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq pnpm
    abbr -a p      "pnpm"
    abbr -a pi     "pnpm install"
    abbr -a pia    "pnpm add"
    abbr -a piad   "pnpm add --save-dev"
    abbr -a piag   "pnpm add --global"
    abbr -a piae   "pnpm add --save-exact"
    abbr -a piao   "pnpm add --save-optional"
    abbr -a pici   "pnpm install --frozen-lockfile"  # CI install
    abbr -a pr     "pnpm run"
    abbr -a prb    "pnpm run build"
    abbr -a prd    "pnpm run dev"
    abbr -a prs    "pnpm run start"
    abbr -a prt    "pnpm run test"
    abbr -a prtw   "pnpm run test:watch"
    abbr -a prl    "pnpm run lint"
    abbr -a prlf   "pnpm run lint:fix"
    abbr -a prfmt  "pnpm run format"
    abbr -a prp    "pnpm run preview"
    abbr -a prtb   "pnpm run typecheck"
    abbr -a pre2e  "pnpm run e2e"
    abbr -a prcov  "pnpm run test:coverage"
    abbr -a prstory "pnpm run storybook"
    abbr -a prdocs "pnpm run docs"
    abbr -a pex    "pnpm exec"
    abbr -a pdlx   "pnpm dlx"                     # Like npx without installing
    abbr -a pu     "pnpm update"
    abbr -a puint  "pnpm update --interactive"
    abbr -a puintl "pnpm update --interactive --latest"
    abbr -a poutd  "pnpm outdated"
    abbr -a prm    "pnpm remove"
    abbr -a prmg   "pnpm remove --global"
    abbr -a pls    "pnpm list"
    abbr -a plsd   "pnpm list --depth=0"
    abbr -a plsg   "pnpm list --global"
    abbr -a plsgd  "pnpm list --global --depth=0"
    abbr -a pf     "pnpm show"
    abbr -a ps     "pnpm search"
    abbr -a ppub   "pnpm publish"
    abbr -a ppubd  "pnpm publish --dry-run"
    abbr -a plink  "pnpm link"
    abbr -a punlink "pnpm unlink"
    abbr -a paudit "pnpm audit"
    abbr -a pfix   "pnpm audit fix"
    abbr -a pdd    "pnpm dedupe"
    abbr -a pprune "pnpm prune"
    abbr -a pstore "pnpm store status"
    abbr -a pstorep "pnpm store prune"
    abbr -a pinit  "pnpm init"
    abbr -a pver   "pnpm --version"
    abbr -a penv   "pnpm env"
    abbr -a penvu  "pnpm env use --global"
    abbr -a penvl  "pnpm env list"
    abbr -a pwhy   "pnpm why"
    abbr -a pfund  "pnpm fund"
    abbr -a pcreate "pnpm create"

    # Workspace commands
    abbr -a pwi    "pnpm install --workspace-root"
    abbr -a pwr    "pnpm run --recursive"
    abbr -a pwra   "pnpm run --recursive --parallel"
    abbr -a pwf    "pnpm --filter"
    abbr -a pwfa   "pnpm add --filter"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧶 YARN — Package Manager
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq yarn
    abbr -a y      "yarn"
    abbr -a yi     "yarn install"
    abbr -a yic    "yarn install --immutable"      # CI: frozen install
    abbr -a ya     "yarn add"
    abbr -a yad    "yarn add --dev"
    abbr -a yap    "yarn add --peer"
    abbr -a yao    "yarn add --optional"
    abbr -a yr     "yarn run"
    abbr -a yrb    "yarn run build"
    abbr -a yrd    "yarn run dev"
    abbr -a yrs    "yarn run start"
    abbr -a yrt    "yarn run test"
    abbr -a yrtw   "yarn run test:watch"
    abbr -a yrl    "yarn run lint"
    abbr -a yrlf   "yarn run lint:fix"
    abbr -a yrfmt  "yarn run format"
    abbr -a yrtb   "yarn run typecheck"
    abbr -a yre2e  "yarn run e2e"
    abbr -a yrcov  "yarn run test:coverage"
    abbr -a ystory "yarn storybook"
    abbr -a yrp    "yarn run preview"
    abbr -a yup    "yarn upgrade"
    abbr -a yupi   "yarn upgrade-interactive"
    abbr -a yupil  "yarn upgrade-interactive --latest"
    abbr -a youtd  "yarn outdated"
    abbr -a yrm    "yarn remove"
    abbr -a yls    "yarn list"
    abbr -a ylsd   "yarn list --depth=0"
    abbr -a yf     "yarn info"
    abbr -a ylink  "yarn link"
    abbr -a yunlink "yarn unlink"
    abbr -a yaudit "yarn audit"
    abbr -a yfix   "yarn audit fix"
    abbr -a yinit  "yarn init"
    abbr -a yinit! "yarn init --yes"
    abbr -a ypub   "yarn publish"
    abbr -a ywhy   "yarn why"
    abbr -a yver   "yarn --version"
    abbr -a yset   "yarn config set"
    abbr -a yget   "yarn config get"
    abbr -a ydlx   "yarn dlx"                     # ephemeral tool runner

    # Workspaces
    abbr -a ywi    "yarn workspaces install"
    abbr -a ywr    "yarn workspaces run"
    abbr -a ywf    "yarn workspace"
    abbr -a ywls   "yarn workspaces list"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🍞 BUN — All-in-one JavaScript runtime
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq bun
    abbr -a b      "bun"
    abbr -a bi     "bun install"
    abbr -a bic    "bun install --frozen-lockfile"
    abbr -a ba     "bun add"
    abbr -a bad    "bun add --dev"
    abbr -a bae    "bun add --exact"
    abbr -a bag    "bun add --global"
    abbr -a bao    "bun add --optional"
    abbr -a br     "bun run"
    abbr -a brb    "bun run build"
    abbr -a brd    "bun run dev"
    abbr -a brs    "bun run start"
    abbr -a brt    "bun run test"
    abbr -a brtw   "bun run test:watch"
    abbr -a brl    "bun run lint"
    abbr -a brlf   "bun run lint:fix"
    abbr -a brfmt  "bun run format"
    abbr -a brtb   "bun run typecheck"
    abbr -a bre2e  "bun run e2e"
    abbr -a brcov  "bun run test:coverage"
    abbr -a brp    "bun run preview"
    abbr -a btest  "bun test"
    abbr -a btestw "bun test --watch"
    abbr -a btestc "bun test --coverage"
    abbr -a bu     "bun update"
    abbr -a boutd  "bun outdated"
    abbr -a brm    "bun remove"
    abbr -a brmg   "bun remove --global"
    abbr -a bls    "bun pm ls"
    abbr -a blsg   "bun pm ls --global"
    abbr -a bbin   "bun pm bin"
    abbr -a bcache "bun pm cache rm"
    abbr -a bx     "bunx"                         # Like npx for bun
    abbr -a binit  "bun init"
    abbr -a binit! "bun init --yes"
    abbr -a blink  "bun link"
    abbr -a bunlink "bun unlink"
    abbr -a bver   "bun --version"
    abbr -a bupg   "bun upgrade"
    abbr -a bcreate "bun create"
    abbr -a bpub   "bun publish"
    abbr -a bpack  "bun pack"
    abbr -a bbuild "bun build"
    abbr -a bbuildmin "bun build . --minify --outdir dist"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🦕 DENO — Secure TypeScript/JavaScript runtime
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq deno
    abbr -a deno   "deno"
    abbr -a denor  "deno run"
    abbr -a denora "deno run --allow-all"
    abbr -a denorn "deno run --allow-net"
    abbr -a denorf "deno run --allow-read --allow-write"
    abbr -a denow  "deno run --watch"
    abbr -a denowa "deno run --watch --allow-all"
    abbr -a denot  "deno test"
    abbr -a denotw "deno test --watch"
    abbr -a denotc "deno test --coverage"
    abbr -a denol  "deno lint"
    abbr -a denolfix "deno lint --fix"
    abbr -a denofmt "deno fmt"
    abbr -a denofmtc "deno fmt --check"
    abbr -a denocheck "deno check"
    abbr -a denocomp "deno compile --allow-all"
    abbr -a denocomp-min "deno compile --allow-all --no-terminal"
    abbr -a denobundle "deno bundle"
    abbr -a denocache "deno cache"
    abbr -a denoclean "deno clean"
    abbr -a denodoc "deno doc"
    abbr -a denorepl "deno repl"
    abbr -a denoinfo "deno info"
    abbr -a denoinstall "deno install"
    abbr -a denoup "deno upgrade"
    abbr -a denover "deno --version"
    abbr -a denoupd "deno run --allow-read --allow-write --allow-net jsr:@deno/fresh/updater"
    abbr -a denotask "deno task"
    abbr -a denotaskl "deno task --list"
    abbr -a denoperm "deno run --allow-all --inspect"
    abbr -a denoself "deno upgrade"
    abbr -a denopub "deno publish"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⚡ VITE — Next Generation Frontend Tooling
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a vite      "npx vite 2>/dev/null || pnpm vite 2>/dev/null || bunx vite"
abbr -a vitedev   "vite dev"
abbr -a vitebuild "vite build"
abbr -a vitepreview "vite preview"
abbr -a vitecheck "vite --config vite.config.ts build --mode check"
abbr -a vitecreate "npm create vite@latest"
abbr -a vitecreate-react "npm create vite@latest -- --template react-ts"
abbr -a vitecreate-vue "npm create vite@latest -- --template vue-ts"
abbr -a vitecreate-svelte "npm create vite@latest -- --template svelte-ts"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧪 VITEST — Vite-native testing
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a vt        "vitest 2>/dev/null || npx vitest"
abbr -a vtrun     "vitest run"
abbr -a vtwatch   "vitest --watch"
abbr -a vtcov     "vitest run --coverage"
abbr -a vtui      "vitest --ui"
abbr -a vtbench   "vitest bench"
abbr -a vttypecheck "vitest typecheck"
abbr -a vtrelated "vitest related"
abbr -a vtfail    "vitest run --reporter verbose"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎭 PLAYWRIGHT / CYPRESS — E2E Testing
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq playwright || test -f node_modules/.bin/playwright
    abbr -a pw     "npx playwright"
    abbr -a pwtest "npx playwright test"
    abbr -a pwtestd "npx playwright test --debug"
    abbr -a pwtestui "npx playwright test --ui"
    abbr -a pwtesthead "npx playwright test --headed"
    abbr -a pwrec  "npx playwright codegen"
    abbr -a pwshow "npx playwright show-report"
    abbr -a pwinst "npx playwright install"
    abbr -a pwinstall "npx playwright install --with-deps"
end

if command -sq cypress || test -f node_modules/.bin/cypress
    abbr -a cy     "npx cypress"
    abbr -a cyopen "npx cypress open"
    abbr -a cyrun  "npx cypress run"
    abbr -a cyrh   "npx cypress run --headless"
    abbr -a cywait "npx cypress open --config watchForFileChanges=true"
    abbr -a cyinfo "npx cypress info"
    abbr -a cyver  "npx cypress version"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎨 CODE QUALITY — ESLint, Prettier, TypeScript
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── ESLint ────────────────────────────────────────────────────────────────────
abbr -a esl       "npx eslint"
abbr -a esll      "npx eslint ."
abbr -a eslfix    "npx eslint . --fix"
abbr -a eslq      "npx eslint . --quiet"
abbr -a eslmx     "npx eslint . --max-warnings=0"
abbr -a eslinsp   "npx eslint --inspect-config"
abbr -a eslcache  "npx eslint . --cache"
abbr -a eslcachef "npx eslint . --cache --fix"
abbr -a eslprint  "npx eslint . --print-config"
abbr -a eslci     "npx eslint . --format=github-actions"

# ── Prettier ──────────────────────────────────────────────────────────────────
abbr -a pret      "npx prettier"
abbr -a pretw     "npx prettier . --write"
abbr -a pretc     "npx prettier . --check"
abbr -a pretd     "npx prettier . --write --debug-check"
abbr -a pretf     "npx prettier --write"
abbr -a pretl     "npx prettier --list-different ."

# ── TypeScript ────────────────────────────────────────────────────────────────
if command -sq tsc || test -f node_modules/.bin/tsc
    abbr -a tsc    "npx tsc"
    abbr -a tscb   "npx tsc --build"
    abbr -a tscnoe "npx tsc --noEmit"
    abbr -a tscw   "npx tsc --watch"
    abbr -a tscwnoe "npx tsc --watch --noEmit"
    abbr -a tscinit "npx tsc --init"
    abbr -a tscv   "npx tsc --version"
    abbr -a tscshow "npx tsc --showConfig"
    abbr -a tscforce "npx tsc --force"
end

# ts-node
abbr -a tsnode    "npx ts-node"
abbr -a tsnodee   "npx ts-node-esm"
abbr -a tsnodew   "npx ts-node-dev --respawn"

# tsx (fast TypeScript runner)
if command -sq tsx || test -f node_modules/.bin/tsx
    abbr -a tsx    "npx tsx"
    abbr -a tsxw   "npx tsx watch"
    abbr -a tsxe   "npx tsx --eval"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⚙️  TOOLCHAIN — Build tools, bundlers, frameworks
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Next.js ───────────────────────────────────────────────────────────────────
abbr -a nextdev    "npx next dev"
abbr -a nextbuild  "npx next build"
abbr -a nextstart  "npx next start"
abbr -a nextlint   "npx next lint"
abbr -a nextexp    "npx next export"
abbr -a nextinfo   "npx next info"
abbr -a nextcreate "npx create-next-app@latest"

# ── Nuxt.js ───────────────────────────────────────────────────────────────────
abbr -a nuxtdev    "npx nuxi dev"
abbr -a nuxtbuild  "npx nuxi build"
abbr -a nuxtgen    "npx nuxi generate"
abbr -a nuxtstart  "npx nuxi start"
abbr -a nuxtcreate "npx nuxi@latest init"
abbr -a nuxtclean  "npx nuxi cleanup"
abbr -a nuxtanalyze "npx nuxi analyze"

# ── SvelteKit ─────────────────────────────────────────────────────────────────
abbr -a svdev      "npx vite dev"
abbr -a svbuild    "npx vite build"
abbr -a svpreview  "npx vite preview"
abbr -a svcreate   "npm create svelte@latest"
abbr -a svcheck    "npx svelte-check"

# ── Remix ─────────────────────────────────────────────────────────────────────
abbr -a remixdev   "npx remix dev"
abbr -a remixbuild "npx remix build"
abbr -a remixcreate "npx create-remix@latest"

# ── Astro ─────────────────────────────────────────────────────────────────────
abbr -a astrodev   "npx astro dev"
abbr -a astrobuild "npx astro build"
abbr -a astroprev  "npx astro preview"
abbr -a astrocreate "npm create astro@latest"
abbr -a astrocheck "npx astro check"
abbr -a astroadd   "npx astro add"

# ── Turborepo ─────────────────────────────────────────────────────────────────
abbr -a turbo      "npx turbo"
abbr -a turbobuild "npx turbo build"
abbr -a turbodev   "npx turbo dev"
abbr -a turbotest  "npx turbo test"
abbr -a turbolint  "npx turbo lint"
abbr -a turbogen   "npx turbo generate"
abbr -a turbodaemon "npx turbo daemon"
abbr -a turbocreate "npx create-turbo@latest"

# ── Nx ────────────────────────────────────────────────────────────────────────
if command -sq nx || test -f node_modules/.bin/nx
    abbr -a nx     "npx nx"
    abbr -a nxbuild "npx nx build"
    abbr -a nxtest "npx nx test"
    abbr -a nxlint "npx nx lint"
    abbr -a nxserve "npx nx serve"
    abbr -a nxgraph "npx nx graph"
    abbr -a nxaffect "npx nx affected"
    abbr -a nxrun  "npx nx run"
    abbr -a nxrm   "npx nx generate @nx/workspace:remove"
    abbr -a nxshow "npx nx show project"
    abbr -a nxlist "npx nx list"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧹 CLEANUP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a nodeclean  "rm -rf node_modules && echo '🗑️  node_modules removed'"
abbr -a nodecleanl "rm -rf node_modules package-lock.json yarn.lock pnpm-lock.yaml bun.lockb && \
                    echo '🗑️  node_modules + lockfiles removed'"
abbr -a nodefresh  "rm -rf node_modules && npm install && echo '✅ Fresh install complete'"
abbr -a nodecleancache "npm cache clean --force && \
                        pnpm store prune 2>/dev/null; \
                        yarn cache clean 2>/dev/null; \
                        echo '✅ Package manager caches cleaned'"
abbr -a nodeinfo   "echo '⬡ Node:' (node --version) '| npm:' (npm --version 2>/dev/null) \
                    '| pnpm:' (pnpm --version 2>/dev/null) '| bun:' (bun --version 2>/dev/null)"