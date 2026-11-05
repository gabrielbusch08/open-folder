# open-folder

Lets a Notion page open its Google Drive folder in Windows **Explorer**. Notion only accepts web links, and browsers won't open local folders from a web page, so this has two parts:

- `index.html`, a redirect page on GitHub Pages: `https://gabrielbusch08.github.io/open-folder/#<folder name>`. It hands the name to an `openfolder:` link. On a phone, or a PC without the install, it offers a Google Drive search for the folder instead.
- `OpenFolder.cs`, a small Windows program that handles `openfolder:` links. It finds the Drive's `My Drive` / `Meu Drive` folder, looks for a folder with that name in `02 AREAS` and `01 PROJECTS` (up to three levels down, shallowest first) and opens it. Names match loosely: no case, accents, spaces, punctuation or emoji. The name is only compared, never turned into a path, and the program only opens folders.

The link carries the folder's **name**, so it keeps working when a project folder moves between Ideas, Backlog, ACTIVE PROJECTS and Archive. The one rule: a Drive folder keeps the same name as its Notion page.

In Notion, the `Folder` formula on Projects DB and Areas DB builds the link from the page's name, so nothing is filled in by hand.

## Install (once per Windows PC, no admin rights)

Press Win+R, paste, Enter:

```
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://gabrielbusch08.github.io/open-folder/install.ps1 | iex"
```

It builds `open-folder.exe` in `%LOCALAPPDATA%\open-folder` with Windows' own C# compiler and registers `openfolder:` links for this user. Run it again to update. The first click in Firefox asks which app to use: pick open-folder and tick "Always".

If the Drive sits somewhere unusual, put its `My Drive` path in `%LOCALAPPDATA%\open-folder\drive.txt`.

Uninstall: delete the registry key `HKEY_CURRENT_USER\Software\Classes\openfolder` and the folder `%LOCALAPPDATA%\open-folder`.

## Quiet tab

Like open-todoist: after "close this tab by itself from now on" is clicked once (kept per browser), the page is a blank dark tab that hands off after 0.1 s and closes itself.
