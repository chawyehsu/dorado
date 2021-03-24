<div align="center">
    <h1 align="center">🐟 dorado</h1>
    <p align="center">
        <a href="https://ci.appveyor.com/project/chawyehsu/dorado/branch/master"><img src="https://img.shields.io/appveyor/ci/chawyehsu/dorado/master.svg?style=flat-square&label=AppVeyor&logo=appveyor" alt="AppVeyor Build Status"></a>
        <a href="https://github.com/chawyehsu/dorado/blob/master/LICENSE"><img src="https://img.shields.io/github/license/chawyehsu/dorado.svg?style=flat-square" alt="License"></a>
        <a href="https://www.microsoft.com/en-us/windows"><img src="https://img.shields.io/badge/Target-Windows%2010-0067B8.svg?style=flat-square" alt="Powered by Saber" /></a>
        <a href="https://github.com/chawyehsu/dorado"><img src="https://img.shields.io/github/repo-size/chawyehsu/dorado.svg?style=flat-square" alt="Repo size"></a>
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
        All apps in this repository should <strong>NOT</strong> require elevated privileges while installation.
    </p>
</div>

Featured Apps
------------

| Manifest | Description |
|----------|-------------|
| llvm-mingw | [The](https://github.com/mstorsjo/llvm-mingw) LLVM/Clang/LLD based **mingw-w64** toolchain. (LLVM 11) |
| miniconda3 | A version of Miniconda3 that dose not add the default venv into your PATH unless you activate it with `conda activate base` |
| nuwen-mingw-gcc | **Minimalist** C/C++ compiler from STL's [MinGW Distro](https://nuwen.net/mingw.html). It's **NOT** a full **mingw-w64** package, has no make, no gdb. Just the *gcc* and *ld* for 'quick-start' use case. (GCC 9.2) |
| nvm-windows | A fork of [nvm-windows](https://github.com/chawyehsu/nvm-windows), removed elevated permission, for non-admin scoop user |
| trash | Move files and folders to recycle bin instead of directly `rm-rf` it, like `brew install trash` but for Windows |
| rustup-np | The `non-portable` version of Rustup, keeping .rustup and .cargo in its original location: `$env:USERPROFILE` |
| volta | You don't need nvm-windows anymore |
| winlibs-mingw | A full **mingw-w64** toolchain built and distributed by [winlibs](http://winlibs.com/). (GCC 10.2) |
| winlibs-mingw-llvm | A LLVM integrated version of winlibs-mingw. (GCC 10.2 + LLVM 11) |
| winlibs-mingw-snapshot | A snapshot version of winlibs-mingw. (GCC 11 snapshot) |

Question
--------

**1. How to install the apps from this bucket?**

Run below command in PowerShell to add the bucket:

``` powershell
scoop bucket add dorado https://github.com/chawyehsu/dorado
```

Install apps from this bucket with below command:

``` powershell
scoop install dorado/<app_name>
```

**2. I want some other apps!**

Please open new app request [issue](https://github.com/chawyehsu/dorado/issues). :)

**3. Some apps are outdated, please update it!**

Be a contributor! Fork it, update the outdated apps app manifest, and file pull-request. :D
