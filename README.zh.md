[English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · **中文** · [हिन्दी](README.hi.md)

# Chordex 80

为 [monome norns](https://monome.org/docs/norns/) 设计的 80 年代复音合成器和弦乐器。按一个键即可奏出和弦（按住的最低键决定根音），由一个带有三种模型的复音引擎发声，这三种模型的灵感来自那个年代的经典机器；同时屏幕上会画出一幅 outrun 风格的日落。

![Chordex 80](docs/sheet.png)

**画面就是合成器：**

- **太阳：** 大小代表滤波器（E1），光晕代表共振，条纹代表失真，抖动代表 wobble，两侧的虚影代表合唱（fatness），亮度则是随你的演奏而呼吸的包络
- **星星**代表 shimmer，**火花**代表噼啪声（同时按住两个以上的键时）
- **网格**随琶音速度前进；每个音符都是道路上的一盏灯

## 功能

- **3 个模型**：D-50、CS80 和 OMNI（灵感来自 Roland D-50、Yamaha CS-80 和 ARP Omni），D-50 可选择起音方式（气声、拨弦、无）
- **10 种和弦**：maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **琶音器**：up, down, up-down, up x2, down x2, random 和 *arpa*（竖琴）；门限从极短到真正的连奏（一个永不中断的声部）
- **和弦模式** 开/关（关 = 单音）以及**保持**
- 同时按住两个以上的键时，会出现老唱片的噼啪声
- 外部 MIDI 时钟只用于设定琶音速度，绝不会触发音符；按节拍重复同一个音也不会重新触发和弦
- 退出时自动保存全部设置，下次加载时完全恢复

与 [Chordex FM](https://github.com/buenosairesfront/chordexfm) 同属 Chordex 系列。

## 需求

- norns（shield、标准版或 fates）
- MIDI 键盘或控制器

## 安装

在 maiden 中输入：

```
;install https://github.com/buenosairesfront/chordex80
```

然后**重启 norns**（SYSTEM > RESTART）以编译新引擎 `Chordex80`，再从 SELECT 加载 **chordex80**。

## 操作

| 操作 | 功能 |
|---|---|
| E1 | 滤波器 |
| E2 | 选择参数 |
| E3 | 调节参数 |
| K3 + E1 | 模型：D-50 / CS80 / OMNI |
| K3 + E2 | 共振 |
| K3 + E3 | 和弦类型 |
| 按住 K3（不转动旋钮） | 和弦模式 开/关 |
| K2（轻按） | 琶音器 开/关 |
| K2 + E1 | 琶音门限（最大 = 连奏） |
| K2 + E2 | 琶音型 |
| K2 + E3 | 琶音速度 |
| 按住 K1 | 保持 开/关（推子左侧的实心点 = 保持中） |

**推子：** 起音、衰减、失真、shimmer、wobble、fatness。

**PARAMETERS 菜单：** MIDI 通道（0 = 全部，默认）、MIDI 时钟分频、D-50 起音、大厅混响、音量，以及以上所有参数。

## 图库

| | |
|---|---|
| ![D-50](docs/1_d50.png) D-50 · Cmaj7 | ![CS80](docs/2_cs80.png) CS80 · Am，滤波器全开 |
| ![OMNI](docs/3_omni.png) OMNI · Dsus2，滤波器关闭 | ![琶音](docs/4_arp.png) 琶音 · Em7 |

## 致谢

由 [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA 制作。
模型名称指的是启发它们的乐器；本项目与 Roland、Yamaha 或 ARP 无关。MIT 许可证。
