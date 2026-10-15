# MOMA Patrol System

[中文](README.zh-CN.md) | [English](README.md)

广州机车巡检系统工作空间。

本仓库只将各功能包作为 Git submodule 纳入管理。

所有使用但**不会修改**的第三方软件包（例如硬件驱动）应放置在 `3rd/` 目录下。

建议将本仓库放置在 ROS 工作空间的 `src/` 目录中：

```bash
git clone --recurse-submodules git@github.com:yangzhaofeng496/moma-patrol-system.git <your_workspace_dir>/src
```

> [!TIP]
> 如果克隆时没有使用 `--recurse-submodules`，可以执行：
>
> ```bash
> git pull
> git submodule update --init --recursive
> ```
>
> 或者：
>
> ```bash
> git pull --recurse-submodules
> ```

## Git 命令说明

以下命令默认在当前本地仓库的根目录执行。

以 `battery` 为例，其仓库地址为：
`https://github.com/Lucid-A/lebang_battery_driver.git`。

> [!IMPORTANT]
> 编写提交信息时，请遵循
> [Conventional Commits 规范](https://www.conventionalcommits.org/en/v1.0.0/)。
> 如有需要，可以使用 LLM 帮助将提交信息修改为规范格式。

> [!IMPORTANT]
> 提交后请使用 `git push` 将提交推送到远程仓库。
> 建议在推送前先执行 `pull`，并及时解决可能出现的冲突。

### 添加 Submodule

```bash
git submodule add https://github.com/Lucid-A/lebang_battery_driver.git battery
git add battery .gitmodules
git commit -m "chore(battery): add battery driver submodule"
```

> [!TIP]
> 虽然远程仓库名称是 `lebang_battery_driver`，但可以在本工作空间中将它命名为 `battery`。

### 移动 Submodule

```bash
git mv battery 3rd/battery
git add 3rd/battery .gitmodules
git commit -m "chore(battery): move battery to 3rd/battery"
```

### 更新 Submodule 到指定版本

```bash
git -C 3rd/battery fetch
git -C 3rd/battery checkout <commit-hash>
git add 3rd/battery
git commit -m "chore(battery): update battery to <short-hash>"
```

> [!NOTE]
> 此时不需要再次执行 `git add .gitmodules`。

> [!TIP]
> 可以使用 `git submodule update --remote` 更新到远程仓库的最新版本。

### 删除 Submodule

```bash
git submodule deinit -f 3rd/battery # 删除本地工作空间中的注册信息和文件
git rm -f 3rd/battery               # 删除父仓库中的 submodule 引用
rm -rf .git/modules/3rd/battery     # 删除已删除 submodule 的本地缓存
git commit -m "chore: remove <repo> submodule"
```

## 各功能包的 README

### 机器人厂商提供

- [电池信息发布节点](https://github.com/Lucid-A/lebang_battery_driver/blob/6e3a86be3d8b97b30107e738b974ca5d68297a82/readme.md)

### 传感器驱动

- [Livox MID360 驱动](https://github.com/Lucid-A/livox_ros_driver2/blob/Guangtie/README.md)
