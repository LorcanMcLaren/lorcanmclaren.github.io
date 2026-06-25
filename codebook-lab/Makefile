# CodeBook Lab docs build helpers.
#
# quartodoc generates the API reference under reference/ from codebook_lab's
# docstrings, so it must run before quarto. It is intentionally NOT wired as a
# Quarto `pre-render` hook: quartodoc rewrites reference/ and the watched
# _sidebar.yml on every pass, which sends `quarto preview` into an endless
# re-render loop. Running it explicitly here avoids that.
#
# Requires `quartodoc`, `quarto`, and an importable `codebook_lab` on PATH
# (e.g. `pip install -r requirements.txt`).

.PHONY: version reference render preview clean

# Write the current release version into a CSS variable (navbar badge) and a
# Quarto variable (citation page), so both stay in sync with codebook_lab.
# Regenerated on every build.
version:
	@python -c 'from importlib.metadata import version as package_version; from pathlib import Path; import re; changelog = Path("changelog.qmd"); text = changelog.read_text(encoding="utf-8") if changelog.exists() else ""; match = re.search(r"^##\s+([0-9]+(?:\.[0-9]+)*)\s*$$", text, re.M); ver = match.group(1) if match else package_version("codebook-lab"); Path("_version.css").write_text(f":root{{--pkg-version:\"v{ver}\";}}\n", encoding="utf-8"); Path("_variables.yml").write_text(f"version: {ver}\n", encoding="utf-8")'

# Regenerate the API reference from the package docstrings.
reference:
	quartodoc build

# Production build: refresh version + reference, then render the whole site.
render: version reference
	quarto render

# Local development: refresh version + reference once, then live-preview.
# Content edits live-reload; rerun `make reference` after editing docstrings.
preview: version reference
	quarto preview

clean:
	rm -rf reference .quarto _version.css _variables.yml
