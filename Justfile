default:
    just --list

install:
    bash install.sh

test:
    bash .git-hooks/run-tests.sh

lint:
    bash .git-hooks/validate-theme.sh
    bash .git-hooks/validate-plugin.sh

format:
    bash .git-hooks/format-scripts.sh

doctor:
    bash scripts/health/doctor.sh
