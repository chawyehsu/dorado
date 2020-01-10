<div align="center">
    <h1 align="center">🐟 dorado</h1>
    <p align="center">
        <a href="https://ci.appveyor.com/project/h404bi/dorado/branch/master"><img src="https://img.shields.io/appveyor/ci/h404bi/dorado/master.svg?style=flat-square&label=AppVeyor&logo=appveyor" alt="AppVeyor Build Status"></a>
        <a href="https://github.com/h404bi/dorado/blob/master/LICENSE"><img src="https://img.shields.io/github/license/h404bi/dorado.svg?style=flat-square" alt="License"></a>
        <a href="https://www.microsoft.com/en-us/windows"><img src="https://img.shields.io/badge/Target-Windows%2010-0067B8.svg?style=flat-square" alt="Powered by Saber" /></a>
        <a href="https://github.com/h404bi/dorado"><img src="https://img.shields.io/github/repo-size/h404bi/dorado.svg?style=flat-square" alt="Repo size"></a>
        <a href="https://github.com/h404bi/awesome-scoop/blob/master/README.md" title="Awesome Scoop"><img src="https://awesome.re/mentioned-badge-flat.svg" alt="Mentioned in Awesome Scoop"></a>
    </p>
    <p align="center">
        <a href="README.md">English</a>|<a href="README_CN.md">简体中文</a>
    </p>
    <p align="center"><img align="center" src="screenshot.gif" alt="highlight" /></p>
    <p align="center">
        Yet another <a href="https://github.com/lukesampson/scoop/wiki/Buckets"><code>bucket</code></a> for <a href="https://github.com/lukesampson/scoop">Scoop</a>.
    </p>
    <p align="center">
        All apps in this repository should <strong>NOT</strong> require elevated privileges while installation.
    </p>
</div>

Feature Apps
------------

| Manifest | Description |
|----------|-------------|
| hmcl | The most famous Minecraft launcher made in China |
| miniconda3 | A `lazy & clean` version of Miniconda3, which will not add the default root env into your PATH unless you activate it |
| nuwen-mingw-gcc | **Minimalist** GCC package from nuwen's [MinGW Distro](https://nuwen.net/mingw.html). Use `nuwen-mingw-without-git` instead if you want Boost/PCRE/zlib... libraries. |
| nvm-windows | A fork of [nvm-windows](https://github.com/coreybutler/nvm-windows), removed elevated permission, for non-admin scoop user |
| tcping | Eli Fulkerson's TCP ping tool, ping over a tcp connection |
| trash | Move files and folders to recycle bin instead of directly `rm-rf` it, like `brew install trash` but for Windows |
| rustup-np | The `non-portable` version of Rustup. Keeping .rustup and .cargo in its original location: `$env:USERPROFILE` |
| yarn-np | The `non-portable` version of the Yarn application. Keeping global node_modules in its original location: `$env:LOCALAPPDATA\\Yarn\\bin` |

Question
--------

**1. How to install the apps from this bucket?**

Run below command in PowerShell to add the bucket:

``` powershell
scoop bucket add dorado https://github.com/h404bi/dorado
```

Install apps from this bucket with below command:

``` powershell
scoop install dorado/<app_name>
```

**2. I want some other apps!**

Please open new app request [issue](https://github.com/h404bi/dorado/issues). :)

**3. Some apps are outdated, please update it!**

Be a contributor, man! Fork it, update the outdated apps app manifest, and file pull-request. :D
