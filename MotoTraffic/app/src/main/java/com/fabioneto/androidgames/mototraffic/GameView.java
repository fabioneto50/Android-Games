package com.fabioneto.androidgames.mototraffic;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.media.AudioManager;
import android.media.ToneGenerator;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.view.HapticFeedbackConstants;
import android.view.MotionEvent;
import android.view.View;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Random;

public final class GameView extends View {
    private enum Screen { HOME, GARAGE, CAREER, SEASON, PILOT, GAME, RESULT }

    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Random random = new Random();
    private final SaveManager save;
    private final Vibrator vibrator;

    private ToneGenerator tone;
    private Screen screen = Screen.HOME;
    private boolean paused;
    private long previousFrameNs;

    private float width;
    private float height;
    private float density;

    private int garageBike;
    private int careerPage;
    private int selectedStage = -1;

    private float playerX;
    private float playerY;
    private float speed;
    private float health;
    private float nitro;
    private float heat;
    private float distanceKm;
    private float roadPhase;
    private float nitroTime;
    private float wheelieTime;
    private float crashCooldown;
    private float trafficSpawn;
    private float coinSpawn;
    private float eventTimer;
    private float eventRemaining;
    private int score;
    private int runCoins;
    private int nearMisses;
    private int currentMap;
    private String weather = "Limpo";
    private String event = "";
    private boolean bossActive;

    private int resultScore;
    private int resultCoins;
    private int resultStars;

    private final List<Traffic> traffic = new ArrayList<>();
    private final List<Coin> coins = new ArrayList<>();

    GameView(Context context) {
        super(context);
        setFocusable(true);
        setClickable(true);
        save = new SaveManager(context.getApplicationContext());
        garageBike = save.selectedBike;
        vibrator = (Vibrator) context.getSystemService(Context.VIBRATOR_SERVICE);
        stroke.setStyle(Paint.Style.STROKE);
        stroke.setStrokeWidth(dp(2));
        setBackgroundColor(Color.rgb(7, 11, 18));
    }

    void setPaused(boolean value) {
        paused = value;
        previousFrameNs = 0L;
        if (value) save.save();
        else postInvalidateOnAnimation();
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        width = w;
        height = h;
        density = getResources().getDisplayMetrics().density;
        playerX = width * 0.5f;
        playerY = height * 0.78f;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (!paused && screen == Screen.GAME) {
            long now = System.nanoTime();
            if (previousFrameNs == 0L) previousFrameNs = now;
            float dt = Math.min(0.033f, (now - previousFrameNs) / 1_000_000_000f);
            previousFrameNs = now;
            updateGame(dt);
        } else {
            previousFrameNs = 0L;
        }

        switch (screen) {
            case HOME: drawHome(canvas); break;
            case GARAGE: drawGarage(canvas); break;
            case CAREER: drawCareer(canvas); break;
            case SEASON: drawSeason(canvas); break;
            case PILOT: drawPilot(canvas); break;
            case GAME: drawGame(canvas); break;
            case RESULT: drawResult(canvas); break;
        }

        if (!paused && screen == Screen.GAME) postInvalidateOnAnimation();
    }

    @Override
    public boolean onTouchEvent(MotionEvent eventMotion) {
        if (eventMotion.getAction() == MotionEvent.ACTION_DOWN) {
            handleTap(eventMotion.getX(), eventMotion.getY());
            return true;
        }
        if (eventMotion.getAction() == MotionEvent.ACTION_MOVE && screen == Screen.GAME) {
            float roadLeft = width * 0.14f;
            float roadRight = width * 0.86f;
            float handling = GameData.BIKE_HANDLING[save.selectedBike]
                    * (1f + save.upgrades[save.selectedBike][1] * 0.05f);
            float target = clamp(eventMotion.getX(), roadLeft + dp(24), roadRight - dp(24));
            playerX += (target - playerX) * Math.min(0.9f, 0.35f * handling);
            invalidate();
            return true;
        }
        return true;
    }

    private void handleTap(float x, float y) {
        switch (screen) {
            case HOME: handleHomeTap(x, y); break;
            case GARAGE: handleGarageTap(x, y); break;
            case CAREER: handleCareerTap(x, y); break;
            case SEASON:
            case PILOT:
                if (isBackTap(x, y)) screen = Screen.HOME;
                break;
            case GAME: handleGameTap(x, y); break;
            case RESULT: handleResultTap(x, y); break;
        }
        haptic(8);
        invalidate();
    }

    private void handleHomeTap(float x, float y) {
        float firstY = height * 0.49f;
        if (between(y, firstY, firstY + dp(74))) {
            startGame(-1);
            return;
        }
        float row1 = firstY + dp(86);
        if (between(y, row1, row1 + dp(68))) {
            if (x < width * 0.5f) screen = Screen.CAREER;
            else screen = Screen.GARAGE;
            return;
        }
        float row2 = row1 + dp(79);
        if (between(y, row2, row2 + dp(68))) {
            if (x < width * 0.5f) screen = Screen.SEASON;
            else screen = Screen.PILOT;
        }
    }

    private void handleGarageTap(float x, float y) {
        if (isBackTap(x, y)) {
            screen = Screen.HOME;
            return;
        }
        if (between(y, height * 0.27f, height * 0.39f)) {
            if (x < width * 0.30f) garageBike = (garageBike + 6) % 7;
            else if (x > width * 0.70f) garageBike = (garageBike + 1) % 7;
            return;
        }

        float upgradesY = height * 0.52f;
        for (int slot = 0; slot < 4; slot++) {
            float top = upgradesY + dp(67) * slot;
            if (between(y, top, top + dp(58)) && x > width * 0.58f) {
                save.upgrade(garageBike, slot);
                return;
            }
        }

        if (y > height - dp(112)) save.buyOrSelectBike(garageBike);
    }

    private void handleCareerTap(float x, float y) {
        if (isBackTap(x, y)) {
            screen = Screen.HOME;
            return;
        }
        float rowY = dp(125);
        for (int index = 0; index < 6; index++) {
            float top = rowY + dp(84) * index;
            if (between(y, top, top + dp(74))) {
                int stage = careerPage * 6 + index;
                if (stage < 12 && save.canPlayStage(stage)) startGame(stage);
                return;
            }
        }
        if (y > height - dp(125)) {
            if (x < width * 0.5f) careerPage = 0;
            else careerPage = 1;
        }
    }

    private void handleGameTap(float x, float y) {
        if (x > width - dp(140) && y > height - dp(140) && y < height - dp(76)) {
            if (nitro >= 8f && nitroTime <= 0f) {
                nitroTime = 2.8f;
                sound(ToneGenerator.TONE_PROP_BEEP, 80);
                haptic(18);
            }
            return;
        }
        if (x > width - dp(140) && y > height - dp(72)) {
            if (wheelieTime <= 0f && speed > 85f) {
                wheelieTime = 1.5f;
                haptic(10);
            }
        }
    }

    private void handleResultTap(float x, float y) {
        if (y > height - dp(170) && y < height - dp(95)) {
            startGame(selectedStage);
        } else if (y > height - dp(90)) {
            screen = Screen.HOME;
        }
    }

    private void startGame(int stage) {
        selectedStage = stage;
        currentMap = stage >= 0 ? GameData.mapForStage(stage) : save.totalRuns % 4;
        playerX = width * 0.5f;
        playerY = height * 0.78f;
        speed = 65f;
        health = 100f;
        nitro = 100f;
        heat = 0f;
        distanceKm = 0f;
        roadPhase = 0f;
        nitroTime = 0f;
        wheelieTime = 0f;
        crashCooldown = 0f;
        trafficSpawn = 0.8f;
        coinSpawn = 0.9f;
        eventTimer = 11f + random.nextFloat() * 8f;
        eventRemaining = 0f;
        score = 0;
        runCoins = 0;
        nearMisses = 0;
        event = "";
        bossActive = false;
        traffic.clear();
        coins.clear();

        if (currentMap == 1) weather = random.nextBoolean() ? "Limpo" : "Nevoeiro";
        else if (currentMap == 2) weather = random.nextBoolean() ? "Limpo" : "Chuva";
        else if (currentMap == 3) weather = "Noite";
        else weather = random.nextInt(3) == 0 ? "Chuva" : "Limpo";

        previousFrameNs = 0L;
        screen = Screen.GAME;
    }

    private void updateGame(float dt) {
        if (dt <= 0f) return;
        if (health <= 0f) {
            finishGame();
            return;
        }

        float engineUpgrade = 1f + save.upgrades[save.selectedBike][0] * 0.035f;
        float topSpeed = 190f * GameData.BIKE_SPEED[save.selectedBike] * engineUpgrade;
        speed += (topSpeed - speed) * dt * 0.10f;

        if (nitroTime > 0f) {
            nitroTime -= dt;
            speed = Math.min(topSpeed * 1.20f, speed + 72f * dt);
            nitro = Math.max(0f, nitro - 24f * dt);
            if (nitro <= 0f) nitroTime = 0f;
        } else {
            float recharge = 3f + save.upgrades[save.selectedBike][2] * 0.9f;
            nitro = Math.min(100f, nitro + recharge * dt);
        }

        if (wheelieTime > 0f) {
            wheelieTime -= dt;
            score += Math.max(1, Math.round(55f * dt));
        }

        crashCooldown = Math.max(0f, crashCooldown - dt);
        distanceKm += speed * dt / 3600f;
        roadPhase = (roadPhase + speed * dt * 1.25f) % dp(120);
        score += Math.max(1, Math.round(speed * dt * (1f + heat / 240f)));

        if (speed > 145f) heat = Math.min(100f, heat + (speed - 140f) * 0.0032f * dt * 60f);
        else heat = Math.max(0f, heat - 1.6f * dt);

        eventTimer -= dt;
        if (eventTimer <= 0f && eventRemaining <= 0f) {
            event = GameData.EVENTS[random.nextInt(GameData.EVENTS.length)];
            eventRemaining = 7.5f;
            eventTimer = 21f + random.nextFloat() * 12f;
            sound(ToneGenerator.TONE_PROP_BEEP, 70);
        }
        if (eventRemaining > 0f) {
            eventRemaining -= dt;
            if (eventRemaining <= 0f) event = "";
        }

        if (heat >= 92f && !bossActive) {
            bossActive = true;
            spawnBoss();
        }

        trafficSpawn -= dt;
        float trafficDensity = event.equals("Obras") ? 0.62f : Math.max(0.48f, 1.05f - speed / 440f);
        if (trafficSpawn <= 0f) {
            spawnTraffic();
            trafficSpawn = trafficDensity + random.nextFloat() * 0.48f;
        }

        coinSpawn -= dt;
        if (coinSpawn <= 0f) {
            spawnCoin();
            coinSpawn = event.equals("Coin Rush") ? 0.24f : 0.85f + random.nextFloat() * 0.9f;
        }

        Iterator<Traffic> trafficIterator = traffic.iterator();
        while (trafficIterator.hasNext()) {
            Traffic car = trafficIterator.next();
            float relative = (speed - car.speed + 82f) * 2.8f;
            car.y += relative * dt;
            if (car.police && heat > 20f) car.x += sign(playerX - car.x) * dp(32) * dt;
            if (car.boss) car.x += sign(playerX - car.x) * dp(52) * dt;

            float dx = Math.abs(car.x - playerX);
            float dy = Math.abs(car.y - playerY);
            if (dx < dp(43) && dy < dp(66) && crashCooldown <= 0f) {
                float armor = GameData.BIKE_ARMOR[save.selectedBike]
                        * (1f + save.upgrades[save.selectedBike][3] * 0.08f);
                health -= (car.boss ? 44f : 29f) / armor;
                speed *= 0.64f;
                crashCooldown = 1f;
                heat = Math.min(100f, heat + 12f);
                haptic(45);
                sound(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 90);
                car.y += dp(120);
            } else if (!car.passed && car.y > playerY + dp(66) && dx < dp(88)) {
                car.passed = true;
                nearMisses++;
                score += 165 + Math.round(heat * 1.5f);
                heat = Math.min(100f, heat + 3f);
                haptic(7);
            }

            if (car.y > height + dp(180)) trafficIterator.remove();
        }

        Iterator<Coin> coinIterator = coins.iterator();
        while (coinIterator.hasNext()) {
            Coin coin = coinIterator.next();
            coin.y += (speed + 65f) * 2.75f * dt;
            if (Math.abs(coin.x - playerX) < dp(40) && Math.abs(coin.y - playerY) < dp(56)) {
                runCoins++;
                score += 70;
                coinIterator.remove();
                sound(ToneGenerator.TONE_PROP_ACK, 40);
            } else if (coin.y > height + dp(60)) {
                coinIterator.remove();
            }
        }
    }

    private void finishGame() {
        resultScore = score;
        resultCoins = runCoins + (save.premium ? Math.round(runCoins * 0.25f) : 0);
        resultStars = save.completeRun(score, runCoins, selectedStage, health);
        traffic.clear();
        coins.clear();
        screen = Screen.RESULT;
        previousFrameNs = 0L;
    }

    private void spawnTraffic() {
        float left = width * 0.14f;
        float right = width * 0.86f;
        float laneWidth = (right - left) / 3f;
        int lane = random.nextInt(3);
        Traffic car = new Traffic();
        car.x = left + laneWidth * (lane + 0.5f);
        car.y = -dp(120);
        car.speed = 38f + random.nextFloat() * 85f;
        car.type = random.nextInt(4);
        car.police = heat > 55f && random.nextInt(6) == 0;
        traffic.add(car);

        if (event.equals("Bloqueio") && random.nextInt(3) == 0) {
            Traffic block = new Traffic();
            block.x = left + laneWidth * (random.nextInt(3) + 0.5f);
            block.y = -dp(230);
            block.speed = 0f;
            block.type = 3;
            traffic.add(block);
        }
    }

    private void spawnBoss() {
        Traffic boss = new Traffic();
        boss.x = width * 0.5f;
        boss.y = -dp(180);
        boss.speed = 145f;
        boss.boss = true;
        boss.police = true;
        traffic.add(boss);
    }

    private void spawnCoin() {
        float left = width * 0.14f;
        float right = width * 0.86f;
        float laneWidth = (right - left) / 3f;
        Coin coin = new Coin();
        coin.x = left + laneWidth * (random.nextInt(3) + 0.5f);
        coin.y = -dp(42);
        coins.add(coin);
    }

    private void drawHome(Canvas canvas) {
        drawBackground(canvas);
        drawTitle(canvas, "MOTO", "TRAFFIC · REBORN");
        drawTopStats(canvas);

        if (save.premium) drawPill(canvas, dp(26), dp(104), dp(154), dp(140), "PREMIUM ON", Color.rgb(174, 108, 255));

        drawText(canvas, "PILOTO", 12f, dp(28), dp(187), Color.LTGRAY, true, Paint.Align.LEFT);
        drawText(canvas, GameData.BIKES[save.selectedBike], 28f, dp(28), dp(224), Color.WHITE, true, Paint.Align.LEFT);
        drawBike(canvas, width * 0.5f, height * 0.34f, 1.40f, save.selectedBike, false);

        float y = height * 0.49f;
        drawBigButton(canvas, dp(28), y, width - dp(28), y + dp(74),
                "CORRIDA RÁPIDA", "Trânsito infinito · " + GameData.MAPS[save.totalRuns % 4], Color.rgb(255, 176, 0));
        y += dp(86);
        drawTwoButtons(canvas, y, "CARREIRA", save.totalStars() + "/36 ★", "GARAGEM", "7 motos · upgrades");
        y += dp(79);
        drawTwoButtons(canvas, y, "TEMPORADA", "S1 · " + save.seasonPoints + " SP", "PILOTO", "stats · ranking");

        float dailyY = Math.min(height - dp(135), y + dp(96));
        drawText(canvas, "DESAFIOS DIÁRIOS", 12f, dp(28), dailyY, Color.rgb(255, 176, 0), true, Paint.Align.LEFT);
        String[] challenges = save.dailyChallenges();
        for (int i = 0; i < challenges.length; i++) {
            drawText(canvas, "• " + challenges[i], 12f, dp(28), dailyY + dp(23 + i * 21), Color.LTGRAY, false, Paint.Align.LEFT);
        }
        drawText(canvas, "v1.0 Reborn · Android 6+", 10f, width - dp(20), height - dp(18), Color.GRAY, false, Paint.Align.RIGHT);
    }

    private void drawGarage(Canvas canvas) {
        drawBackground(canvas);
        drawTitle(canvas, "GARAGEM", "MOTOS · PERFORMANCE");
        drawTopStats(canvas);
        drawBack(canvas);

        drawBike(canvas, width * 0.5f, height * 0.28f, 1.75f, garageBike, false);
        drawText(canvas, GameData.BIKES[garageBike], 28f, width * 0.5f, height * 0.43f, Color.WHITE, true, Paint.Align.CENTER);
        String status = save.unlocked[garageBike]
                ? (save.selectedBike == garageBike ? "SELECIONADA" : "DESBLOQUEADA")
                : GameData.BIKE_COST[garageBike] + " ◈";
        drawText(canvas, status, 13f, width * 0.5f, height * 0.465f,
                save.unlocked[garageBike] ? Color.rgb(93, 225, 147) : Color.rgb(255, 176, 0), true, Paint.Align.CENTER);
        drawPill(canvas, dp(22), height * 0.30f, dp(70), height * 0.36f, "‹", Color.WHITE);
        drawPill(canvas, width - dp(70), height * 0.30f, width - dp(22), height * 0.36f, "›", Color.WHITE);

        String[] labels = {"MOTOR", "AGILIDADE", "NITRO", "BLINDAGEM"};
        float y = height * 0.52f;
        for (int slot = 0; slot < 4; slot++) {
            int level = save.upgrades[garageBike][slot];
            drawPanel(canvas, dp(28), y, width - dp(28), y + dp(58), Color.rgb(16, 24, 36));
            drawText(canvas, labels[slot], 13f, dp(43), y + dp(24), Color.WHITE, true, Paint.Align.LEFT);
            drawText(canvas, "LV " + level + "/5", 11f, dp(43), y + dp(44), Color.LTGRAY, false, Paint.Align.LEFT);
            String cost = level >= 5 ? "MAX" : save.upgradeCost(garageBike, slot) + " ◈";
            drawPill(canvas, width - dp(145), y + dp(10), width - dp(40), y + dp(48), cost,
                    level >= 5 ? Color.GRAY : Color.rgb(255, 176, 0));
            y += dp(67);
        }

        drawBigButton(canvas, dp(28), height - dp(106), width - dp(28), height - dp(44),
                save.unlocked[garageBike] ? "USAR MOTO" : "COMPRAR MOTO", "",
                save.unlocked[garageBike] ? Color.rgb(93, 225, 147) : Color.rgb(255, 176, 0));
    }

    private void drawCareer(Canvas canvas) {
        drawBackground(canvas);
        drawTitle(canvas, "CARREIRA", "12 ETAPAS · 36 ESTRELAS");
        drawTopStats(canvas);
        drawBack(canvas);

        float y = dp(125);
        int start = careerPage * 6;
        for (int i = 0; i < 6; i++) {
            int stage = start + i;
            if (stage >= 12) break;
            boolean open = save.canPlayStage(stage);
            drawPanel(canvas, dp(24), y, width - dp(24), y + dp(74), open ? Color.rgb(16, 24, 36) : Color.rgb(12, 15, 20));
            drawText(canvas, String.format(Locale.US, "%02d", stage + 1), 22f, dp(40), y + dp(31), open ? Color.rgb(255, 176, 0) : Color.DKGRAY, true, Paint.Align.LEFT);
            drawText(canvas, GameData.CAREER[stage], 15f, dp(88), y + dp(29), open ? Color.WHITE : Color.GRAY, true, Paint.Align.LEFT);
            drawText(canvas, GameData.MAPS[GameData.mapForStage(stage)] + " · alvo " + GameData.targetForStage(stage),
                    11f, dp(88), y + dp(51), Color.LTGRAY, false, Paint.Align.LEFT);
            drawText(canvas, stars(save.stars[stage]), 15f, width - dp(40), y + dp(42),
                    save.stars[stage] > 0 ? Color.rgb(255, 176, 0) : Color.DKGRAY, true, Paint.Align.RIGHT);
            y += dp(84);
        }

        drawTwoButtons(canvas, height - dp(116), careerPage == 0 ? "PÁG. 1" : "← ANTERIOR", "",
                careerPage == 0 ? "SEGUINTE →" : "PÁG. 2", "");
    }

    private void drawSeason(Canvas canvas) {
        drawBackground(canvas);
        drawTitle(canvas, "TEMPORADA 1", "ASPHALT STORM · 10 TIERS");
        drawTopStats(canvas);
        drawBack(canvas);

        drawText(canvas, save.seasonPoints + " SP", 34f, dp(28), dp(138), Color.WHITE, true, Paint.Align.LEFT);
        drawText(canvas, "Cada corrida aumenta Season Points", 12f, dp(28), dp(162), Color.LTGRAY, false, Paint.Align.LEFT);

        float y = dp(196);
        for (int tier = 1; tier <= 10; tier++) {
            int required = tier * 75;
            boolean done = save.seasonPoints >= required;
            float x1 = dp(28) + ((tier - 1) % 2) * (width / 2f - dp(18));
            float x2 = x1 + width / 2f - dp(38);
            float yy = y + ((tier - 1) / 2) * dp(82);
            drawPanel(canvas, x1, yy, x2, yy + dp(65), done ? Color.rgb(27, 46, 40) : Color.rgb(16, 24, 36));
            drawText(canvas, "TIER " + tier, 14f, x1 + dp(14), yy + dp(27), Color.WHITE, true, Paint.Align.LEFT);
            drawText(canvas, required + " SP", 10f, x1 + dp(14), yy + dp(48), done ? Color.rgb(93, 225, 147) : Color.GRAY, false, Paint.Align.LEFT);
            drawText(canvas, done ? "✓" : "◈", 17f, x2 - dp(14), yy + dp(39), done ? Color.rgb(93, 225, 147) : Color.rgb(255, 176, 0), true, Paint.Align.RIGHT);
        }
        drawText(canvas, "Premium: +25% moedas · CAFÉ 650 desbloqueada", 11f, dp(28), height - dp(70), Color.rgb(194, 156, 255), false, Paint.Align.LEFT);
    }

    private void drawPilot(Canvas canvas) {
        drawBackground(canvas);
        drawTitle(canvas, "PILOTO", "ESTATÍSTICAS · RANKING LOCAL");
        drawTopStats(canvas);
        drawBack(canvas);

        drawStat(canvas, dp(28), dp(132), "NÍVEL", String.valueOf(save.level()));
        drawStat(canvas, width / 2f + dp(7), dp(132), "MELHOR SCORE", String.valueOf(save.bestScore));
        drawStat(canvas, dp(28), dp(227), "CORRIDAS", String.valueOf(save.totalRuns));
        drawStat(canvas, width / 2f + dp(7), dp(227), "MOEDAS", String.valueOf(save.totalCoins));
        drawStat(canvas, dp(28), dp(322), "ESTRELAS", save.totalStars() + "/36");
        drawStat(canvas, width / 2f + dp(7), dp(322), "SEASON", save.seasonPoints + " SP");

        drawText(canvas, "LEADERBOARD", 14f, dp(28), dp(442), Color.rgb(255, 176, 0), true, Paint.Align.LEFT);
        List<Integer> leaderboard = save.localLeaderboard();
        for (int i = 0; i < leaderboard.size(); i++) {
            float y = dp(462 + i * 58);
            drawPanel(canvas, dp(28), y, width - dp(28), y + dp(50), Color.rgb(16, 24, 36));
            drawText(canvas, (i + 1) + ".", 16f, dp(42), y + dp(31), Color.LTGRAY, true, Paint.Align.LEFT);
            drawText(canvas, i == 0 ? "TU" : "RIVAL " + i, 14f, dp(78), y + dp(31), Color.WHITE, true, Paint.Align.LEFT);
            drawText(canvas, String.valueOf(leaderboard.get(i)), 15f, width - dp(42), y + dp(31), Color.rgb(255, 176, 0), true, Paint.Align.RIGHT);
        }
    }

    private void drawGame(Canvas canvas) {
        drawRoad(canvas);
        for (Coin coin : coins) drawCoin(canvas, coin);
        for (Traffic car : traffic) drawTraffic(canvas, car);
        drawBike(canvas, playerX, playerY, wheelieTime > 0f ? 1.08f : 1f, save.selectedBike, wheelieTime > 0f);
        drawHud(canvas);

        if (eventRemaining > 0f) {
            drawPanel(canvas, width * 0.20f, dp(95), width * 0.80f, dp(141), Color.argb(225, 18, 24, 32));
            drawText(canvas, event.toUpperCase(Locale.ROOT), 17f, width * 0.5f, dp(125), Color.rgb(255, 176, 0), true, Paint.Align.CENTER);
        }
        if (bossActive) drawText(canvas, "BLACK VIPER", 15f, width * 0.5f, dp(169), Color.rgb(255, 68, 76), true, Paint.Align.CENTER);

        if (weather.equals("Chuva")) drawRain(canvas);
        if (weather.equals("Nevoeiro")) {
            paint.setColor(Color.argb(58, 225, 232, 236));
            canvas.drawRect(0, 0, width, height, paint);
        }
        if (currentMap == 3 || event.equals("Blackout")) {
            paint.setColor(Color.argb(event.equals("Blackout") ? 108 : 66, 0, 0, 10));
            canvas.drawRect(0, 0, width, height, paint);
        }
    }

    private void drawResult(Canvas canvas) {
        drawBackground(canvas);
        drawTitle(canvas, "RESULTADO", selectedStage >= 0 ? GameData.CAREER[selectedStage] : "CORRIDA RÁPIDA");
        drawText(canvas, String.valueOf(resultScore), 48f, width * 0.5f, height * 0.30f, Color.WHITE, true, Paint.Align.CENTER);
        drawText(canvas, "SCORE", 12f, width * 0.5f, height * 0.34f, Color.GRAY, true, Paint.Align.CENTER);

        drawStat(canvas, dp(28), height * 0.42f, "MOEDAS", "+" + resultCoins);
        drawStat(canvas, width / 2f + dp(7), height * 0.42f, "ESTRELAS", selectedStage >= 0 ? stars(resultStars) : "—");
        drawStat(canvas, dp(28), height * 0.54f, "NÍVEL", String.valueOf(save.level()));
        drawStat(canvas, width / 2f + dp(7), height * 0.54f, "SEASON", save.seasonPoints + " SP");

        drawBigButton(canvas, dp(28), height - dp(170), width - dp(28), height - dp(102), "REPETIR", "", Color.rgb(255, 176, 0));
        drawBigButton(canvas, dp(28), height - dp(90), width - dp(28), height - dp(30), "MENU PRINCIPAL", "", Color.rgb(62, 75, 92));
    }

    private void drawRoad(Canvas canvas) {
        int sky;
        if (currentMap == 1) sky = Color.rgb(38, 89, 111);
        else if (currentMap == 2) sky = Color.rgb(33, 63, 43);
        else if (currentMap == 3) sky = Color.rgb(5, 7, 15);
        else sky = Color.rgb(42, 56, 72);
        canvas.drawColor(sky);

        paint.setColor(currentMap == 1 ? Color.rgb(202, 174, 102) : Color.rgb(32, 71, 40));
        canvas.drawRect(0, height * 0.1f, width, height, paint);

        float left = width * 0.14f;
        float right = width * 0.86f;
        paint.setColor(Color.rgb(45, 47, 51));
        canvas.drawRect(left, 0, right, height, paint);
        paint.setColor(Color.rgb(240, 240, 230));
        canvas.drawRect(left - dp(4), 0, left + dp(4), height, paint);
        canvas.drawRect(right - dp(4), 0, right + dp(4), height, paint);

        float lane = (right - left) / 3f;
        paint.setColor(Color.argb(178, 245, 245, 225));
        float dashHeight = dp(52);
        float dashGap = dp(120);
        for (int k = 1; k < 3; k++) {
            for (float y = -dashGap + roadPhase; y < height; y += dashGap) {
                canvas.drawRoundRect(left + lane * k - dp(2.5f), y, left + lane * k + dp(2.5f), y + dashHeight, dp(2), dp(2), paint);
            }
        }
    }

    private void drawHud(Canvas canvas) {
        drawPanel(canvas, dp(14), dp(14), width - dp(14), dp(87), Color.argb(210, 7, 11, 18));
        drawText(canvas, String.valueOf(Math.round(speed)), 26f, dp(27), dp(49), Color.WHITE, true, Paint.Align.LEFT);
        drawText(canvas, "KM/H", 9f, dp(28), dp(68), Color.GRAY, true, Paint.Align.LEFT);
        drawText(canvas, String.valueOf(score), 20f, width * 0.5f, dp(49), Color.rgb(255, 176, 0), true, Paint.Align.CENTER);
        drawText(canvas, String.format(Locale.US, "%.2f KM", distanceKm), 9f, width * 0.5f, dp(68), Color.GRAY, true, Paint.Align.CENTER);
        drawText(canvas, "HP " + Math.max(0, Math.round(health)), 11f, width - dp(28), dp(38), health < 35f ? Color.RED : Color.WHITE, true, Paint.Align.RIGHT);
        drawText(canvas, "HEAT " + Math.round(heat) + "%", 11f, width - dp(28), dp(60), heat > 70f ? Color.rgb(255, 68, 76) : Color.LTGRAY, true, Paint.Align.RIGHT);
        drawText(canvas, weather + " · " + GameData.MAPS[currentMap], 9f, width - dp(28), dp(78), Color.GRAY, false, Paint.Align.RIGHT);

        drawPill(canvas, width - dp(138), height - dp(140), width - dp(18), height - dp(78), "NITRO", nitro > 8f ? Color.rgb(68, 181, 255) : Color.DKGRAY);
        drawPill(canvas, width - dp(138), height - dp(70), width - dp(18), height - dp(16), "WHEELIE", Color.rgb(255, 176, 0));
        drawPanel(canvas, dp(18), height - dp(70), dp(126), height - dp(16), Color.argb(195, 7, 11, 18));
        drawText(canvas, "◈ " + runCoins, 14f, dp(31), height - dp(39), Color.rgb(255, 176, 0), true, Paint.Align.LEFT);
        drawText(canvas, "NEAR " + nearMisses, 10f, dp(31), height - dp(21), Color.GRAY, false, Paint.Align.LEFT);
    }

    private void drawTraffic(Canvas canvas, Traffic car) {
        int color;
        if (car.boss) color = Color.rgb(8, 8, 10);
        else if (car.police) color = Color.rgb(30, 45, 70);
        else if (car.type == 0) color = Color.rgb(210, 52, 62);
        else if (car.type == 1) color = Color.rgb(80, 146, 211);
        else if (car.type == 2) color = Color.rgb(223, 218, 206);
        else color = Color.rgb(112, 117, 126);

        paint.setColor(Color.argb(70, 0, 0, 0));
        canvas.drawRoundRect(car.x - dp(38), car.y - dp(62), car.x + dp(38), car.y + dp(67), dp(15), dp(15), paint);
        paint.setColor(color);
        canvas.drawRoundRect(car.x - dp(34), car.y - dp(60), car.x + dp(34), car.y + dp(60), dp(14), dp(14), paint);
        paint.setColor(Color.rgb(142, 192, 210));
        canvas.drawRoundRect(car.x - dp(26), car.y - dp(35), car.x + dp(26), car.y - dp(4), dp(8), dp(8), paint);
        paint.setColor(Color.rgb(35, 39, 45));
        canvas.drawRoundRect(car.x - dp(27), car.y + dp(10), car.x + dp(27), car.y + dp(38), dp(7), dp(7), paint);
        if (car.police) {
            paint.setColor(car.boss ? Color.rgb(255, 28, 41) : Color.rgb(54, 151, 255));
            canvas.drawRect(car.x - dp(24), car.y - dp(3), car.x + dp(24), car.y + dp(4), paint);
        }
    }

    private void drawCoin(Canvas canvas, Coin coin) {
        paint.setColor(Color.rgb(255, 183, 0));
        canvas.drawCircle(coin.x, coin.y, dp(15), paint);
        paint.setColor(Color.rgb(255, 225, 117));
        canvas.drawCircle(coin.x, coin.y, dp(8), paint);
    }

    private void drawBike(Canvas canvas, float x, float y, float scale, int bike, boolean wheelie) {
        int[] colors = {
                Color.rgb(255, 176, 0), Color.rgb(220, 48, 58), Color.rgb(42, 130, 208),
                Color.rgb(96, 219, 151), Color.rgb(178, 73, 255), Color.rgb(223, 222, 213), Color.rgb(56, 215, 229)
        };
        int safeBike = Math.max(0, Math.min(colors.length - 1, bike));

        canvas.save();
        canvas.translate(x, y);
        canvas.scale(scale, scale);
        if (wheelie) canvas.rotate(-7f);

        paint.setColor(Color.argb(75, 0, 0, 0));
        canvas.drawOval(-dp(28), dp(40), dp(28), dp(70), paint);
        paint.setColor(Color.rgb(20, 22, 26));
        canvas.drawOval(-dp(24), -dp(58), dp(24), -dp(22), paint);
        canvas.drawOval(-dp(25), dp(27), dp(25), dp(68), paint);

        paint.setColor(colors[safeBike]);
        Path body = new Path();
        body.moveTo(0, -dp(54));
        body.lineTo(dp(25), -dp(12));
        body.lineTo(dp(19), dp(42));
        body.lineTo(0, dp(55));
        body.lineTo(-dp(19), dp(42));
        body.lineTo(-dp(25), -dp(12));
        body.close();
        canvas.drawPath(body, paint);

        paint.setColor(Color.rgb(220, 235, 245));
        canvas.drawRoundRect(-dp(13), -dp(41), dp(13), -dp(18), dp(7), dp(7), paint);
        paint.setColor(Color.rgb(18, 22, 27));
        canvas.drawRoundRect(-dp(15), dp(4), dp(15), dp(28), dp(6), dp(6), paint);
        paint.setColor(Color.rgb(255, 72, 68));
        canvas.drawRoundRect(-dp(8), dp(38), dp(8), dp(48), dp(3), dp(3), paint);
        canvas.restore();
    }

    private void drawRain(Canvas canvas) {
        paint.setColor(Color.argb(95, 195, 225, 255));
        paint.setStrokeWidth(dp(1.3f));
        for (int i = 0; i < 26; i++) {
            float x = (i * dp(71) + roadPhase * 3f) % Math.max(1f, width);
            float y = (i * dp(137) + roadPhase * 5f) % Math.max(1f, height);
            canvas.drawLine(x, y, x - dp(8), y + dp(23), paint);
        }
    }

    private void drawBackground(Canvas canvas) {
        canvas.drawColor(Color.rgb(7, 11, 18));
        paint.setColor(Color.rgb(16, 24, 36));
        for (int i = 0; i < 8; i++) {
            float x = (i * dp(137)) % Math.max(dp(1), width);
            float y = (i * dp(223)) % Math.max(dp(1), height);
            canvas.drawCircle(x, y, dp(68 + (i % 3) * 22), paint);
        }
    }

    private void drawTitle(Canvas canvas, String top, String bottom) {
        drawText(canvas, top, 32f, dp(28), dp(60), Color.WHITE, true, Paint.Align.LEFT);
        drawText(canvas, bottom, 13f, dp(29), dp(87), Color.rgb(255, 176, 0), true, Paint.Align.LEFT);
    }

    private void drawTopStats(Canvas canvas) {
        drawPill(canvas, width - dp(198), dp(25), width - dp(112), dp(61), "◈ " + save.coins, Color.rgb(255, 176, 0));
        drawPill(canvas, width - dp(106), dp(25), width - dp(22), dp(61), "LV " + save.level(), Color.rgb(88, 184, 255));
    }

    private void drawBack(Canvas canvas) {
        drawPill(canvas, dp(22), height - dp(42), dp(96), height - dp(10), "‹ MENU", Color.LTGRAY);
    }

    private boolean isBackTap(float x, float y) {
        return x <= dp(115) && y >= height - dp(55);
    }

    private void drawStat(Canvas canvas, float x, float y, String label, String value) {
        float boxW = width / 2f - dp(35);
        drawPanel(canvas, x, y, x + boxW, y + dp(77), Color.rgb(16, 24, 36));
        drawText(canvas, label, 10f, x + dp(14), y + dp(25), Color.GRAY, true, Paint.Align.LEFT);
        drawText(canvas, value, 22f, x + dp(14), y + dp(56), Color.WHITE, true, Paint.Align.LEFT);
    }

    private void drawBigButton(Canvas canvas, float left, float top, float right, float bottom,
                               String main, String sub, int accent) {
        drawPanel(canvas, left, top, right, bottom, Color.rgb(18, 26, 38));
        paint.setColor(accent);
        canvas.drawRoundRect(left, top, left + dp(7), bottom, dp(8), dp(8), paint);
        drawText(canvas, main, 17f, left + dp(23), top + dp(31), Color.WHITE, true, Paint.Align.LEFT);
        if (sub != null && !sub.isEmpty()) {
            drawText(canvas, sub, 10f, left + dp(23), top + dp(53), Color.LTGRAY, false, Paint.Align.LEFT);
        }
        drawText(canvas, "›", 24f, right - dp(22), (top + bottom) / 2f + dp(8), accent, true, Paint.Align.RIGHT);
    }

    private void drawTwoButtons(Canvas canvas, float top, String leftMain, String leftSub, String rightMain, String rightSub) {
        float gap = dp(10);
        float left1 = dp(28);
        float right1 = width * 0.5f - gap / 2f;
        float left2 = width * 0.5f + gap / 2f;
        float right2 = width - dp(28);
        float bottom = top + dp(68);
        drawPanel(canvas, left1, top, right1, bottom, Color.rgb(16, 24, 36));
        drawPanel(canvas, left2, top, right2, bottom, Color.rgb(16, 24, 36));
        drawText(canvas, leftMain, 14f, left1 + dp(14), top + dp(29), Color.WHITE, true, Paint.Align.LEFT);
        drawText(canvas, rightMain, 14f, left2 + dp(14), top + dp(29), Color.WHITE, true, Paint.Align.LEFT);
        if (leftSub != null && !leftSub.isEmpty()) drawText(canvas, leftSub, 9f, left1 + dp(14), top + dp(50), Color.GRAY, false, Paint.Align.LEFT);
        if (rightSub != null && !rightSub.isEmpty()) drawText(canvas, rightSub, 9f, left2 + dp(14), top + dp(50), Color.GRAY, false, Paint.Align.LEFT);
    }

    private void drawPill(Canvas canvas, float left, float top, float right, float bottom, String text, int color) {
        paint.setColor(Color.argb(38, Color.red(color), Color.green(color), Color.blue(color)));
        canvas.drawRoundRect(left, top, right, bottom, dp(12), dp(12), paint);
        stroke.setColor(color);
        stroke.setStrokeWidth(dp(1.2f));
        canvas.drawRoundRect(left, top, right, bottom, dp(12), dp(12), stroke);
        drawText(canvas, text, 10.5f, (left + right) / 2f, (top + bottom) / 2f + dp(4), color, true, Paint.Align.CENTER);
    }

    private void drawPanel(Canvas canvas, float left, float top, float right, float bottom, int color) {
        paint.setColor(color);
        canvas.drawRoundRect(left, top, right, bottom, dp(14), dp(14), paint);
    }

    private void drawText(Canvas canvas, String text, float sp, float x, float y, int color, boolean bold, Paint.Align align) {
        paint.setColor(color);
        paint.setTextSize(sp(sp));
        paint.setTextAlign(align);
        paint.setTypeface(bold ? android.graphics.Typeface.DEFAULT_BOLD : android.graphics.Typeface.DEFAULT);
        paint.setStyle(Paint.Style.FILL);
        canvas.drawText(text, x, y, paint);
    }

    private void sound(int toneId, int durationMs) {
        try {
            if (tone == null) tone = new ToneGenerator(AudioManager.STREAM_MUSIC, 35);
            tone.startTone(toneId, durationMs);
        } catch (Throwable ignored) {
            // Sound is optional; gameplay must never crash if audio is unavailable.
        }
    }

    private void haptic(long milliseconds) {
        try {
            performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP);
            if (vibrator == null || !vibrator.hasVibrator()) return;
            if (Build.VERSION.SDK_INT >= 26) {
                vibrator.vibrate(VibrationEffect.createOneShot(milliseconds, VibrationEffect.DEFAULT_AMPLITUDE));
            } else {
                vibrator.vibrate(milliseconds);
            }
        } catch (Throwable ignored) {
            // Haptics are optional and never allowed to crash the game.
        }
    }

    private float dp(float value) {
        float d = density;
        if (d <= 0f) d = getResources().getDisplayMetrics().density;
        return value * d;
    }

    private float sp(float value) {
        return value * getResources().getDisplayMetrics().scaledDensity;
    }

    private static float clamp(float value, float min, float max) {
        return Math.max(min, Math.min(max, value));
    }

    private static boolean between(float value, float min, float max) {
        return value >= min && value <= max;
    }

    private static float sign(float value) {
        if (value > 0f) return 1f;
        if (value < 0f) return -1f;
        return 0f;
    }

    private static String stars(int count) {
        if (count <= 0) return "☆ ☆ ☆";
        if (count == 1) return "★ ☆ ☆";
        if (count == 2) return "★ ★ ☆";
        return "★ ★ ★";
    }

    private static final class Traffic {
        float x;
        float y;
        float speed;
        int type;
        boolean police;
        boolean boss;
        boolean passed;
    }

    private static final class Coin {
        float x;
        float y;
    }
}
