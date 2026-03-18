# OpenClaw 生信分析环境 - 部署说明

## 文件清单

部署到其他服务器需要以下文件：

```
openclaw/
├── openclaw-bioinfo.sif          # SIF镜像文件 (~1.5GB)
├── run_sif.sh                    # 启动脚本
└── openclaw_test_configs/        # 配置目录
    ├── config/.openclaw/         # OpenClaw配置
    │   └── openclaw.json         # 主配置文件（需修改API Key）
    ├── workspace/                # 设定文件
    │   ├── IDENTITY.md
    │   ├── USER.md
    │   ├── SOUL.md
    │   └── AGENTS.md
    ├── skills/                   # 自定义技能
    ├── micromamba_envs/          # 用户conda环境
    ├── micromamba_pkgs/          # conda包缓存
    ├── micromamba_etc/           # micromamba配置
    ├── data/                     # 原始数据（只读）
    └── work/                     # 工作目录
```

## 目标服务器要求

### 1. 安装容器运行时

**选项A: Apptainer (推荐，较新)**
```bash
conda create -n apptainer -c conda-forge apptainer
conda activate apptainer
```

**选项B: Singularity (兼容旧版本)**
```bash
# Ubuntu/Debian
sudo apt-get install singularity-container

# CentOS/RHEL
sudo yum install singularity

# 或从源码安装
# 参考: https://sylabs.io/guides/3.0/user-guide/quick_start.html
```

### 2. 部署步骤

```bash
# 1. 创建目录
mkdir -p /path/to/openclaw
cd /path/to/openclaw

# 2. 复制文件
# 将以下文件复制到当前目录:
#   - openclaw-bioinfo.sif
#   - run_sif.sh
#   - openclaw_test_configs/ (整个目录)

# 3. 赋予执行权限
chmod +x run_sif.sh

# 4. 修改配置文件（重要！）
# 编辑 openclaw_test_configs/config/.openclaw/openclaw.json
# 修改以下内容:
#   - CUSTOM_API_KEY: 你的API密钥
#   - baseUrl: 你的API地址
#   - 模型配置等

# 5. 运行
./run_sif.sh
```

## 配置说明

### 修改API配置

编辑 `openclaw_test_configs/config/.openclaw/openclaw.json`：

```json
{
  "env": {
    "CUSTOM_API_KEY": "你的API密钥"
  },
  "models": {
    "providers": {
      "custom-provider": {
        "baseUrl": "你的API地址",
        "apiKey": "${CUSTOM_API_KEY}",
        "models": [
          {
            "id": "你的模型ID",
            "name": "模型名称"
          }
        ]
      }
    }
  }
}
```

### 目录用途

| 目录 | 用途 | 说明 |
|------|------|------|
| config/.openclaw | OpenClaw配置 | 包含配置文件和会话记录 |
| workspace | 设定文件 | IDENTITY.md等，定义AI行为 |
| skills | 自定义技能 | AI可调用的技能脚本 |
| micromamba_envs | conda环境 | 用户自建的软件环境 |
| micromamba_pkgs | 包缓存 | conda包缓存，避免重复下载 |
| data | 原始数据 | 只读挂载，保护原始数据 |
| work | 工作目录 | 实际分析和结果输出目录 |

## 使用示例

### 启动OpenClaw
```bash
./run_sif.sh
```

### 添加数据
```bash
# 将数据放入data目录
cp /path/to/your/data.fastq.gz openclaw_test_configs/data/
```

### 安装新软件
```bash
# 进入容器后
micromamba create -n my_env -c bioconda fastqc multiqc
```

## 兼容性

- **Apptainer**: 1.0+ (推荐)
- **Singularity**: 3.0+ (兼容)
- 脚本会自动检测并使用可用的容器运行时

## 常见问题

### Q: 提示"未找到 apptainer 或 singularity"
A: 请安装其中一个容器运行时，见上文安装说明

### Q: 提示"Permission denied"
A: 检查文件权限，确保当前用户对配置目录有读写权限

### Q: Gateway启动失败
A: 检查端口18789是否被占用，运行 `pkill -f gateway` 清理残留进程

### Q: 模型调用失败
A: 检查openclaw.json中的API配置是否正确
