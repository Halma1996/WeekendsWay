package org.weekendsway;

import android.content.Context;
import android.content.Intent;
import android.location.Address;
import android.location.Geocoder;
import android.net.Uri;
import android.os.Build;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Future;
import java.util.concurrent.SynchronousQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicReference;

public final class TaxiBridge {
    private TaxiBridge() {}
    private static final int TIMEOUT_SECONDS = 15;
    // Older Android providers can block even after cancellation. Bound them to
    // one daemon worker and no queue, rather than leaking a thread per retry.
    private static final ThreadPoolExecutor LEGACY = new ThreadPoolExecutor(
        0, 1, 30, TimeUnit.SECONDS, new SynchronousQueue<Runnable>(), runnable -> {
            Thread thread = new Thread(runnable, "WeekendsWay-address");
            thread.setDaemon(true);
            return thread;
        });

    private static String failure(String reason) {
        try { return new JSONObject().put("error", reason).toString(); }
        catch (Exception ignored) { return "{\"error\":\"lookup\"}"; }
    }

    // Invoked only from a Qt worker. No API key, location permission, current
    // location lookup, contact access or persistence is needed.
    public static String resolve(Context context, String query) {
        if (context == null || query == null || query.trim().isEmpty()) return failure("lookup");
        if (!Geocoder.isPresent()) return failure("unavailable");
        try {
            Geocoder geocoder = new Geocoder(context.getApplicationContext(), Locale.getDefault());
            List<Address> addresses;
            if (Build.VERSION.SDK_INT >= 33) {
                CountDownLatch ready = new CountDownLatch(1);
                AtomicReference<List<Address>> found = new AtomicReference<>();
                AtomicReference<String> error = new AtomicReference<>();
                geocoder.getFromLocationName(query, 5, new Geocoder.GeocodeListener() {
                    @Override public void onGeocode(List<Address> results) {
                        found.set(results);
                        ready.countDown();
                    }
                    @Override public void onError(String ignored) {
                        error.set("lookup");
                        ready.countDown();
                    }
                });
                if (!ready.await(TIMEOUT_SECONDS, TimeUnit.SECONDS)) return failure("timeout");
                if (error.get() != null) return failure("lookup");
                addresses = found.get();
            } else {
                Future<List<Address>> lookup = LEGACY.submit(() -> legacyLookup(geocoder, query));
                try { addresses = lookup.get(TIMEOUT_SECONDS, TimeUnit.SECONDS); }
                catch (TimeoutException timeout) { lookup.cancel(true); return failure("timeout"); }
            }
            JSONArray points = new JSONArray();
            if (addresses != null) for (Address address : addresses) {
                if (address == null || !address.hasLatitude() || !address.hasLongitude()) continue;
                String label = address.getMaxAddressLineIndex() >= 0 ? address.getAddressLine(0) : null;
                if (label == null || label.trim().isEmpty()) continue;
                double latitude = address.getLatitude(), longitude = address.getLongitude();
                if (!Double.isFinite(latitude) || !Double.isFinite(longitude)
                        || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) continue;
                points.put(new JSONObject().put("label", label).put("latitude", latitude).put("longitude", longitude));
            }
            return new JSONObject().put("points", points).toString();
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            return failure("timeout");
        } catch (Exception unavailable) {
            // Do not log the user's saved address or provider diagnostics.
            return failure("lookup");
        }
    }

    @SuppressWarnings("deprecation")
    private static List<Address> legacyLookup(Geocoder geocoder, String query) throws Exception {
        return geocoder.getFromLocationName(query, 5);
    }

    public static boolean open(Context context, String url) {
        if (context == null || url == null) return false;
        try {
            Uri uri = Uri.parse(url);
            if (!"https".equals(uri.getScheme())
                    || !"3.redirect.appmetrica.yandex.com".equals(uri.getHost())
                    || !"/route".equals(uri.getPath())
                    || !"1178268795219780156".equals(uri.getQueryParameter("appmetrica_tracking_id"))) return false;
            double latitude = Double.parseDouble(uri.getQueryParameter("end-lat"));
            double longitude = Double.parseDouble(uri.getQueryParameter("end-lon"));
            if (!Double.isFinite(latitude) || !Double.isFinite(longitude)
                    || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) return false;
            Intent target = new Intent(Intent.ACTION_VIEW, uri).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            try {
                // Starting an activity does not require a broad package query.
                // Prefer Go directly when it handles its official HTTPS link.
                context.startActivity(new Intent(target).setPackage("ru.yandex.taxi"));
            } catch (Exception unavailable) {
                // Official AppMetrica redirect opens Go or its store page. The
                // destination stays in the URL; no alternative taxi is chosen.
                context.startActivity(target);
            }
            return true;
        } catch (Exception unavailable) {
            return false;
        }
    }
}
