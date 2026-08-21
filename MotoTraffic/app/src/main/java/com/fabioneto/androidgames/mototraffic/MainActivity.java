package com.fabioneto.androidgames.mototraffic;

import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.TextView;

public final class MainActivity extends Activity {
    private static final String TAG = "MotoTraffic";
    private GameView gameView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        try {
            requestWindowFeature(Window.FEATURE_NO_TITLE);
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            enableImmersiveMode();
            gameView = new GameView(this);
            setContentView(gameView);
        } catch (Throwable error) {
            Log.e(TAG, "Fatal error during startup", error);
            showSafeErrorScreen(error);
        }
    }

    private void enableImmersiveMode() {
        View decor = getWindow().getDecorView();
        decor.setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
    }

    private void showSafeErrorScreen(Throwable error) {
        TextView text = new TextView(this);
        text.setBackgroundColor(Color.rgb(7, 11, 18));
        text.setTextColor(Color.WHITE);
        text.setPadding(32, 64, 32, 32);
        text.setTextSize(16f);
        String detail = error.getClass().getSimpleName();
        if (error.getMessage() != null && !error.getMessage().isEmpty()) {
            detail += ": " + error.getMessage();
        }
        text.setText("MOTO TRAFFIC\n\nA aplicação abriu em modo de diagnóstico.\n\nErro: " + detail
                + "\n\nEnvia uma captura deste ecrã para corrigirmos diretamente.");
        setContentView(text);
    }

    @Override
    protected void onResume() {
        super.onResume();
        enableImmersiveMode();
        if (gameView != null) gameView.setPaused(false);
    }

    @Override
    protected void onPause() {
        if (gameView != null) gameView.setPaused(true);
        super.onPause();
    }
}
