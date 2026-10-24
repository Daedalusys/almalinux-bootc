# Daedalus 面向的构建入口。上游 Makefile 仍是构建动作的单一事实源,
# 这里只做 facade —— 详见 docs/REBASE.md 关于 Makefile 冲突的约定。
#
# 本 fork 只保留 10-kitten 变体;镜像的发布 tag 约定见 docs/REGISTRY.md。

# 被探测的镜像。三种覆盖方式等价:
#   IMAGE=<ref> just verify-headless        # 环境变量(CI 用这个)
#   just --set IMG <ref> verify-headless    # just 变量
#   just IMG=<ref> verify-headless          # just 变量,须写在 recipe 名之前
# 默认指向本 fork 实际发布的 tag,不是 :latest —— :latest 在本仓不存在。
IMG := env_var_or_default("IMAGE", "ghcr.io/daedalusys/almalinux-bootc:10-kitten")

# 本地造镜像。Makefile 用的是 `sudo podman`,镜像落在 root 的存储里,
# 验证刚造出来的镜像要用同一个 podman。
build:
    make image

# manifest 静态扫描:不需要容器,任何机器都能跑,任何时候都是门。
verify-headless-manifest:
    ./tests/no-gui.sh

# headless 静态保证(T2/T3 在 CI 里也走这个入口,保证本地与 CI 同一套判定)。
verify-headless:
    IMAGE={{ IMG }} ./tests/no-gui.sh
    IMAGE={{ IMG }} ./tests/rescue-path.sh

# live 段:要能起完整 systemd 的环境,本地/CI 都不能默认跑。
verify-headless-live:
    IMAGE={{ IMG }} RESCUE_LIVE=1 ./tests/rescue-path.sh
