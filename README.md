# EVE-Config-Shell  
**一个用于下载和配置 EVE-NG 的脚本  
A script for downloading and configuring EVE-NG**

---

## 📝 说明 | Description

**中文：**  
本项目及其源代码遵循 **GPLv3 开源许可协议**：

- 允许修改与分发，但必须保留原项目的版权与许可声明，禁止未经授权的商业使用；  
- 修改后的项目必须继续使用相同的开源协议，并需保留原作者署名与来源；  
- 本项目仅用于学习与研究，作者不对使用本项目造成的任何直接或间接后果负责；  
- **生产环境用户及 EVE-NG Pro 用户必须在部署前进行充分的审计、测试与评估。**

本脚本使用 **hi168 / Microsoft SharePoint** 作为配置文件与镜像存储源。  
本项目为面向 ChatGPT 辅助开发而创建，**石山勿Q**。

项目地址：  
👉 https://github.com/ChengCingSyuan/EVE-Config-Shell

---

**English:**  
This project and its source code are licensed under the **GPLv3 license**:

- Modification and redistribution are permitted, but the original copyright and license statements must be preserved.  
- Unauthorized commercial use is prohibited.  
- Modified versions must continue to use the same open-source license and retain proper attribution.  
- **Production environment users and EVE-NG Pro users must conduct thorough auditing, testing, and evaluation before deployment.**

This script uses **hi168 / Microsoft SharePoint** as the storage source for configuration files and images.  
This project is developed with assistance from ChatGPT — **Don’t ask**.

Project repository:  
👉 https://github.com/ChengCingSyuan/EVE-Config-Shell

---

## ✨ 功能 | Features

**中文：**

1. 切换下载源（支持 hi168 与 Microsoft SharePoint）  
2. 安装 / 更新 EVE-NG 配置文件（scripts、icons、YAML 模板等）  
3. 一键修复权限  
4. 安装锐捷设备镜像  
5. 切换 APT 源并安装必要系统组件  

**未来计划：**

- 支持更多厂商设备  

---

**English:**

1. Switch between download sources (supports hi168 and Microsoft SharePoint)  
2. Install/Update EVE-NG configuration files (scripts, icons, YAML templates, etc.)  
3. One-click permission repair  
4. Install Ruijie device images  
5. Switch APT sources and install required system components  

**Future Plans:**

- Support for more vendor device images  

---

## 设备列表 (Supported Devices)

### Ruijie
- **RuijieFirewall-V1.03**  
- **RuijieRoute-V1.06**  
- **RuijieSwitch-V1.06**  

### H3C
- **H3C VFW1K — 7.1.064-E1260P45**  
- **H3C VSR1K — 7.1.064-R1340P22**  
- **H3C Switch S9850 — 7.1.070-R7643P02**  
