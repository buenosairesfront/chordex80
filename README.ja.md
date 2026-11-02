[English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · **日本語** · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex 80

[monome norns](https://monome.org/docs/norns/) 用の、80 年代ポリシンセのコード楽器。
1 つのキーでコードを鳴らし（押さえている一番低いキーがルート）、その時代の名機にインスパイアされた 3 つのモデルを持つポリフォニック・エンジンで演奏します。画面にはアウトラン風の夕焼けが描かれます。

![Chordex 80](docs/sheet.png)

**情景そのものがシンセサイザーです：**

- **太陽：** 大きさはフィルター（E1）、光の輪はレゾナンス、縞はディストーション、揺れはウォブル、左右のゴーストはコーラス（ファットネス）、輝きは演奏に合わせて呼吸するエンベロープ
- **星**はシマー、**火花**はクラックル（3 つ以上のキーを押したとき）
- **グリッド**はアルペジオのテンポで進み、各音は道路の上の光になります

## 機能

- **3 モデル**：D-50、CS80、OMNI（Roland D-50、Yamaha CS-80、ARP Omni にインスパイア）。D-50 はアタックを選択可能（エア、プラック、なし）
- **10 種類のコード**：maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **アルペジエーター**：up, down, up-down, up x2, down x2, random, *arpa*（ハープ）。ゲートはごく短い音から本物のレガート（途切れない 1 ボイス）まで
- **コードモード** オン/オフ（オフ = 単音）と**ホールド**
- 3 つ以上のキーを押すと古いレコードのクラックルノイズ
- 受信した MIDI クロックはアルペジオのテンポにのみ使われ、ノートを鳴らすことはありません。テンポに合わせて同じ音を繰り返してもコードは再トリガーされません
- 終了時にすべて保存され、読み込むと同じ状態に戻ります

<!-- u-ma:family -->
## Chordex ファミリー

操作は同じ、エンジンは別。ほかの楽器もどうぞ：

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.ja.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.ja.md)**<br>花として描かれる 4 オペレーター FM<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.ja.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.ja.md)**<br>弓で擦った弦の実際の動きを描くオーケストラ弦楽<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexwt/blob/main/README.ja.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexwt/main/docs/2_vocal.png" width="200" alt="Chordex WT"></a> | **[Chordex WT](https://github.com/buenosairesfront/chordexwt/blob/main/README.ja.md)**<br>8 波形 × 8 バンクのウェーブテーブル。3D テーブルとして描画<br>`;install https://github.com/buenosairesfront/chordexwt` |

**U-MA のほかの作品：** すべての楽器とツールをひとつに → [U-MA ショーケース](https://github.com/buenosairesfront/U-ma/blob/main/README.ja.md)
<!-- /u-ma:family -->

## 必要なもの

- norns（shield、標準モデル、fates）
- MIDI キーボードまたはコントローラー

## インストール

maiden から：

```
;install https://github.com/buenosairesfront/chordex80
```

その後、新しいエンジン `Chordex80` をコンパイルするために **norns を再起動**（SYSTEM > RESTART）し、SELECT から **chordex80** を読み込みます。

## 操作

| 操作 | 機能 |
|---|---|
| E1 | フィルター |
| E2 | パラメーター選択 |
| E3 | パラメーター調整 |
| K3 + E1 | モデル：D-50 / CS80 / OMNI |
| K3 + E2 | レゾナンス |
| K3 + E3 | コードの種類 |
| K3 長押し（回さずに） | コードモード オン/オフ |
| K2（タップ） | アルペジエーター オン/オフ |
| K2 + E1 | アルペジオのゲート（最大 = レガート） |
| K2 + E2 | アルペジオのパターン |
| K2 + E3 | アルペジオの速度 |
| K1 長押し | ホールド オン/オフ（フェーダー左の点が塗りつぶし = ホールド中） |

**フェーダー：** アタック、ディケイ、ディストーション、シマー、ウォブル、ファットネス。

**PARAMETERS メニュー：** MIDI チャンネル（0 = 全チャンネル、初期値）、MIDI クロック分周、D-50 のアタック、ホール、音量、および上記すべて。

## ギャラリー

| | |
|---|---|
| ![D-50](docs/1_d50.png) D-50 · Cmaj7 | ![CS80](docs/2_cs80.png) CS80 · Am、フィルター全開 |
| ![OMNI](docs/3_omni.png) OMNI · Dsus2、フィルター閉 | ![アルペジオ](docs/4_arp.png) アルペジオ · Em7 |

## クレジット

制作：[Buenos Aires Front](https://github.com/buenosairesfront) / U-MA。
モデル名はインスピレーション元の楽器を指すもので、本プロジェクトは Roland、Yamaha、ARP とは関係ありません。MIT ライセンス。
