.PHONY: install test lint format doctor clean sync-wiki update-badges

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

clean:
	rm -rf .aur-publish .ash-setup data/tmp/*

sync-wiki:
	bash .github/scripts/sync-wiki.sh

update-badges:
	bash .github/scripts/update-badges.sh
