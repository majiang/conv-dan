# 段位効率計算機

## 序論
* 天鳳ユーザは段位を重視する傾向にある
* 現在段位そのものは粗い評価であり、直近の結果を反映するにすぎない
* 任意試合数の順位分布から計算可能な [段位効率](http://tenhou.net/man/#RANKING) が注目されている
* 一般に少数の結果から算出された結果は偶然によって大きくばらつくので「たまたま結果がよかっただけ」と評価されないような指標が必要とされる
* とつげき東北により提案されている [保証安定R](http://totutohoku.b23.coreserver.jp/hp/SLtotu14.htm) は、平均順位に関してこのような性質をもつ
* 本研究は段位効率の挙動を明らかにし、新たな指標「保証収束段位」を提供することを目標とする

## 定義
* 収束段位: 真の順位分布に基づく、平均獲得ポイントが0となる段位 (段位は離散的だが1次関数で補間・補外)
* 段位効率: 有限試合の結果順位分布に基づく、平均獲得ポイントが0となる段位
* トップラス比: 真のトップ率 / 真のラス率

## 仮定
* 本来、本研究の意味でプレイヤーを特定するには順位分布 (自由度3) を指定する必要がある
    * 一般に、自由度の大きいパラメータを適切に設定することは難しい
* 簡単のため、プレイヤーの実力には一意な順序が入るとしたい
* 自由度1の指標「トップラス比」を導入し、順位分布はこれに従属するとする
    * トップラス比は0より大きいとする (真のラス率は0ではないとする)
    * 具体的には、プレイヤーの順位獲得確率は等差数列とする
        * トップラス比 = r のとき、1位から順に順位獲得確率は 3r/6(1+r), (1+2r)/6(1+r), (2+r)/6(1+r), 3/6(1+r) とする

## 無作為成績の保証収束段位
* 本節はプレイ前に指定された異なるゲーム数の段位効率を比較するにあたり確率α (たとえば α = 5%) の幸運を仮定した比較を行う方法の提供を目的とする
* プレイ後に指定ゲーム数を抜き出した成績の比較は今後の課題とする (次節に追記する予定である)

### 基礎実験
* 本項はプレイヤー (トップラス比によって指定) と試合数を入力とし段位効率分布を返す一般的なシミュレーションの手順を記述する

0. トップラス比から順位分布を生成する (収束段位が決まる)
0. 試合数とシミュレーション回数を指定し、前項の順位分布に基づいたシミュレーションを行う
0. シミュレーション結果 (段位効率の分布) を観察する
    * 特に、上位α段位効率 (たとえば α = 5%) に注目する

### 実験
* 本項は、前項の実験に基づく、保証収束段位を求めるための探索について記述する
* 基本的なアイディアは二分探索であるが、シミュレーション結果の誤差を探索終了の条件に組み込む

0. 評価するべき段位効率 `e` と試合数 `n` およびシミュレーション回数・仮定する上振れ確率α を入力とする
0. 保持するデータ: トップラス比の上下限・そのトップラス比に基づく実験結果 (上位α段位効率)
0. 開始時: トップラス比 0, (たとえば) 2 から始める
    * 二分探索の終了条件は「シミュレーションの精度が二分探索の精度と同程度となったとき」
        * シミュレーション回数が無限大であるとき、本来の二分探索の仮定がみたされる: 上位α段位効率 f はトップラス比に対して単調な関数である
        * 乱数によるシミュレーションを行っているため不変条件 (`f(min) <= f(mid) <= f(max)`) が崩れるとき、探索を終了する
    * 探索結果トップラス比から順位分布および収束段位を求めて出力する
* 注意点
    * 評価するべき段位効率がその試合数でちょうど達成しうる値だと、二分探索が早期に「成功」(`f(mid) = e`) してしまい、精度が十分にならない
        * 評価する値が `e` なら `e-ε, e, e+ε` の3つの値に対して探索を行い、この現象を避けるべきである

