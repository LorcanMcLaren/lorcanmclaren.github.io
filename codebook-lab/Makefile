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

# Write the installed package version into a CSS variable (navbar badge) and a
# Quarto variable (citation page), so both stay in sync with codebook_lab.
# Regenerated on every build.
version:
	@python -c "from importlib.metadata import version as v; ver=v('codebook-lab'); open('_version.css','w').write(':root{--pkg-version:\"v'+ver+'\";}\n'); open('_variables.yml','w').write('version: '+ver+'\n')"

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
