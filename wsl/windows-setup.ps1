$personalize = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
Set-ItemProperty $personalize -Name AppsUseLightTheme -Value 1
Set-ItemProperty $personalize -Name SystemUsesLightTheme -Value 1
Set-ItemProperty $personalize -Name ColorPrevalence -Value 0

$wallpaper = Join-Path $env:USERPROFILE 'Pictures\wallpaper-white.png'
Copy-Item (Join-Path $PSScriptRoot '..\assets\wallpaper-white.png') $wallpaper -Force
Add-Type -TypeDefinition 'using System.Runtime.InteropServices; public class W { [DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern int SystemParametersInfo(int a, int b, string c, int d); }'
[W]::SystemParametersInfo(20, 0, $wallpaper, 3) | Out-Null


Write-Host 'Light mode + white wallpaper applied. Next: accent color gray (Settings > Personalization > Colors) and install JetBrainsMono Nerd Font from nerdfonts.com.'
