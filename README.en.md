[中文](README.md) | [English](README.en.md)

# c-cpp-latex-env-setup

A **TRAE / VS Code skill** that sets up a one-click build & debug environment for **C and C++ (MSVC)**, **Python** and **LaTeX (MiKTeX / TeX Live)** on Windows.

When you start a new project it auto-detects the toolchain already on your machine and writes the configs for `F5` (build/run + debug) and `Ctrl+Alt+B` (build PDF) in one go — and if the machine has nothing installed yet, it walks you through the installs step by step.

---

## What it solves

- **Re-configuring the interpreter for every new project?** One command writes the `.vscode/` config; reuse it for every project afterwards.
- **No compiler installed at all?** Run it with `-Guide` and the terminal prints the install command, download link and verification step for each piece.
- **Hard-coded paths that break on another machine?** It locates Visual Studio via `vswhere`, detects the TeX distribution and the Python interpreter automatically — different drive letters or versions are fine.
- **Red squiggles all over your C/C++ headers?** It injects the MSVC `cl.exe` path into clangd's `--query-driver`, and writes the Python interpreter into `python.defaultInterpreterPath`.
- **Multiple source files?** `build.ps1 -All` compiles every source file in the folder and links them together.

## Requirements

| Item | Requirement |
|---|---|
| OS | Windows 10 / 11 |
| Editor | Trae or VS Code |
| C / C++ | Visual Studio 2022 with the **Desktop development with C++** workload |
| Python (optional) | CPython 3.x, with **Add python.exe to PATH** checked during install |
| LaTeX (optional) | MiKTeX or TeX Live, with `xelatex` on PATH |
| Extensions | clangd, CodeLLDB, LaTeX Workshop, Python (the script checks for these and tells you what is missing) |

Everything runs offline. Extensions install from the VS Code Marketplace or Open VSX; clangd / CodeLLDB download their own binaries from GitHub Releases on first run. No proxy is needed.

## Quick start

### 1. Install the skill

Clone into the editor's global skills directory (for VS Code use your own data folder instead of `.trae-cn`):

```powershell
git clone https://github.com/yifantu067-ctrl/c-cpp-latex-env-setup.git "$env:USERPROFILE\.trae-cn\skills\c-cpp-latex-env-setup"
```

> No git? Download the ZIP, extract it, and drop the `c-cpp-latex-env-setup` folder into `%USERPROFILE%\.trae-cn\skills\`.

### 2. Starting from nothing: read the install guide

If the machine has no compiler yet, run with `-Guide` (no `-Target` needed):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.trae-cn\skills\c-cpp-latex-env-setup\scripts\new-project.ps1" -Guide -Lang en
```

Follow the 6 steps it prints to install Visual Studio, MiKTeX, Python and the editor extensions. Full details: [references/install-guide.en.md](references/install-guide.en.md).

### 3. Write the project config

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.trae-cn\skills\c-cpp-latex-env-setup\scripts\new-project.ps1" -Target "D:\your-project" -Lang en
```

The script first self-checks the machine (colour-coded `OK / WARN / FAIL`, printing the install command for anything missing), then writes:

- `build.ps1` → project root
- `tasks.json`, `launch.json`, `settings.json` → project `.vscode/`

Self-check only, without writing files: add `-CheckOnly`.
English terminal output: `-Lang en` (default is Chinese).

### 4. Verify

Copy `assets\samples\hello.c` into the project root, open it and press **F5** — the terminal should print `Hello World!`.
For Python copy `hello.py` and press **F5**; for LaTeX copy `sample.tex` and press **Ctrl+Alt+B** — `sample.pdf` should appear.

## Usage

| File type | Action | Result |
|---|---|---|
| `.c` / `.cpp` | **F5** | Build and start debugging |
| `.py` | **F5** | Run and debug with the detected Python interpreter (`debugpy`) |
| Multiple files | `build.ps1 -Source xx.cpp -All` | Compile every `.c/.cpp/.cc/.cxx` in the folder, then link |
| `.tex` | **Ctrl+Alt+B** / **Ctrl+Alt+V** | Build PDF / preview (auto-builds on save) |

> Note: `-All` compiles **every** source file in the folder. If the folder also holds another sample with a `main` (such as `hello.c`), you get `LNK2005 duplicate definition` — move or delete the extra file first.

All build outputs go into a **`build\`** folder in the project (`.exe` / `.obj` / `.pdb` / `.ilk`), so the project root keeps only your sources and the config. To clean up, just delete `build\`.

## Layout

```
c-cpp-latex-env-setup/
├── SKILL.md                        # Skill entry: notes, pitfalls, maintenance rules
├── README.md / README.en.md        # Repo homepage (Chinese / English)
├── scripts/
│   └── new-project.ps1             # Self-check + write config (-Guide / -CheckOnly / -Lang)
├── references/
│   ├── install-guide.md            # Chinese install guide
│   └── install-guide.en.md         # English install guide
└── assets/
    ├── build.ps1                   # Written into the project: MSVC build script
    ├── tasks.json                  # Written into .vscode: pre-F5 C/C++ build task
    ├── launch.json                 # Written into .vscode: CodeLLDB (C/C++) + debugpy (Python)
    ├── settings.json               # Written into .vscode: LaTeX Workshop + clangd + Python interpreter
    └── samples/                    # Smoke-test samples
        ├── hello.c
        ├── hello.cpp
        ├── hello.py
        └── sample.tex
```

## FAQ

| Symptom | Cause / fix |
|---|---|
| `cl` not found in a normal terminal | Expected — `cl.exe` is not on PATH; the script enters the VS developer environment for you |
| `latexmk` errors | `latexmk` needs Perl; this skill uses plain **xelatex** instead |
| Chinese LaTeX fails | Chinese requires `xelatex` (the default here); do not switch to pdflatex |
| Red squiggles in C/C++ headers | The script injects `--query-driver`; reload the window, or ignore it — it does not affect builds |
| F5 says no Python interpreter | Python was installed without **Add python.exe to PATH**; reinstall with the box checked, or restart the editor so the `python.defaultInterpreterPath` written by the script takes effect |
| Python F5 debug does not start | `launch.json` uses `type: debugpy`, which needs the **Python extension** (which brings debugpy); the script detects it and tells you if it is missing |
| Tool installed but still unavailable | **Restart the editor** so the new PATH is picked up |
| Extension will not install / spins forever | Retry from the marketplace, or install the `.vsix` from Open VSX offline |
| Extension installed but completion / F5 does not work | clangd and CodeLLDB fetch binaries from GitHub Releases on first run; retry or set `HTTP_PROXY` / `HTTPS_PROXY` |
| MiKTeX `User/administrator updates out-of-sync` | Harmless for PDF output; update via MiKTeX Console as administrator |

The full troubleshooting table is in [SKILL.md](SKILL.md); install details in [references/install-guide.en.md](references/install-guide.en.md).

## License

[MIT License](LICENSE) — free to use, modify and redistribute.