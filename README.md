<div align="center">
    <h1 align="center">🐟 dorado</h1>
    <p align="center">
        <a href="https://github.com/chawyehsu/dorado/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/chawyehsu/dorado/ci.yml?style=flat-square&logo=github&label=Tests" alt="GitHub Actions CI Status"></a>
        <a href="https://github.com/chawyehsu/dorado/blob/master/UNLICENSE"><img src="https://img.shields.io/github/license/chawyehsu/dorado.svg?style=flat-square" alt="License"></a>
        <a href="https://www.microsoft.com/en-us/windows"><img src="https://img.shields.io/badge/Target-Windows%2010-0067B8.svg?style=flat-square" alt="Powered by Saber" /></a>
        <a href="https://github.com/chawyehsu/dorado"><img src="https://img.shields.io/github/repo-size/chawyehsu/dorado.svg?style=flat-square" alt="Repo size"></a>
        <a href="https://t.me/scoop_rs" title="Telegram Group"><img src="https://img.shields.io/badge/Telegram-Group-0067B8.svg?style=flat-square&logo=telegram&color=0088cc&labelColor=282c34&longCache=true" alt="Telegram Group"></a>
        <a href="https://github.com/scoopinstaller/awesome/blob/master/README.md" title="Awesome Scoop"><img src="https://awesome.re/mentioned-badge-flat.svg" alt="Mentioned in Awesome Scoop"></a>
    </p>
    <p align="center">
        <a href="README.md">English</a>|<a href="README.zh-Hans.md">简体中文</a>
    </p>
    <p align="center"><img align="center" src="https://user-images.githubusercontent.com/5764917/100413251-da9d0400-30b1-11eb-9bf8-3a97713e7730.gif" alt="highlight" /></p>
    <p align="center">
        Yet another <a href="https://github.com/lukesampson/scoop/wiki/Buckets"><code>bucket</code></a> for <a href="https://github.com/lukesampson/scoop">Scoop</a>.
    </p>
    <p align="center">
        <strong>None</strong> of the apps in this repository require elevated (administrator) privileges to install.
    </p>
</div>

## Featured Apps

| Manifest                | Description                                                                                                                                            |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| llvm-mingw              | LLVM/Clang/LLD based **mingw-w64** toolchain.                                                                                                          |
| miniconda3              | Miniconda3 variant which dose not add the default venv into your PATH unless you activate it with `conda activate base`                                |
| nuwen-mingw-gcc         | **Minimalist** GCC compiler from STL's [MinGW Distro]. It's **NOT** a full toolchain. No make, gdb, just the _gcc_ and _ld_ for quick-start scenarios. |
| nvm-windows             | A [nvm-windows] fork that removes elevated permission, for non-admin Scoop users                                                                       |
| trash                   | Safely move files and folders to recycle bin instead of using `rm -rf`                                                                                 |
| rustup-np               | `non-portable` variant of Rustup that keeps `.rustup` and `.cargo` in their original location: `$env:USERPROFILE`                                      |
| volta                   | You don't need nvm-windows anymore                                                                                                                     |
| winlibs-mingw-msvcrt    | A full **mingw-w64** toolchain with MSVCRT runtime built and distributed by [winlibs].                                                                 |
| winlibs-mingw-ucrt      | A full **mingw-w64** toolchain with UCRT runtime built and distributed by [winlibs].                                                                   |
| winlibs-mingw-llvm-ucrt | _winlibs-mingw-ucrt_ with LLVM support                                                                                                                 |

## Question

**1. How to install the apps from this bucket?**

Run below command in PowerShell to add the bucket:

```powershell
scoop bucket add dorado https://github.com/chawyehsu/dorado
```

Install apps from this bucket with below command:

```powershell
scoop install dorado/<app_name>
```

**2. I want some other apps!**

Please open new app request [issue]. :)

Please consider submitting your new app pull requests to the official buckets if
they satisfy the criteria before opening new app request in my bucket.

**3. Some apps are outdated, please update it!**

Be a contributor! Fork it, update the outdated apps app manifest, and file pull-request. :D

**4. What does the bucket name "dorado" mean?**

[Dorado (Mahi-Mahi)]

[MinGW Distro]: https://nuwen.net/mingw.html
[nvm-windows]: https://github.com/chawyehsu/nvm-windows
[winlibs]: https://winlibs.com/
[issue]: https://github.com/chawyehsu/dorado/issues
[Dorado (Mahi-Mahi)]: https://en.wikipedia.org/wiki/Mahi-mahi
