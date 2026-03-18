<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>やまだのぷよぷよパズル</title>
    <style>
        /* CSS: デザインの設定 */
        body {
            background-color: #fff9e6; /* やまださんらしい楽しそうな薄黄色 */
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
            font-family: 'Hiragino Sans', 'Meiryo', sans-serif;
        }

        .game-container {
            position: relative;
            border: 8px solid #ffcf33;
            border-radius: 20px;
            background-color: #333;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            overflow: hidden;
        }

        canvas {
            display: block;
        }

        .info-panel {
            margin-bottom: 15px;
            text-align: center;
            background: white;
            padding: 10px 20px;
            border-radius: 50px;
            box-shadow: 0 4px 10px rgba(0,0,0,0.1);
        }

        .score {
            font-size: 24px;
            font-weight: bold;
            color: #ff6f61;
        }

        .controls {
            margin-top: 15px;
            font-size: 14px;
            color: #666;
            background: rgba(255,255,255,0.8);
            padding: 5px 15px;
            border-radius: 10px;
        }
    </style>
</head>
<body>

    <div class="info-panel">
        <div class="score">SCORE: <span id="scoreVal">0</span></div>
    </div>

    <div class="game-container">
        <canvas id="gameCanvas" width="240" height="480"></canvas>
    </div>

    <div class="controls">
        移動: ← → / 回転: ↑ / 加速: ↓
    </div>

<script>
    /* JavaScript: ゲームの動き */
    const canvas = document.getElementById('gameCanvas');
    const ctx = canvas.getContext('2d');
    const scoreElement = document.getElementById('scoreVal');

    const ROW = 12;
    const COL = 6;
    const SIZE = 40;
    // ぷよの色（1:赤, 2:緑, 3:黄, 4:紫）
    const COLORS = [null, '#FF6F61', '#4DB6AC', '#FFD54F', '#9575CD'];

    let board = Array.from({ length: ROW }, () => Array(COL).fill(0));
    let currentPuyo = { x: 2, y: 0, colors: [1, 2], rot: 0 };
    let score = 0;
    let isProcessing = false;

    // 描画メイン
    function draw() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        
        // 盤面の描画
        board.forEach((row, y) => {
            row.forEach((val, x) => {
                if (val) drawPuyo(x, y, COLORS[val]);
            });
        });

        // 操作中のぷよを描画
        if (!isProcessing) {
            drawPuyo(currentPuyo.x, currentPuyo.y, COLORS[currentPuyo.colors[0]]);
            let ox = [0, 1, 0, -1][currentPuyo.rot];
            let oy = [-1, 0, 1, 0][currentPuyo.rot];
            drawPuyo(currentPuyo.x + ox, currentPuyo.y + oy, COLORS[currentPuyo.colors[1]]);
        }
    }

    // ぷよ一個を描く
    function drawPuyo(x, y, color) {
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.arc(x * SIZE + SIZE/2, y * SIZE + SIZE/2, SIZE/2 - 3, 0, Math.PI * 2);
        ctx.fill();
        // 光沢（ぷよっぽく）
        ctx.fillStyle = 'rgba(255,255,255,0.4)';
        ctx.beginPath();
        ctx.arc(x * SIZE + SIZE/3, y * SIZE + SIZE/3, 5, 0, Math.PI * 2);
        ctx.fill();
    }

    // 落下処理
    async function handleDrop() {
        if (isProcessing) return;

        if (!checkCollision(0, 1, currentPuyo.rot)) {
            currentPuyo.y++;
        } else {
            isProcessing = true;
            lockPuyo();
            await processChains();
            spawnPuyo();
            isProcessing = false;
        }
        draw();
    }

    // 衝突判定
    function checkCollision(dx, dy, dr) {
        let ox = [0, 1, 0, -1][dr];
        let oy = [-1, 0, 1, 0][dr];
        let pts = [[currentPuyo.x + dx, currentPuyo.y + dy], [currentPuyo.x + ox + dx, currentPuyo.y + oy + dy]];
