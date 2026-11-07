# open-folder

Lets a Notion page open its Google Drive folder in Windows **Explorer**, and puts the browser back behind Notion afterwards, for these links and for open-todoist's. Notion only accepts web links, and browsers won't open local folders from a web page, so this has two parts:

- `index.html`, a redirect page on GitHub Pages: `https://gabrielbusch08.github.io/open-folder/#<folder name>`. It hands the name to an `openfolder:` link. On a phone, or a PC without the install, it offers a Google Drive search for the folder instead.
- `OpenFolder.cs`, a small Windows program that handles `openfolder:` links. It finds the Drive's `My Drive` / `Meu Drive` folder, looks for a folder with that name in `02 AREAS` and `01 PROJECTS` (up to three levels down, shallowest first) and opens it. Names match loosely: no case, accents, spaces, punctuation or emoji. If no folder has that name, it offers to create one in `01 PROJECTS\IN PROGRESS` (characters Windows doesn't allow in names, like `/`, become `-`), then opens it. Apart from that, the name is only compared, never turned into a path, and the program only opens folders. Each link is logged to `%LOCALAPPDATA%\open-folder\log.txt`.

The link carries the folder's **name**, so it keeps working when a project folder moves between Ideas, Backlog, ACTIVE PROJECTS and Archive. The one rule: a Drive folder keeps the same name as its Notion page.

After opening the folder, or a Todoist project from an `opentodoist:<ID>` link, the program sends the browser window behind every other window, so the Notion window it covered shows again. open-todoist's page uses `opentodoist:` instead of `todoist://` once its `#helper-on` link has been opened in that browser; the installer opens it. `#helper-off` switches back.

In Notion, the `Folder` formula on Projects DB and Areas DB builds the link from the page's name, so nothing is filled in by hand.

## Install (once per Windows PC, no admin rights)

Open **Windows PowerShell** (Start menu) and paste these two lines, one at a time:

```
[Net.ServicePointManager]::SecurityProtocol='Tls12'
irm https://gabrielbusch08.github.io/open-folder/install.txt | iex
```

`install.txt` is a PowerShell script; the `.txt` makes GitHub Pages serve it as text, which `irm` needs. It builds `open-folder.exe` in `%LOCALAPPDATA%\open-folder` with Windows' own C# compiler and registers `openfolder:` and `opentodoist:` links for this user, then opens open-todoist's `#helper-on` page in the default browser. Run it again to update. The first click in Firefox asks which app to use: pick open-folder and tick "Always".

If the Drive sits somewhere unusual, put its `My Drive` path in `%LOCALAPPDATA%\open-folder\drive.txt`.

Uninstall: open `https://gabrielbusch08.github.io/open-todoist/#helper-off` in Firefox, delete the registry keys `HKEY_CURRENT_USER\Software\Classes\openfolder` and `...\opentodoist`, and the folder `%LOCALAPPDATA%\open-folder`.

## Quiet tab

Like open-todoist: after "close this tab by itself from now on" is clicked once (kept per browser), the page is a blank dark tab that hands off after 0.1 s and closes itself.
