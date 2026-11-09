# One-command Windows setup

`setup-dkb.ps1` runs the existing Bananza installer CLI with the local ExeFS, RomFS, tool package and destination. The full lift, compile, shader translation, pipeline warm-up and self-test stay on the player's PC. Game files and generated game data must never be uploaded to GitHub Actions or committed to the fork.

## Build the tools package

In the fork on GitHub, open **Actions**, select **DKB setup zip**, choose **Run workflow**, and download the `DKB-Setup-windows` artifact after the run succeeds. Extract the zip somewhere outside the game dump. The workflow builds the installer and tool package only; it does not build the user's game.

## Run the local setup

From PowerShell in the fork checkout:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
./setup-dkb.ps1 `
  -Exefs 'D:\Bananza\base\exefs' `
  -Romfs 'D:\Bananza\base\romfs' `
  -Destination 'D:\Recomps\DKB-Recomp' `
  -ToolsPackage 'D:\Downloads\DKB-Setup-0.2.0-windows\DKB-Setup' `
  -Language 'pt-BR' `
  -Jobs 6
```

For a packed RomFS, provide the folder containing both `romfs.bin` and `index.json`. For a loose RomFS, provide its root folder. `-Verify` asks the installer to hash every kept output file after setup. The installer resumes completed steps when rerun with the same arguments.

The script validates required inputs and tool files, then delegates to the project's installer. It does not delete the dump, profile or saves. Use an empty destination or an existing Bananza installation owned by the installer.

## Notes

- Windows PowerShell 5.1 or later is supported; execution-policy change is scoped to the current PowerShell process.
- Use a base 1.0.0 dump. The workflow does not need game files, keys or a console account.
- Allow roughly 60 GB of working space, as described in [building.md](building.md).
- Shader translation failures stop the install. Driver pipeline warm-up can fail on some NVIDIA driver versions; in that case the installer warns, keeps the build and records that pipeline libraries were not prepared.
