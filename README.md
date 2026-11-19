# Codice Photos Viewer

Public, static catalog viewer for comparing source jacket photography with
generated front, rear, three-quarter, and detail views.

Only web-ready viewer files are stored in this repository. Raw photography and
other production assets remain outside the public Git history.

## Local preview

```bash
python3 -m http.server 4173
```

Then open `http://127.0.0.1:4173/viewer/`.

## Tests

```bash
node --test viewer/tests/zoom.test.mjs
bash scripts/verify-public-repo.sh
```

## Publish

GitHub Pages is served from the generated `gh-pages` branch. After verifying a
change on `main`, publish it with:

```bash
bash scripts/publish-pages.sh
```
