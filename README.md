# open-folder

Lets a Notion page open its Google Drive folder in Windows **Explorer**. Notion only accepts web links, and browsers won't open local folders from a web page, so this has two parts:

- `index.html`, a redirect page on GitHub Pages: `https://gabrielbusch08.github.io/open-folder/#<folder name>`. It hands the name to an `openfolder:` link. On a phone, or a PC without the install, it offers a Google Drive search for the folder instead.
- `open-folder.ps1`, a PowerShell script that handles `openfolder:` links. It finds the Drive's `My Drive` / `Meu Drive` folder, looks for a folder with that name in `02 AREAS` and `01 PROJECTS` (up to three levels down, shallowest first) and opens it. Names match loosely: no case, accents, spaces, punctuation or emoji. If no folder has that name, a PowerShell window asks whether to create one in `01 PROJECTS\IN PROGRESS` (characters Windows doesn't allow in names, like `/`, become `-`), then opens it. Apart from that, the name is only compared, never turned into a path, and the script only opens folders. Each link is logged to `%LOCALAPPDATA%\open-folder\log.txt`.

The link carries the folder's **name**, so it keeps working when a project folder moves between stages. The one rule: a Drive folder keeps the same name as its Notion page.

In Notion, the `Folder` formula on Projects DB and Areas DB builds the link from the page's name, so nothing is filled in by hand.

**Why a script and not a program:** Windows 11's Smart App Control blocks unsigned programs, and the first version (`open-folder.exe`, built on the PC from C#) was unsigned, so it got blocked (18 November 2026). The script runs in Windows' own PowerShell, which Microsoft signs, through `conhost --headless` so no window flashes. It sticks to what PowerShell's Constrained Language mode allows (no `Add-Type`, no .NET classes beyond basic types), in case Smart App Control imposes it, and is kept to ASCII because Windows PowerShell reads a file without a BOM as ANSI. What was lost with the program: it put the browser back behind Notion after a link, which needed Windows calls a script in that mode can't make.

It still handles `opentodoist:<ID>` links (opens the Todoist app on that project), for a browser where open-todoist's `#helper-on` is still set. The installer, when it replaces the old program, opens `#helper-off` so Todoist links go straight to the Todoist app again.

## Install (once per Windows PC, no admin rights)

Open **Windows PowerShell** (Start menu) and paste this line:

```
irm https://gabrielbusch08.github.io/open-folder/install.txt | iex
```

`install.txt` is a PowerShell script; the `.txt` makes GitHub Pages serve it as text, which `irm` needs. It saves `open-folder.ps1` in `%LOCALAPPDATA%\open-folder`, removes the old `open-folder.exe` if there is one, and registers `openfolder:` and `opentodoist:` links for this user. Run it again to update. If Firefox asks which app to use for a link, pick the one it offers and tick "Always".

If the Drive sits somewhere unusual, put its `My Drive` path in `%LOCALAPPDATA%\open-folder\drive.txt`.

Uninstall: delete the registry keys `HKEY_CURRENT_USER\Software\Classes\openfolder` and `...\opentodoist`, and the folder `%LOCALAPPDATA%\open-folder`.

## Quiet tab

Like open-todoist: after "close this tab by itself from now on" is clicked once (kept per browser), the page is a blank dark tab that hands off after 0.1 s and closes itself.
