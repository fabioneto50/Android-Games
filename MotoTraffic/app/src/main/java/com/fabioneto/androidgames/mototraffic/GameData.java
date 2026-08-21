package com.fabioneto.androidgames.mototraffic;

final class GameData {
    static final String[] BIKES = {
            "Street 750", "RR 1000", "Adventure 1100", "Naked 900",
            "Hyper 1300", "CAFÉ 650", "E-R 1200"
    };

    static final int[] BIKE_COST = {0, 6500, 8500, 10500, 14500, 12000, 18000};
    static final float[] BIKE_SPEED = {1.00f, 1.13f, 1.07f, 1.10f, 1.18f, 1.04f, 1.16f};
    static final float[] BIKE_HANDLING = {1.00f, 1.03f, 1.12f, 1.16f, 1.00f, 1.14f, 1.20f};
    static final float[] BIKE_ARMOR = {1.00f, .93f, 1.23f, 1.03f, .95f, 1.05f, 1.11f};

    static final String[] MAPS = {"Cidade", "Costa", "Serra", "Noite"};

    static final String[] CAREER = {
            "Arranque Urbano", "Hora de Ponta", "Tempestade Urbana",
            "Rota Atlântica", "Mar de Nevoeiro", "Linha Vermelha",
            "Curvas Altas", "Caça na Serra", "Descida Sem Medo",
            "Blackout", "Bloqueio Total", "Most Wanted"
    };

    static final String[] EVENTS = {"Coin Rush", "Obras", "Speed Zone", "Blackout", "Bloqueio"};

    static int mapForStage(int stage) {
        if (stage < 0) return 0;
        return Math.min(3, stage / 3);
    }

    static int targetForStage(int stage) {
        return 2600 + Math.max(0, stage) * 700;
    }

    private GameData() {}
}
