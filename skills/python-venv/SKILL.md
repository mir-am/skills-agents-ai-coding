---
name: python-venv
description: Create or reuse a project-local Python virtual environment and ensure .venv is excluded by the repository's .gitignore
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: python
  category: project-setup
---

## What I do

- Create `.venv` in the project root using an available Python 3 interpreter
- Reuse a working environment without recreating it or changing its packages
- Preserve existing files when `.venv` is not a valid virtual environment
- Ensure the root `.gitignore` excludes `.venv/`, preserving existing content
- Verify the environment's interpreter and Git ignore behavior

## When to use me

Use when setting up a project-local Python virtual environment or ensuring an existing `.venv` stays out of Git. This workflow requires Git and a Bash-compatible POSIX environment with Python 3; it does not install project dependencies or commit changes.

## Workflow

### 1. Locate the project and interpreter

Read project instructions and any Python version requirements first. Use the Git working-tree root as the project root, including when invoked from a subdirectory. For an explicitly selected nested project, resolve its location before adapting the paths below. If there is no Git working tree, report that prerequisite instead of initializing a repository.

For a new environment, prefer a user-specified or project-required interpreter when available. The command below tries `python3`, then `python`, accepting only Python 3 with the standard-library `venv` module. Adjust the candidate list for a required version or a discovered versioned executable such as `python3.12`; do not silently substitute an incompatible version. Reuse an existing valid environment even if no separate Python executable is on `PATH`; report any conflict with the project's Python requirement.

### 2. Create or reuse, exclude, and verify

Run this block with Bash. It stops before changing an invalid `.venv`, a symlink at `.venv` or `.gitignore`, or an environment already tracked by Git. Normal interpreter symlinks inside a virtual environment are supported.

```bash
(
set -e
venv_project_root=$(git rev-parse --show-toplevel)
cd "$venv_project_root"

if [ -L .venv ] || [ -L .gitignore ]; then
  echo 'Stop: .venv or .gitignore is a symlink; preserve it and resolve the target first.' >&2
  exit 1
fi
if [ -e .gitignore ] && [ ! -f .gitignore ]; then
  echo 'Stop: .gitignore is not a regular file; leaving it unchanged.' >&2
  exit 1
fi
venv_tracked=$(git ls-files -- .venv)
if [ -n "$venv_tracked" ]; then
  echo 'Stop: .venv has tracked files; ignore rules cannot untrack them.' >&2
  exit 1
fi

verify_venv() {
  [ -f .venv/pyvenv.cfg ] && [ -x .venv/bin/python ] &&
    .venv/bin/python -I -c 'import pathlib, sys; expected = pathlib.Path(".venv").resolve(); sys.exit(0 if sys.version_info.major == 3 and sys.prefix != sys.base_prefix and pathlib.Path(sys.prefix).resolve() == expected else 1)'
}

if [ -e .venv ]; then
  if ! verify_venv; then
    echo 'Stop: existing .venv is not a working Python 3 virtual environment; preserved unchanged.' >&2
    exit 1
  fi
  echo 'Reusing .venv'
else
  venv_python=''
  for venv_candidate in python3 python; do
    if command -v "$venv_candidate" >/dev/null 2>&1 &&
       "$venv_candidate" -I -c 'import sys, venv; sys.exit(0 if sys.version_info.major == 3 else 1)' >/dev/null 2>&1; then
      venv_python="$venv_candidate"
      break
    fi
  done
  if [ -z "$venv_python" ]; then
    echo 'Stop: no usable Python 3 with the venv module found.' >&2
    exit 1
  fi
  "$venv_python" -m venv .venv
  verify_venv
  echo 'Created .venv'
fi

.venv/bin/python -I - <<'PY'
from pathlib import Path
import subprocess

def ignored_by_root():
    result = subprocess.run(
        ["git", "check-ignore", "--no-index", "-v", "-z", "--stdin"],
        input=b".venv/\0", stdout=subprocess.PIPE, check=False,
    )
    if result.returncode not in (0, 1):
        raise SystemExit("Stop: git check-ignore failed.")
    fields = result.stdout.split(b"\0")
    return (len(fields) == 5 and fields[0] == b".gitignore"
            and bool(fields[2]) and not fields[2].startswith(b"!"))

ignore = Path(".gitignore")
if not ignored_by_root():
    content = ignore.read_bytes() if ignore.exists() else b""
    newline = b"\r\n" if b"\r\n" in content else b"\n"
    separator = b"" if not content or content.endswith(b"\n") else newline
    with ignore.open("ab") as stream:
        stream.write(separator + b".venv/" + newline)
    print("Added .venv/ to root .gitignore")
else:
    print("Root .gitignore already excludes .venv/")
if not ignored_by_root():
    raise SystemExit("Stop: root .gitignore does not exclude .venv/.")
PY

verify_venv
.venv/bin/python -I -c 'import sys; print("Interpreter:", sys.executable); print("Version:", sys.version.split()[0]); print("Environment:", sys.prefix)'
git check-ignore -q -- .venv/pyvenv.cfg
git check-ignore -v -- .venv/ .venv/pyvenv.cfg
)
```

### 3. Review and report

- Report whether `.venv` was created or reused, its interpreter/version, whether `.gitignore` changed, and the verified ignore rule.
- Existing effective rules such as `/.venv/` or broader patterns are sufficient; do not append a duplicate. Global excludes, `.git/info/exclude`, and `.venv/.gitignore` alone are insufficient because the repository's root `.gitignore` must provide the exclusion. A later negation can require a new final `.venv/` rule; retain the existing rules.
- To verify repeatability, run the block again and confirm it reports reuse, leaves `.gitignore` byte-for-byte unchanged, and preserves `pyvenv.cfg` and the interpreter's modification times. Do not recreate the environment just to test it.
- Use `.venv/bin/python` directly for subsequent Python commands. Optionally show `source .venv/bin/activate` for the user's Bash/Zsh session; activation in a tool subprocess does not activate the user's shell.

## Errors and recovery

- If creation fails (for example, missing `ensurepip` support), report the exact error and the needed interpreter/venv dependency. Preserve any partial `.venv`; do not delete it, retry creation over it, or use `--clear` without explicit authorization.
- If `.venv` is an ordinary file, invalid directory, broken environment, or symlink, stop and report its path. Do not rename, remove, or repair existing files automatically.
- If environment files are tracked, report them and explain that `.gitignore` cannot remove them from the index. Do not run `git rm --cached` as part of setup.
- If ignore editing or final verification fails, report the incomplete setup and retain the environment and existing ignore content. Do not claim success based only on an interpreter version or an ignore-rule text match.
