dorado
======

[![AppVeyor Build Status](https://img.shields.io/appveyor/ci/h404bi/dorado/master.svg?style=flat-square&label=AppVeyor&logo=appveyor)](https://ci.appveyor.com/project/h404bi/dorado/branch/master)
 [![License](https://img.shields.io/github/license/h404bi/dorado.svg?style=flat-square)](LICENSE) ![Repo size](https://img.shields.io/github/repo-size/h404bi/dorado.svg?style=flat-square)

Yet another [`bucket`](https://github.com/lukesampson/scoop/wiki/Buckets) for [Scoop](https://github.com/lukesampson/scoop).

All apps in this repository should **NOT** require elevated privileges while installation.

Question
--------

**1. How to install scoop apps from this bucket?**

Run below command in PowerShell to tap the bucket:

``` powershell
scoop bucket add dorado https://github.com/h404bi/dorado
```

Install apps from this bucket with below command:

``` powershell
scoop install dorado/<app_name>
```

**2. Some apps are outdated, please update it!**

Be a contributor, man! Fork it, update the outdated apps app manifest, and fire a pull-request. :D
