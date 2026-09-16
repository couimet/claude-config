include versions.mk

.PHONY: check lint lint-md lint-sh test scan install-prereqs

# `check` mirrors CI (markdownlint + shellcheck + bats + secret scan).
check: lint test scan

lint: install-prereqs lint-md lint-sh

# markdownlint runs via npx so no package.json is needed in this repo.
# The version is pinned in versions.mk to match the shared CI action.
lint-md:
	npx --yes markdownlint-cli2@$(MARKDOWNLINT_VERSION) "**/*.md"

# shellcheck scope mirrors the shell-ci-checks reusable workflow defaults.
lint-sh:
	find . -type f \( -name '*.sh' -o -name '*.bash' \) \
		-not -path '*/.claude-work/*' \
		-not -path '*/.history/*' \
		-not -path '*/.git/*' \
		-not -path '*/node_modules/*' \
		-exec shellcheck {} +

test: install-prereqs lint-sh
	bats bats-tests/

# Mirrors the CI secret-scan job (scans tracked content only).
scan:
	./scripts/secret-scan.sh tree

install-prereqs:
	@command -v mise >/dev/null 2>&1 || { \
		echo "Missing: mise — install it: https://mise.jdx.dev/getting-started.html"; \
		echo; \
		echo "Then re-run make install-prereqs."; \
		exit 1; \
	}
	@mise install
	@missing=""; \
	for tool in node bats shellcheck; do \
		command -v $$tool >/dev/null 2>&1 || missing="$$missing $$tool"; \
	done; \
	[ -z "$$missing" ] || { \
		echo "mise is installed, but these tools do not resolve on PATH:$$missing"; \
		echo; \
		echo "Activate mise in your shell so its shims win, then re-run make install-prereqs."; \
		echo "See https://mise.jdx.dev/getting-started.html"; \
		exit 1; \
	}
