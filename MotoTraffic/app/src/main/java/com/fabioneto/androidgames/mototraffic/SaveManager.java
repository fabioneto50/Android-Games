package com.fabioneto.androidgames.mototraffic;

import android.content.Context;
import android.content.SharedPreferences;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Locale;

final class SaveManager {
    private static final int BIKE_COUNT = 7;
    private static final int STAGE_COUNT = 12;
    private static final int UPGRADE_COUNT = 4;

    private final SharedPreferences prefs;

    int coins;
    int xp;
    int seasonPoints;
    int selectedBike;
    int bestScore;
    int totalRuns;
    int totalCoins;
    final int[] stars = new int[STAGE_COUNT];
    final int[][] upgrades = new int[BIKE_COUNT][UPGRADE_COUNT];
    final boolean[] unlocked = new boolean[BIKE_COUNT];
    boolean premium;

    SaveManager(Context context) {
        prefs = context.getSharedPreferences("moto_traffic_reborn_save_1", Context.MODE_PRIVATE);
        load();
    }

    private int safeInt(String key, int fallback, int min, int max) {
        int value = prefs.getInt(key, fallback);
        if (value < min || value > max) return fallback;
        return value;
    }

    private void load() {
        coins = safeInt("coins", 12500, 0, 10_000_000);
        xp = safeInt("xp", 0, 0, 50_000_000);
        seasonPoints = safeInt("season", 0, 0, 10_000_000);
        selectedBike = safeInt("bike", 0, 0, BIKE_COUNT - 1);
        bestScore = safeInt("best", 0, 0, 100_000_000);
        totalRuns = safeInt("runs", 0, 0, 10_000_000);
        totalCoins = safeInt("totalCoins", 0, 0, 100_000_000);
        premium = prefs.getBoolean("premium", true);

        for (int bike = 0; bike < BIKE_COUNT; bike++) {
            unlocked[bike] = prefs.getBoolean("unlocked_" + bike, bike == 0 || (premium && bike == 5));
            for (int slot = 0; slot < UPGRADE_COUNT; slot++) {
                upgrades[bike][slot] = safeInt("up_" + bike + "_" + slot, 0, 0, 5);
            }
        }
        unlocked[0] = true;
        if (!unlocked[selectedBike]) selectedBike = 0;

        for (int stage = 0; stage < STAGE_COUNT; stage++) {
            stars[stage] = safeInt("stars_" + stage, 0, 0, 3);
        }
    }

    void save() {
        SharedPreferences.Editor editor = prefs.edit()
                .putInt("coins", coins)
                .putInt("xp", xp)
                .putInt("season", seasonPoints)
                .putInt("bike", selectedBike)
                .putInt("best", bestScore)
                .putInt("runs", totalRuns)
                .putInt("totalCoins", totalCoins)
                .putBoolean("premium", premium);

        for (int bike = 0; bike < BIKE_COUNT; bike++) {
            editor.putBoolean("unlocked_" + bike, unlocked[bike]);
            for (int slot = 0; slot < UPGRADE_COUNT; slot++) {
                editor.putInt("up_" + bike + "_" + slot, upgrades[bike][slot]);
            }
        }
        for (int stage = 0; stage < STAGE_COUNT; stage++) {
            editor.putInt("stars_" + stage, stars[stage]);
        }
        editor.apply();
    }

    int level() {
        return Math.min(50, 1 + xp / 1500);
    }

    int totalStars() {
        int total = 0;
        for (int value : stars) total += value;
        return total;
    }

    boolean canPlayStage(int stage) {
        return stage == 0 || (stage > 0 && stage < STAGE_COUNT && stars[stage - 1] > 0);
    }

    boolean buyOrSelectBike(int bike) {
        if (bike < 0 || bike >= BIKE_COUNT) return false;
        if (unlocked[bike]) {
            selectedBike = bike;
            save();
            return true;
        }
        int cost = GameData.BIKE_COST[bike];
        if (coins < cost) return false;
        coins -= cost;
        unlocked[bike] = true;
        selectedBike = bike;
        save();
        return true;
    }

    int upgradeCost(int bike, int slot) {
        if (bike < 0 || bike >= BIKE_COUNT || slot < 0 || slot >= UPGRADE_COUNT) return 0;
        int level = upgrades[bike][slot];
        if (level >= 5) return 0;
        return 900 + level * 900 + slot * 250;
    }

    boolean upgrade(int bike, int slot) {
        if (bike < 0 || bike >= BIKE_COUNT || slot < 0 || slot >= UPGRADE_COUNT) return false;
        if (!unlocked[bike]) return false;
        int cost = upgradeCost(bike, slot);
        if (cost <= 0 || coins < cost) return false;
        coins -= cost;
        upgrades[bike][slot]++;
        save();
        return true;
    }

    int completeRun(int score, int earnedCoins, int stage, float health) {
        int bonus = premium ? Math.round(earnedCoins * 0.25f) : 0;
        int totalEarned = earnedCoins + bonus;
        coins += totalEarned;
        totalCoins += totalEarned;
        xp += Math.max(80, score / 18);
        seasonPoints += Math.max(4, score / 800);
        bestScore = Math.max(bestScore, score);
        totalRuns++;

        int starsEarned = 0;
        if (stage >= 0 && stage < STAGE_COUNT) {
            int target = GameData.targetForStage(stage);
            if (score >= target) starsEarned = 1;
            if (score >= Math.round(target * 1.35f)) starsEarned = 2;
            if (score >= Math.round(target * 1.70f) && health > 0f) starsEarned = 3;
            stars[stage] = Math.max(stars[stage], starsEarned);
        }
        save();
        return starsEarned;
    }

    String[] dailyChallenges() {
        String key = new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date());
        int seed = Math.abs(key.hashCode());
        return new String[] {
                "Percorre " + (4 + seed % 4) + " km numa corrida",
                "Apanha " + (10 + seed % 11) + " moedas",
                "Atinge Heat " + (65 + seed % 25) + "%"
        };
    }

    List<Integer> localLeaderboard() {
        ArrayList<Integer> list = new ArrayList<>();
        list.add(bestScore);
        list.add(Math.max(0, bestScore - 800));
        list.add(Math.max(0, bestScore - 1600));
        Collections.sort(list, Collections.reverseOrder());
        return list;
    }
}
