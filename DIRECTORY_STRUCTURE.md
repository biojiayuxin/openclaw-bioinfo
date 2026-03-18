# OpenClaw生信分析环境 - 目录结构

## 宿主机目录结构

```
/mnt/data_1/yuxin.jia/openclaw_test_configs/
├── config/.openclaw/          # OpenClaw核心配置
│   └── openclaw.json          # 主配置文件
├── workspace/                 # OpenClaw设定文件
│   ├── IDENTITY.md            # 身份设定
│   ├── USER.md                # 用户信息
│   ├── SOUL.md                # 行为准则
│   ├── AGENTS.md              # 工作方式（含目录说明）
│   └── memory/                # 记忆存储（自动创建）
├── skills/                    # 自定义技能
├── micromamba_envs/             # 用户自建conda环境
├── micromamba_pkgs/           # conda包缓存
├── micromamba_etc/            # micromamba配置
├── data/                      # 原始数据（只读挂载）
└── work/                      # 实际工作目录
```

## 容器内映射

| 宿主机目录 | 容器内路径 | 用途 |
|-----------|-----------|------|
| config/.openclaw | /root/.openclaw | OpenClaw配置、会话、记忆 |
| workspace | /root/.openclaw/workspace | 设定文件(IDENTITY.md等) |
| skills | /skills | 自定义技能 |
| micromamba_envs | /root/micromamba/envs | 用户自建conda环境 |
| micromamba_pkgs | /root/micromamba/pkgs | conda包缓存 |
| micromamba_etc | /root/micromamba/etc | micromamba配置 |
| data | /data | 原始数据（只读） |
| work | /work | 实际工作目录 |

## 镜像内置（无需挂载）

| 容器内路径 | 内容 |
|-----------|------|
| /opt/bioenvs/rna | 预装RNA分析环境 |
| /usr/local/bin/micromamba | micromamba可执行文件 |

## Singularity运行示例

```bash
# 注意：必须使用 --no-home 防止挂载宿主机的 ~/.openclaw
singularity run \
    --no-home \
    --bind /path/to/config/.openclaw:/root/.openclaw \
    --bind /path/to/workspace:/root/.openclaw/workspace \
    --bind /path/to/skills:/skills \
    --bind /path/to/micromamba_envs:/root/micromamba/envs \
    --bind /path/to/micromamba_pkgs:/root/micromamba/pkgs \
    --bind /path/to/micromamba_etc:/root/micromamba/etc \
    --bind /path/to/data:/data:ro \
    --bind /path/to/work:/work \
    openclaw-bioinfo.sif
```
