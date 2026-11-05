// open-folder: opens a Google Drive folder in Windows Explorer from an
// "openfolder:<folder name>" link. install.ps1 compiles this file into
// open-folder.exe and registers it for openfolder: links (this user only).
//
// The link carries a folder NAME, not a path, so it keeps working when a
// project folder moves between stages (Ideas, Backlog, ACTIVE, Archive).
// The name is only compared with folder names found in the Drive; it is
// never used to build a path, and the program only ever opens folders.
//
// Written for C# 5: Windows PowerShell 5.1 compiles it with .NET Framework.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

static class OpenFolder
{
    const string Title = "Open folder";
    // Searched in this order; the first folder whose name matches wins,
    // shallower before deeper (Areas, then projects in their stage folders).
    static readonly string[] SearchRoots = { "02 AREAS", "01 PROJECTS" };
    const int MaxDepth = 3;

    [DllImport("user32.dll")]
    static extern bool AllowSetForegroundWindow(int processId);

    [STAThread]
    static int Main(string[] args)
    {
        string name = args.Length > 0 ? NameFromLink(args[0]) : "";
        string drive = FindDriveRoot();
        if (drive == null)
        {
            Show("Couldn't find your Google Drive folder (My Drive or Meu Drive).\n\n" +
                 "Is Google Drive for desktop running? If your Drive is somewhere else, put its path in\n" +
                 Path.Combine(AppFolder(), "drive.txt"));
            return 1;
        }
        string key = Key(name);
        if (key.Length == 0)
        {
            Open(drive);
            return 0;
        }
        string found = Find(drive, key);
        if (found != null)
        {
            Open(found);
            return 0;
        }
        string fallback = Path.Combine(drive, "01 PROJECTS");
        if (!Directory.Exists(fallback)) fallback = drive;
        Open(fallback);
        Show("No folder named \"" + name + "\" in your Drive's 02 AREAS or 01 PROJECTS.\n\n" +
             "The Drive folder needs the same name as the Notion page. Opened " + fallback + " instead.");
        return 1;
    }

    // "openfolder:Notion%20Setup" or "openfolder://Notion%20Setup/" -> "Notion Setup"
    static string NameFromLink(string link)
    {
        string s = link;
        const string scheme = "openfolder:";
        if (s.StartsWith(scheme, StringComparison.OrdinalIgnoreCase)) s = s.Substring(scheme.Length);
        s = s.Trim('/');
        try { s = Uri.UnescapeDataString(s); } catch (Exception) { }
        return s.Trim();
    }

    // Compare names loosely: no case, accents, spaces, punctuation or emoji,
    // so "Compras / Aquisições" in Notion matches "Compras _ Aquisicoes" in Drive.
    static string Key(string name)
    {
        string d = (name ?? "").Normalize(NormalizationForm.FormD);
        StringBuilder sb = new StringBuilder();
        foreach (char c in d)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) == UnicodeCategory.NonSpacingMark) continue;
            if (char.IsLetterOrDigit(c)) sb.Append(char.ToLowerInvariant(c));
        }
        return sb.ToString();
    }

    static string AppFolder()
    {
        return Path.GetDirectoryName(Application.ExecutablePath);
    }

    // The Drive's "My Drive" folder: from drive.txt if present, else the first
    // My Drive / Meu Drive found, preferring one that holds "02 AREAS"
    // (there may be one per Google account).
    static string FindDriveRoot()
    {
        try
        {
            string txt = Path.Combine(AppFolder(), "drive.txt");
            if (File.Exists(txt))
            {
                string p = File.ReadAllText(txt).Trim().Trim('"');
                if (Directory.Exists(p)) return p;
            }
        }
        catch (Exception) { }

        List<string> bases = new List<string>();
        string profile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        bases.Add(profile);
        bases.Add(Path.Combine(profile, "Google Drive"));
        foreach (DriveInfo d in DriveInfo.GetDrives())
        {
            try
            {
                if (d.DriveType == DriveType.Network || !d.IsReady) continue;
                bases.Add(d.RootDirectory.FullName);
            }
            catch (Exception) { }
        }

        string first = null;
        foreach (string b in bases)
        {
            foreach (string n in new string[] { "My Drive", "Meu Drive" })
            {
                string p = Path.Combine(b, n);
                try
                {
                    if (!Directory.Exists(p)) continue;
                    if (Directory.Exists(Path.Combine(p, "02 AREAS"))) return p;
                    if (first == null) first = p;
                }
                catch (Exception) { }
            }
        }
        return first;
    }

    // Breadth-first, so a shallow match beats a deeper folder with the same name.
    static string Find(string drive, string key)
    {
        List<string> level = new List<string>();
        foreach (string r in SearchRoots)
        {
            string p = Path.Combine(drive, r);
            if (Directory.Exists(p)) level.Add(p);
        }
        for (int depth = 1; depth <= MaxDepth && level.Count > 0; depth++)
        {
            List<string> next = new List<string>();
            foreach (string dir in level)
            {
                string[] subs;
                try { subs = Directory.GetDirectories(dir); }
                catch (Exception) { continue; }
                Array.Sort(subs, StringComparer.OrdinalIgnoreCase);
                foreach (string sub in subs)
                {
                    if (Key(Path.GetFileName(sub)) == key) return sub;
                    next.Add(sub);
                }
            }
            level = next;
        }
        return null;
    }

    static void Open(string folder)
    {
        // Let the Explorer window come to the front instead of opening behind Firefox.
        AllowSetForegroundWindow(-1);
        ProcessStartInfo psi = new ProcessStartInfo("explorer.exe", "\"" + folder + "\"");
        psi.UseShellExecute = false;
        Process.Start(psi);
    }

    static void Show(string message)
    {
        MessageBox.Show(message, Title, MessageBoxButtons.OK, MessageBoxIcon.Information);
    }
}
