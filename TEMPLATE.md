# course-template

A GitHub template for learning logs: one repo per course, same structure every time.
This file explains how to use the template. `init-course.sh` deletes it from the
generated repo, so it never ends up in your course repos.

## One-time setup

1. Push this repo to GitHub as `course-template`.
2. Settings → General → tick **Template repository**.

## Starting a new course

```bash
gh repo create learn-ml-crash-course \
  --template <your-user>/course-template --public --clone
cd learn-ml-crash-course

./scripts/init-course.sh \
  --name "Google Machine Learning Crash Course" \
  --url "https://developers.google.com/machine-learning/crash-course" \
  --lang python \
  --outline outline.tsv          # optional

git add -A && git commit -m "Initialise course" && git push
gh repo edit --add-topic learning-log
```

`--lang` is `go`, `python`, `both` or `none`. It creates `go.mod` and/or
`pyproject.toml`; CI then runs `go vet`/`go test` and `ruff`/`pytest` only when
those files exist.

`--outline` takes a tab-separated file, one module per line: `title<TAB>url`.
Copy the course's table of contents into it and every module folder is created
up front. Without it, add modules one at a time:

```bash
./scripts/new-module.sh "Linear regression" \
  "https://developers.google.com/machine-learning/crash-course/linear-regression"
```

## What each part is for

| Path | Purpose |
|------|---------|
| `modules/NN-slug/notes.md` | One page per module: before/after questions, notes in your own words, self-quiz, reflection |
| `modules/NN-slug/code/` | Exercises for that module (Go package or Python scripts) |
| `writing/` | Blog-post drafts with Hugo front matter, ready to move to your site |
| `glossary.md` | Terms in your own words, linked to the module |
| `resources.md` | Extra reading, related papers and talks |
| `AGENTS.md` / `CLAUDE.md` | Rules that keep an AI assistant in tutor mode |
| `templates/` | Source files the scripts copy from — edit these to change every future course |

## CI

`.github/workflows/checks.yml` runs ShellCheck on the scripts, Go/Python checks
when a toolchain file exists, and a link check (lychee) on push and weekly.
The link check is `continue-on-error` because course sites occasionally
rate-limit bots; treat its warnings as a to-do list for dead links.
