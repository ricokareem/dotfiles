# dotfiles

macOS shell and tool configuration, managed with [chezmoi](https://www.chezmoi.io/).

The old version of this repo was a pile of un-dotted files (`zshrc`, `gitconfig`)
plus a README telling you to rename and copy them by hand. This version is
declarative: `chezmoi apply` puts every file where it belongs, installs the
packages, and can be re-run any time to pull the machine back into line.

## Fresh machine

```bash
# 1. Homebrew (chezmoi and everything else comes from it)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. chezmoi
brew install chezmoi

# 3. Initialise from this repo and apply in one step.
#    Prompts for your git name + email, then does everything below.
chezmoi init --apply ricokareem
```

That last step will:

1. Write `~/.config/chezmoi/chezmoi.toml` with the identity you typed
2. Install everything in `~/.Brewfile` (`brew bundle`)
3. `mise install` the runtimes in `~/.config/mise/config.toml`
4. Install oh-my-zsh if it isn't there
5. Lay down the shell, git, npm, mise, and Ghostty config

Then open a new terminal. If zsh isn't your login shell yet: `chsh -s /bin/zsh`.

### Working from an existing checkout

By default chezmoi keeps its source in `~/.local/share/chezmoi` and clones into
it. If you'd rather edit the repo where you already have it checked out, point
`sourceDir` at that path in `~/.config/chezmoi/chezmoi.toml`:

```toml
sourceDir = "~/projects/ricokareem/dotfiles"
```

`chezmoi edit`, `chezmoi cd`, and `chezmoi apply` all follow it, so there's only
one copy of the source to keep straight. Without this you get two — the checkout
you're editing and the one chezmoi actually applies from, which silently diverge.

## Day to day

```bash
chezmoi diff                 # what would change in $HOME
chezmoi apply                # apply it
chezmoi edit ~/.zshrc        # edit the SOURCE of a managed file
chezmoi add ~/.some-config   # start managing a new file
chezmoi update               # git pull + apply
chezmoi cd                   # drop into this repo to commit/push
```

> [!IMPORTANT]
> Edit the **source**, not the target. Changing `~/.zshrc` directly works until
> the next `chezmoi apply` silently overwrites it. Use `chezmoi edit ~/.zshrc`,
> or edit `dot_zshrc` in this repo — same file, chezmoi just knows the mapping.
> `chezmoi diff` will show you if the two have drifted.

## Identity

Nothing in this repo hard-codes a name or email — it's a public repo. Both come
from `~/.config/chezmoi/chezmoi.toml`, which is per-machine and never committed.
`chezmoi init` prompts for them. To change them later:

```bash
chezmoi edit-config   # opens ~/.config/chezmoi/chezmoi.toml
chezmoi apply
```

```toml
[data]
  git_name  = "Your Name"
  git_email = "you@example.com"
```

Both keys are required: a template referencing an unset key aborts the entire
apply with `map has no entry for key ...`, which doesn't hint at the fix. If you
add a template that needs a new value, add a prompt for it in
`.chezmoi.toml.tmpl` *and* document it here.

## Secrets and machine-local config

Never put a secret in a managed file — not even a `.tmpl`, since the rendered
source still lives in this public repo. Two escape hatches, both sourced
automatically and neither committed:

| File | Sourced by | Use it for |
|---|---|---|
| `~/.zshenv.local` | every shell | secrets, API tokens, env vars scripts need |
| `~/.zshrc.local` | interactive shells | aliases, project shortcuts, work-only config |

```bash
# ~/.zshenv.local
export ELASTIC_PASSWORD="..."
export OPENAI_API_KEY="..."
```

Both files are `chmod 600` and sourced behind an existence check, so a machine
without them is fine.

## What's managed

| Target | Source | Purpose |
|---|---|---|
| `~/.zshenv` | `dot_zshenv` | `PATH` and env for **all** shells — scripts, cron, GUI apps, agent shells |
| `~/.zshrc` | `dot_zshrc` | Interactive only: oh-my-zsh, prompt, fzf, aliases, functions |
| `~/.zprofile` | `dot_zprofile` | Intentionally empty; managed so installers can't quietly regrow it |
| `~/.gitconfig` | `dot_gitconfig.tmpl` | Identity (templated), aliases, sane merge/push defaults |
| `~/.gitignore_global` | `dot_gitignore_global` | `core.excludesfile` — `.DS_Store`, `.envrc`, editor dirs |
| `~/.npmrc` | `dot_npmrc` | `legacy-peer-deps` |
| `~/.Brewfile` | `dot_Brewfile` | Homebrew formulae and casks |
| `~/.config/mise/config.toml` | `dot_config/mise/config.toml` | Global runtime versions |
| `~/.config/ghostty/config` | `dot_config/ghostty/config` | Terminal appearance, keybindings |

## The three shell files

This trips people up constantly, so: zsh sources them in this order, and each
has one job.

```mermaid
flowchart LR
    A["<b>~/.zshenv</b><br/>EVERY shell<br/>PATH, env vars, secrets"] --> B["<b>/etc/zprofile</b><br/>macOS runs path_helper<br/>⚠ hoists /usr/bin to front"]
    B --> C["<b>~/.zprofile</b><br/>login shells<br/>(kept empty)"]
    C --> D["<b>~/.zshrc</b><br/>INTERACTIVE only<br/>re-asserts PATH order,<br/>prompt, aliases"]

    classDef env fill:#d6eaf8,stroke:#5499c7,color:#1a3a5c
    classDef warn fill:#fdebd0,stroke:#e59866,color:#6e2c00
    classDef rc fill:#d5f5e3,stroke:#7dcea0,color:#145a32
    class A env
    class B warn
    class C,D rc
```

Two consequences worth knowing before you edit anything:

- **`PATH` belongs in `.zshenv`.** It used to live in `.zshrc`, which meant any
  non-interactive shell — a script, a cron job, an editor's integrated tooling —
  got the bare macOS `PATH` and couldn't find mise-managed node, pnpm globals,
  or brew.
- **`.zshrc` re-prepends a few entries anyway, and that is not a bug.** macOS
  `/etc/zprofile` runs `path_helper` *after* `.zshenv`, which rebuilds `PATH`
  with `/usr/bin` and friends at the front. The re-assert in `.zshrc` puts mise
  shims and Homebrew back in front. Both files strip an existing copy before
  (pre|ap)pending, so re-sourcing can never duplicate an entry.

## Bootstrap script order

Two things order these scripts, and both are load-bearing.

**`_after_` vs `_before_`** — chezmoi runs `_before_` scripts, *then* writes the
target files, *then* runs `_after_` scripts. All three of these scripts are
`_after_` because each one reads a file chezmoi has to write first:

| Script | Reads |
|---|---|
| `10-brew-bundle` | `~/.Brewfile` |
| `20-mise-install` | `~/.config/mise/config.toml` |
| `30-oh-my-zsh` | (nothing, but `.zshrc` expects its output) |

> [!WARNING]
> Getting this wrong fails in a way that doesn't point at the cause.
> `10-brew-bundle` was briefly a `_before_` script, and on a first apply it ran
> against a `~/.Brewfile` that did not exist yet — chezmoi hadn't written it.

**The numeric prefix** orders them against each other, since `_after_` scripts
run in filename order:

```
10-brew-bundle   → installs mise, ghostty, fonts, everything else
20-mise-install  → needs the mise binary from step 10
30-oh-my-zsh     → the prompt .zshrc expects
```

**`run_onchange_` re-runs on content change**, which is why each script embeds a
`sha256sum` of the file it acts on. Without that line, editing the Brewfile
would leave the script byte-identical and nothing would ever install.

One failed script aborts the whole apply, including the file writes that would
otherwise have happened after it. That's a safe default — a half-applied machine
is worse — but it means a broken script leaves `$HOME` completely untouched
rather than partially updated.

## What changed from the old setup

Kept because you use them: oh-my-zsh + cobalt2, fzf, bun, GAM7, `ghistory`,
`cdf`, the weather alias, `legacy-peer-deps`.

Removed or reworked, with reasons:

| Change | Why |
|---|---|
| `./node_modules/.bin` off `PATH` | A relative entry on `PATH` means any directory you `cd` into can put its own `tsc`/`test`/`ls` ahead of the real one. Use `npx` / `pnpm exec`. |
| Fixed `...gam7:$PATH"export PATH=...` | Two `export`s were concatenated with no newline in the old `zshrc`, so `~/.local/bin` never actually made it onto `PATH`. |
| `jenv` → `use-jdk` function | jenv shimmed every `java` call and cost ~150ms per shell to manage JDKs used by maven and IntelliJ. `use-jdk 17` does the same thing via `/usr/libexec/java_home`, for free. |
| conda init → `conda-on` function | The `conda initialize` block ran in every shell (~200ms) for something used occasionally. Same block, now on demand. |
| asdf removed | mise already replaced it; the commented-out asdf lines and `.tool-versions` java pin were dead weight. |
| Android / Cordova / Dart / capybara-webkit exports dropped | Cordova-era leftovers pointing at SDK paths and a `qt@5.5` that no longer exists. |
| `push.default = tracking` → `simple` | `tracking` pushes to a differently-named upstream branch without complaint. `simple` refuses. |
| `core.excludesfile` `/Users/rico/...` → `~/...` | The absolute path silently did nothing on any machine with a different username. |
| iTerm2 → Ghostty | iTerm2 keeps settings in a binary plist it rewrites on quit, so it could only be tracked by manual JSON export — which is why the old `iterm2-profiles/` went stale and got deleted. Ghostty's config is a text file chezmoi manages directly. |
| `libxml2-libxslt-notes.txt` deleted | Nine-year-old `brew info` output for `/usr/local` paths that don't exist on Apple Silicon. |
| `default-gems`, `.projections.json`, `eslintrc.json` deleted | asdf-ruby, a VS Code extension, and a linter config that all belong per-project now. |

Anything removed is still in git history — `git log --diff-filter=D --name-only`
will find it.

## Notes

- **oh-my-zsh is not managed here.** It's a self-updating git checkout; chezmoi
  installs it once (step 30) and then leaves it alone. `.zshrc` degrades
  gracefully if it's missing — warns on stderr, runs a bare `compinit`, and
  leaves you promptless rather than broken.
- **The cobalt2 theme needs a Nerd Font.** `cask "font-meslo-lg-nerd-font"` in
  the Brewfile covers it. Without it the prompt separators render as tofu.
- **`brew bundle` never uninstalls.** Deleting a line from the Brewfile is inert
  until you run `brew bundle cleanup --global --force`.
