# TimeSetor - 不常规时间管理系统

一个创新的时间管理软件，通过调整时间流速来帮助用户建立规律的作息习惯。

## 功能特点

- **不常规时间显示**: 显示与真实时间不同的虚拟时间，流速可变
- **智能时间流速**: 根据用户活动自动调整时间流速
  - 娱乐时：时间加速流逝（可配置倍速）
  - 学习时：时间曲线变速（开始快，逐渐变慢）

  - 休息时：时间减速流逝
- **番茄钟功能**: 集成番茄钟，使用虚拟时间计时
- **AI智能总结**: 自动生成日/周/月/年总结
- **多客户端同步**: 支持多个设备同时使用

## 项目结构

```
timesetor/
├── server/                 # Python服务端
├── web/                    # Vue Web客户端
└── android/                # Flutter安卓客户端
```

## 快速开始

### 服务端部署

1. 确保已安装 Python 3.8+
2. 双击运行 `server/start.bat`（Windows）
3. 服务默认运行在 `http://localhost:5000`

### Web客户端

```bash
cd web
npm install
npm run dev
```

### 安卓客户端

从GitHub Releases下载APK安装

## License

MIT License