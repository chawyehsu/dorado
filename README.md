<div align="center">
    <h1 align="center">🐟 dorado</h1>
    <p align="center">
        <a href="https://ci.appveyor.com/project/h404bi/dorado/branch/master"><img src="https://img.shields.io/appveyor/ci/h404bi/dorado/master.svg?style=flat-square&label=AppVeyor&logo=appveyor" alt="AppVeyor Build Status"></a>
        <a href="https://github.com/h404bi/dorado/blob/master/LICENSE"><img src="https://img.shields.io/github/license/h404bi/dorado.svg?style=flat-square" alt="License"></a>
        <a href="https://github.com/h404bi/dorado"><img src="https://img.shields.io/github/repo-size/h404bi/dorado.svg?style=flat-square" alt="Repo size"></a>
        <a href="https://github.com/h404bi/awesome-scoop/blob/master/README.md" title="Awesome Scoop"><img src="https://awesome.re/mentioned-badge.svg" alt="Mentioned in Awesome Scoop"></a>
    </p>
    <p align="center"><img align="center" src="https://www.h404bi.com/uploads/2018/05/20180512002.gif" alt="highlight" /></p>
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
| hmcl.json | The most famous Minecraft launcher made in China |
| nuwen-mingw-gcc.json | Minimalist GCC package from nuwen's [MinGW Distro](https://nuwen.net/mingw.html) | 
| nvm-windows.json | A fork of [nvm-windows](https://github.com/coreybutler/nvm-windows), removed elevated permission, for low permission scoop user |
| tcping.json | Eli Fulkerson's TCP ping tool, ping over a tcp connection |
| trash.json | Move files and folders to recycle bin instead of directly `rm-rf` it, like `brew install trash` but for Windows |
| yarn.json | The `non-portable` version of the Yarn application. Keep global node_modules in its original location: `$env:LOCALAPPDATA\\Yarn\\bin` |

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
