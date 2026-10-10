# Zero-Basis Install Guide (starting from a machine with no compiler at all)

Applies to: Windows 10 / 11. Every install here is a **one-time** job — after that, new projects just reuse the generated config.

Follow the steps in order; each step ends with "how to verify". Roughly four installs in total.

> Once you are comfortable, print the same guidance from the terminal:
> `powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-dir>\scripts\new-project.ps1" -Guide -Lang en`

---

## Step 0: Prerequisites

- Windows 10 / 11
- Internet access
- Administrator rights (installing Visual Studio triggers a UAC prompt — click Yes)
- An editor already installed (Trae or VS Code). If not, install the editor first; this skill's config takes effect through its `.vscode` folder.

---

## Step 1: Install Visual Studio 2022 (provides the C / C++ compiler)

**What it gives you**: `cl.exe` (MSVC). Both C and C++ are compiled with it.

**Option A — automatic (recommended; winget ships with Win10/11)**

```powershell
winget install Microsoft.VisualStudio.2022.Community --override "--quiet --wait --add Microsoft.VisualStudio.Workload.NativeDesktop"
```

**Option B — manual**
1. Download the Community edition from https://visualstudio.microsoft.com/vs/community/
2. Run the installer and on the **Workloads** page make sure **Desktop development with C++** is checked
3. Leave the right-hand "Installation details" at their defaults and install

**Verify**
- `VC\Tools\MSVC\<version>\bin\Hostx64\x64\cl.exe` exists under the install folder
- Or open **Developer PowerShell for VS 2022** from the Start menu and type `cl` — you should see version info

> Note: typing `cl` in a **normal** PowerShell window normally says "not recognized" — that is expected. The scripts in this skill enter the VS developer environment automatically, so you never have to edit PATH by hand.

---

## Step 2: Install MiKTeX (provides the LaTeX engine)

**What it gives you**: `xelatex`, used to compile LaTeX (`.tex` → `.pdf`).

**Option A — automatic**

```powershell
winget install MiKTeX.MiKTeX
```

**Option B — manual**
1. Download the installer from https://miktex.org/download
2. Choose **Install for me only** and accept the defaults

**Verify**
- **Open a new terminal** (important: PATH only refreshes in a new shell) and run `xelatex --version`

> Skip this step if you only need C/C++.

---

## Step 3: Install the 3 editor extensions

Search and install these from the editor's **Extensions** view (the squares icon on the left):

| Extension | Extension ID | Purpose |
|---|---|---|
| clangd | `llvm-vs-code-extensions.vscode-clangd` | C/C++ completion and diagnostics |
| CodeLLDB | `vadimcn.vscode-lldb` | F5 debugging (`launch.json` depends on it) |
| LaTeX Workshop | `james-yu.latex-workshop` | LaTeX build and PDF preview |

**From the command line** (when the editor CLI is on PATH):

```powershell
code --install-extension llvm-vs-code-extensions.vscode-clangd
code --install-extension vadimcn.vscode-lldb
code --install-extension james-yu.latex-workshop
```

**Verify**: all three appear in the extensions list, enabled.

### If an extension fails to install

Outside mainland China this is almost always a transient network hiccup, not a blocked service — the editor marketplace (VS Code Marketplace or Open VSX) works directly.

1. **Install from the built-in marketplace** — click the Extensions icon and search for clangd / CodeLLDB / LaTeX Workshop.
2. **Install from the command line** — the `code --install-extension ...` commands above.
3. **Offline VSIX** — if both of the above fail, download the `.vsix` and use Extensions view → `...` → **Install from VSIX...**
   - clangd: https://open-vsx.org/extension/llvm-vs-code-extensions/vscode-clangd
   - CodeLLDB: https://open-vsx.org/extension/vadimcn/vscode-lldb
   - LaTeX Workshop: https://open-vsx.org/extension/james-yu/latex-workshop

4. **Installed but not working** — clangd and CodeLLDB download their own binaries from **GitHub Releases** on first run, which is a normal outbound connection. If it fails, retry; if you are behind a corporate proxy, set `HTTP_PROXY` / `HTTPS_PROXY` and restart the editor.
   - **clangd**: download `clangd-windows-*.zip`, unzip it, and point `clangd.path` in `settings.json` at `clangd.exe`
   - **CodeLLDB**: retry, or place the platform binary manually

**Verify**: after restarting the editor the extensions show as enabled; you get C/C++ completion and F5 starts a debug session.

---

## Step 4: Write the project config

1. Open a terminal in your project folder
2. Run (replace `<skill-dir>` and `<project-dir>` with real paths):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-dir>\scripts\new-project.ps1" -Target "<project-dir>" -Lang en
```

The script self-checks your machine and writes `build.ps1` plus the three files under `.vscode\`.

**Verify**: every check prints `[OK]` and the last line says the config was written. Any `[FAIL]` / `[WARN]` points you back to the matching step.

---

## Step 5: End-to-end check

1. Copy `<skill-dir>\assets\samples\hello.c` into the project root
2. Open the project folder in the editor, open `hello.c`, press **F5**
3. The terminal should print `Hello World!`

LaTeX: copy `sample.tex` over, press **Ctrl+Alt+B**, and `sample.pdf` should appear.

---

## Common pitfalls

| Symptom | What to do |
|---|---|
| Tool installed but still unavailable | **Restart the editor** (sometimes the terminal too) so PATH refreshes |
| `winget` not found | Use the manual "Option B" above, or update "App Installer" from the Microsoft Store |
| `cl` not found in a normal terminal | Expected — the script enters the VS environment for you; do not run `cl` by hand |
| Red squiggles in C/C++ headers | The script already injects `--query-driver`; reload the window, or ignore it — it does not affect compiling or running |
| MiKTeX says `User/administrator updates out-of-sync` | Harmless for PDF output; run MiKTeX Console as administrator and update to clear it |
| Chinese LaTeX fails | You must use `xelatex` (the default here); do not switch to pdflatex |
| "File not found" for a path | If a path contains special characters or quotes, use a relative path instead of embedding an absolute path in the command |
| A pile of files appears after building | Normal MSVC outputs (`.exe/.obj/.pdb/.ilk`), and they are all under `build\`; delete `build\` to clean up |