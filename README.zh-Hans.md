<div align="center">
    <h1 align="center">🐟 dorado</h1>
    <p align="center">
        <a href="https://github.com/chawyehsu/dorado/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/chawyehsu/dorado/ci.yml?style=flat-square&logo=github&label=Tests" alt="GitHub Actions CI Status"></a>
        <a href="https://github.com/chawyehsu/dorado/blob/master/UNLICENSE"><img src="https://img.shields.io/github/license/chawyehsu/dorado.svg?style=flat-square" alt="License"></a>
        <a href="https://www.microsoft.com/en-us/windows"><img src="https://img.shields.io/badge/Target-Windows%2010-0067B8.svg?style=flat-square" alt="Powered by Saber" /></a>
        <a href="https://github.com/chawyehsu/dorado"><img src="https://img.shields.io/github/repo-size/chawyehsu/dorado.svg?style=flat-square" alt="Repo size"></a>
        <a href="https://github.com/scoopinstaller/awesome/blob/master/README.md" title="Awesome Scoop"><img src="https://awesome.re/mentioned-badge-flat.svg" alt="Mentioned in Awesome Scoop"></a>
    </p>
    <p align="center">
        <a href="README.md">English</a>|<a href="README.zh-Hans.md">简体中文</a>
    </p>
    <p align="center"><img align="center" src="https://user-images.githubusercontent.com/5764917/100413251-da9d0400-30b1-11eb-9bf8-3a97713e7730.gif" alt="highlight" /></p>
    <p align="center">
        又一个 <a href="https://github.com/lukesampson/scoop">Scoop</a> 的软件仓库（<a href="https://github.com/lukesampson/scoop/wiki/Buckets">bucket</a>）
    </p>
    <p align="center">
        宗旨：本仓库内的所有软件在安装时都应<strong>无需</strong>管理员权限
    </p>
</div>

## 推荐软件

| 软件                    | 简介                                                                                          |
| ----------------------- | --------------------------------------------------------------------------------------------- |
| hmcl                    | 好用的国产 Minecraft 启动器                                                                   |
| llvm-mingw              | 一个基于 LLVM/Clang/LLD 的 **mingw-w64** 工具链                                               |
| msys2-cn                | MSYS2 衍生，配置大陆镜像点自动无人值守安装                                                    |
| neteasemusic            | 网易云音乐客户端                                                                              |
| nuwen-mingw-gcc         | GCC 编译器极简包，源自 STL 的 [MinGW Distro]，只有 gcc 与 ld，最小化环境编译简单的 C/C++ 代码 |
| nvm-windows             | [nvm-windows] 修改版，移除了管理员提权要求，使得非权限普通用户亦可使用                        |
| texlive                 | 需要 Tex 环境？TexLive 大概是当下最佳解决方法                                                 |
| trash                   | 将待删除文件移至回收站，而不是直接 `rm -rf`，类似于 macOS 的 trash                            |
| volta                   | 你可能不再需要 nvm-windows                                                                    |
| winlibs-mingw-msvcrt    | [winlibs](http://winlibs.com/) 编译的完整 MSVCRT 运行库 **mingw-w64** 工具链发行版            |
| winlibs-mingw-ucrt      | [winlibs](http://winlibs.com/) 编译的完整 UCRT 运行库 **mingw-w64** 工具链发行版              |
| winlibs-mingw-llvm-ucrt | 包含 LLVM 支持的 _winlibs-mingw-ucrt_                                                         |

更多待你发现~

## 疑问

**1. 如何安装该软件仓库中的软件？**

确保你已经有 Scoop 环境，执行以下命令订阅本软件仓库：

```powershell
scoop bucket add dorado https://github.com/chawyehsu/dorado
```

执行以下命令安装本仓库中的软件：

```powershell
scoop install dorado/<软件名>
```

**2. 我想要某个软件，这个仓库里没有！**

开 [issue]，描述你的需求。:)

**3. 仓库中的某个软件版本落后了，求更新！**

欢迎 Fork 本仓库，修改落后的软件清单，并提交你的拉取请求。:D

**4. 仓库名 dorado 是什么意思？**

一种鱼：[Dorado (Mahi-Mahi)]。

[MinGW Distro]: https://nuwen.net/mingw.html
[nvm-windows]: https://github.com/chawyehsu/nvm-windows
[winlibs]: https://winlibs.com/
[issue]: https://github.com/chawyehsu/dorado/issues
[Dorado (Mahi-Mahi)]: https://en.wikipedia.org/wiki/Mahi-mahi
