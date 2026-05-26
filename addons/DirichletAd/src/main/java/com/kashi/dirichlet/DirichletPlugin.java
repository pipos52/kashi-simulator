package com.kashi.dirichlet;

import android.app.Activity;
import android.util.Log;

import com.tapsdk.tapad.AdRequest;
import com.tapsdk.tapad.TapAdConfig;
import com.tapsdk.tapad.TapAdManager;
import com.tapsdk.tapad.TapAdNative;
import com.tapsdk.tapad.TapAdSdk;
import com.tapsdk.tapad.TapRewardVideoAd;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Dirichlet Ad SDK Godot 4.2+ Android Plugin（适配 SDK 4.2.4.8）
 */
public class DirichletPlugin extends GodotPlugin {
    private static final String TAG = "DirichletPlugin";

    private TapAdNative tapAdNative;
    private TapRewardVideoAd currentAd;
    private long mediaId = 0;
    private String mediaKey = "";
    private long testSpaceId = 0;
    private boolean isLoading = false;
    private boolean isInitialized = false;
    private boolean isInitializing = false;
    private boolean rewardGranted = false;
    private String lastError = "";

    public DirichletPlugin(Godot godot) {
        super(godot);
        Log.i(TAG, "DirichletPlugin created. godot=" + godot);
    }

    @Override
    public String getPluginName() {
        return "DirichletAd";
    }

    @Override
    public List<String> getPluginMethods() {
        // 必须显式注册公开方法，否则 Godot 引擎找不到它们
        return Arrays.asList(
            "initialize",
            "loadRewardVideoAd",
            "setTestSpaceId",
            "getDiagnosticInfo",
            "getLastError",
            "isInitialized",
            "reset"
        );
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(
            new SignalInfo("reward_ready"),
            new SignalInfo("reward_error", String.class),
            new SignalInfo("reward_closed")
        ));
    }

    @Override
    public void onMainPause() {
        Log.d(TAG, "onMainPause called");
    }
    @Override
    public void onMainResume() {
        Log.d(TAG, "onMainResume called");
    }

    // ── 广告加载回调 ──
    private final TapAdNative.RewardVideoAdListener loadListener =
            new TapAdNative.RewardVideoAdListener() {
        @Override
        public void onRewardVideoAdLoad(TapRewardVideoAd ad) {
            Log.i(TAG, "onRewardVideoAdLoad: ad=" + ad);
            isLoading = false;
            currentAd = ad;
            if (currentAd == null) {
                Log.e(TAG, "Loaded ad is null");
                emitSignal("reward_error", "Loaded ad is null");
                return;
            }
            // 先发射 reward_ready 信号，通知 Godot 层广告已加载成功
            Log.i(TAG, "Emitting reward_ready signal...");
            emitSignal("reward_ready");
            // 然后再设置监听器并自动播放
            Activity act = getActivity();
            if (act == null) {
                Log.e(TAG, "Activity is null, cannot show ad");
                emitSignal("reward_error", "Activity null");
                return;
            }
            try {
                Log.i(TAG, "Setting interaction listener and showing ad...");
                currentAd.setRewardAdInteractionListener(interactionListener);
                currentAd.showRewardVideoAd(act);
                Log.i(TAG, "showRewardVideoAd returned OK");
            } catch (Exception e) {
                Log.e(TAG, "Show exception: " + e.getMessage(), e);
                emitSignal("reward_error", "Show failed: " + e.getMessage());
            }
        }

        @Override
        public void onRewardVideoCached(TapRewardVideoAd ad) {
            Log.d(TAG, "onRewardVideoCached, ad=" + ad);
        }

        @Override
        public void onError(int code, String message) {
            isLoading = false;
            lastError = code + ":" + message;
            Log.e(TAG, "Ad load failed code=" + code + " msg=" + message);
            emitSignal("reward_error", lastError);
        }
    };

    // ── 广告交互回调 ──
    private final TapRewardVideoAd.RewardAdInteractionListener interactionListener =
            new TapRewardVideoAd.RewardAdInteractionListener() {
        @Override
        public void onAdShow(TapRewardVideoAd ad) {
            Log.d(TAG, "onAdShow called, ad=" + ad);
        }

        @Override
        public void onAdClose(TapRewardVideoAd ad) {
            Log.d(TAG, "onAdClose, ad=" + ad + " rewardGranted=" + rewardGranted);
            emitSignal("reward_closed");
            if (rewardGranted) {
                Log.i(TAG, "Reward granted! Emitting reward_ready");
                rewardGranted = false;
                emitSignal("reward_ready");
            }
        }

        @Override
        public void onVideoComplete(TapRewardVideoAd ad) {
            Log.d(TAG, "onVideoComplete, ad=" + ad);
        }

        @Override
        public void onVideoError(TapRewardVideoAd ad) {
            Log.e(TAG, "onVideoError, ad=" + ad);
            emitSignal("reward_error", "Video play error");
        }

        @Override
        public void onRewardVerify(TapRewardVideoAd ad, boolean passed,
                                    int amount, String name,
                                    int errorCode, String errorMsg) {
            Log.d(TAG, "onRewardVerify: passed=" + passed
                    + " amount=" + amount + " name=" + name
                    + " errorCode=" + errorCode + " errorMsg=" + errorMsg);
            if (passed) {
                Log.i(TAG, "Reward verified! Setting rewardGranted=true");
                rewardGranted = true;
            }
        }

        @Override
        public void onSkippedVideo(TapRewardVideoAd ad) {
            Log.d(TAG, "onSkippedVideo, ad=" + ad);
        }

        @Override
        public void onAdClick(TapRewardVideoAd ad) {
            Log.d(TAG, "onAdClick, ad=" + ad);
        }

        @Override
        public void onAdValidShow(TapRewardVideoAd ad) {
            Log.d(TAG, "onAdValidShow, ad=" + ad);
        }
    };

    // ── 公开方法（供 GDScript 调用） ──

    @UsedByGodot
    public void initialize(long mediaId, String mediaKey) {
        Log.i(TAG, "initialize() called: mediaId=" + mediaId + " mediaKey=" + mediaKey
                + " isInitializing=" + isInitializing);
        this.mediaId = mediaId;
        this.mediaKey = mediaKey;
        lastError = "";
        if (isInitializing) {
            Log.w(TAG, "Already initializing, skip");
            return;
        }
        if (isInitialized) {
            Log.w(TAG, "Already initialized, skip");
            return;
        }
        isInitializing = true;

        // Get Activity from Godot plugin base class
        Activity act = getActivity();
        if (act == null) {
            lastError = "Activity is null";
            isInitializing = false;
            Log.e(TAG, "BRANCH-A: getActivity() returned NULL");
            return;
        }
        Log.i(TAG, "BRANCH-B: getActivity() = " + act.getClass().getSimpleName());

        try {
            TapAdConfig.Builder builder = new TapAdConfig.Builder();
            builder.withMediaId(mediaId);
            builder.withMediaKey(mediaKey);
            builder.withMediaName("Game");
            builder.enableDebug(true);
            TapAdConfig config = builder.build();

            Log.i(TAG, "BRANCH-C: calling TapAdSdk.init()...");
            TapAdSdk.init(act, config);
            Log.i(TAG, "BRANCH-D: TapAdSdk.init() returned");

            tapAdNative = TapAdManager.get().createAdNative(act);
            Log.i(TAG, "BRANCH-E: createAdNative = " + tapAdNative);

            isInitialized = true;
            isInitializing = false;
            Log.i(TAG, "BRANCH-F: initialize SUCCESS");
        } catch (Throwable e) {
            lastError = e.getClass().getSimpleName() + ": " + e.getMessage();
            isInitializing = false;
            Log.e(TAG, "BRANCH-ERR: " + lastError, e);
        }
    }

    @UsedByGodot
    public void setTestSpaceId(long spaceId) {
        this.testSpaceId = spaceId;
        Log.i(TAG, "setTestSpaceId() called: testSpaceId=" + spaceId);
    }

    @UsedByGodot
    public void loadRewardVideoAd(long spaceId) {
        long actualSpaceId = (testSpaceId > 0) ? testSpaceId : spaceId;
        Log.i(TAG, "loadRewardVideoAd() called: spaceId=" + spaceId
                + " testSpaceId=" + testSpaceId
                + " actualSpaceId=" + actualSpaceId
                + " tapAdNative=" + tapAdNative
                + " isLoading=" + isLoading);

        if (tapAdNative == null) {
            lastError = "Not initialized";
            Log.e(TAG, "BRANCH-E: tapAdNative is null, aborting load");
            emitSignal("reward_error", lastError);
            return;
        }
        if (isLoading) {
            Log.w(TAG, "Ad already loading, resetting flag");
            isLoading = false;
        }
        isLoading = true;
        rewardGranted = false;
        lastError = "";
        try {
            String userId = UUID.randomUUID().toString().replace("-", "").substring(0, 16);
            AdRequest request = new AdRequest.Builder()
                    .withSpaceId(actualSpaceId)
                    .withRewardName("金币")
                    .withRewardAmount(100)
                    .withUserId(userId)
                    .withExtra1("TestPluginTesnewt_auto")
                    .build();
            Log.i(TAG, "Calling loadRewardVideoAd with request...");
            tapAdNative.loadRewardVideoAd(request, loadListener);
            Log.i(TAG, "loadRewardVideoAd returned OK");
        } catch (Exception e) {
            isLoading = false;
            lastError = "Load: " + e.getMessage();
            Log.e(TAG, "BRANCH-F: Load exception: " + e.getMessage(), e);
            emitSignal("reward_error", lastError);
        }
    }

    // ── 诊断方法 ──

    /** 检查 SDK 是否已初始化成功 */
    @UsedByGodot
    public boolean isInitialized() {
        Log.d(TAG, "isInitialized() called, returning: " + isInitialized);
        return isInitialized;
    }

    /** 获取最后一次错误信息 */
    @UsedByGodot
    public String getLastError() {
        Log.d(TAG, "getLastError() called, returning: " + lastError);
        return lastError;
    }

    /** 重置广告状态（卡住时调用） */
    @UsedByGodot
    public void reset() {
        isLoading = false;
        rewardGranted = false;
        lastError = "";
        testSpaceId = 0;
        Log.i(TAG, "Plugin state reset");
    }

    @UsedByGodot
    public boolean isAdLoading() {
        Log.d(TAG, "isAdLoading() called, returning: " + isLoading);
        return isLoading;
    }

    /** 获取诊断状态（JSON 字符串） */
    @UsedByGodot
    public String getDiagnosticInfo() {
        String info = "{"
            + "\"initialized\":" + isInitialized + ","
            + "\"initializing\":" + isInitializing + ","
            + "\"nativeReady\":" + (tapAdNative != null) + ","
            + "\"isLoading\":" + isLoading + ","
            + "\"lastError\":\"" + escape(lastError) + "\","
            + "\"mediaId\":" + mediaId + ""
            + "}";
        Log.d(TAG, "getDiagnosticInfo() called, returning: " + info);
        return info;
    }

    private String escape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}