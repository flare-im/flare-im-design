package com.flare.im.ui

import android.annotation.SuppressLint
import android.content.Context
import android.webkit.CookieManager
import android.webkit.WebStorage
import android.webkit.WebView
import androidx.webkit.ProfileStore
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import java.security.MessageDigest

/*
 * What a bundle WebView may keep between loads (design 8.5: no cookies; storage unavailable or cleared with the
 * session). `domStorageEnabled = false` turns off only localStorage and sessionStorage: IndexedDB, Cache Storage and
 * first-party cookies stay on in Android WebView, and the bundle origin is stable per tenant and plugin. So:
 *
 * - With `MULTI_PROFILE`, every bundle WebView runs in a profile of the signed-in user ([FlarePluginBundleStorage.signedIn]),
 *   never in the app's default profile, and that profile refuses cookies. Sign-out and a user switch delete it.
 * - Without it, bundle WebViews refuse cookies while one is open, and what an origin wrote is deleted from the default
 *   profile.
 * - Either way, when the last page of an origin closes, that origin's storage and cookies are deleted, and anything a
 *   killed process left behind is deleted before the next bundle opens.
 */

/** One bundle WebView's hold on its storage: its origin, the profile it runs in (null: the default profile), its paths. */
internal data class PluginBundleStorageLease(val origin: String, val profile: String?, val cookiePaths: List<String>)

/** The profile of [scope] (a signed-in user): a stable name that does not reveal the scope. */
internal fun pluginBundleProfileName(scope: String?): String {
    val key = scope?.takeIf { it.isNotBlank() } ?: return "$PLUGIN_BUNDLE_PROFILE_PREFIX-anonymous"
    val digest = MessageDigest.getInstance("SHA-256").digest(key.toByteArray(Charsets.UTF_8))
    return "$PLUGIN_BUNDLE_PROFILE_PREFIX-" + digest.take(16).joinToString("") { "%02x".format(it) }
}

internal const val PLUGIN_BUNDLE_PROFILE_PREFIX = "flare-plugin-bundle"

/** Cookie names in a `CookieManager.getCookie` answer (`a=1; b=2`). */
internal fun pluginBundleCookieNames(header: String?): List<String> =
    header.orEmpty().split(';').mapNotNull { pair ->
        pair.substringBefore('=').trim().takeIf { it.isNotEmpty() }
    }.distinct()

/** The `Set-Cookie` value that expires [name] at [path]. */
internal fun pluginBundleExpiredCookie(name: String, path: String): String =
    "$name=; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Path=$path; Secure"

/** Every path a page of this bundle could set a cookie for and read it back from: `/` and each listed file's folders. */
internal fun pluginBundleCookiePaths(files: Collection<String>): List<String> {
    val paths = linkedSetOf("/")
    files.forEach { file ->
        val segments = file.split('/').dropLast(1)
        for (end in 1..segments.size) {
            val dir = "/" + segments.take(end).joinToString("/")
            paths.add(dir)
            paths.add("$dir/")
        }
        paths.add("/$file")
    }
    return paths.toList()
}

/** Which bundle WebViews are open, so storage is deleted only once nothing uses it. Main thread only. */
internal class PluginBundleStorageLedger {
    private val open = HashMap<PluginBundleStorageLease, Int>()

    fun opened(lease: PluginBundleStorageLease) {
        open[lease] = (open[lease] ?: 0) + 1
    }

    /** True when [lease] was the last open page of its origin in its profile: delete that origin's storage now. */
    fun closed(lease: PluginBundleStorageLease): Boolean {
        val left = (open[lease] ?: return false) - 1
        if (left > 0) {
            open[lease] = left
        } else {
            open.remove(lease)
        }
        return open.keys.none { it.origin == lease.origin && it.profile == lease.profile }
    }

    fun isEmpty(): Boolean = open.isEmpty()

    /** Whether a page runs in [profile] (null: the default profile). */
    fun inUse(profile: String?): Boolean = open.keys.any { it.profile == profile }
}

/**
 * The storage of plugin bundle WebViews, per signed-in user. Hosts call [signedIn] once the user is known and
 * [signedOut] when the session ends (sign-out, expiry, a switch to another account). Main thread only.
 */
object FlarePluginBundleStorage {
    private const val PREFS = "flare.plugin_bundle_storage"
    private const val KEY_SCOPE = "scope"
    private const val KEY_ORIGINS = "origins"
    private const val KEY_STALE_PROFILES = "staleProfiles"

    private val ledger = PluginBundleStorageLedger()
    private var restoreAcceptCookie: Boolean? = null

    /** Whether this WebView keeps bundle storage in profiles of their own. */
    fun profilesSupported(): Boolean =
        runCatching { WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE) }.getOrDefault(false)

    /**
     * [scope] signed in: a stable key of the user (tenant, deployment and user id). Another user's bundle storage left
     * on this device is deleted first.
     */
    fun signedIn(context: Context, scope: String) {
        val prefs = prefs(context)
        val previous = prefs.getString(KEY_SCOPE, null)
        if (previous != null && previous != scope) forget(context, previous)
        prefs.edit().putString(KEY_SCOPE, scope).apply()
        deleteStaleProfiles(context)
    }

    /** The session ended: everything bundles kept for this user goes, the open pages' storage included. */
    fun signedOut(context: Context) {
        val prefs = prefs(context)
        val scope = prefs.getString(KEY_SCOPE, null)
        forget(context, scope)
        prefs.edit().remove(KEY_SCOPE).apply()
    }

    /**
     * Puts a new bundle [view] in the current user's profile and holds its storage. Call it first, before anything
     * else touches [view]. The answer goes back to [release] when the view is destroyed.
     */
    @SuppressLint("RequiresFeature")
    internal fun attach(view: WebView, origin: String, files: Collection<String>): PluginBundleStorageLease {
        val context = view.context.applicationContext
        if (ledger.isEmpty()) wipeLeftovers(context)
        val profile = if (profilesSupported()) {
            val name = pluginBundleProfileName(prefs(context).getString(KEY_SCOPE, null))
            runCatching {
                // A profile of its own refuses cookies outright (design 8.5: no cookies), which leaves the app's
                // default profile alone; what a bundle keeps goes through the bridge's storage.
                ProfileStore.getInstance().getOrCreateProfile(name).cookieManager.setAcceptCookie(false)
                WebViewCompat.setProfile(view, name)
                name
            }.getOrNull()
        } else {
            null
        }
        val lease = PluginBundleStorageLease(origin.trimEnd('/'), profile, pluginBundleCookiePaths(files))
        if (profile == null) {
            remember(context, lease.origin)
            // The default profile is the app's: no bundle cookies in it while a page is open.
            val cookies = CookieManager.getInstance()
            if (restoreAcceptCookie == null) restoreAcceptCookie = cookies.acceptCookie()
            cookies.setAcceptCookie(false)
        }
        ledger.opened(lease)
        return lease
    }

    /** The view of [lease] was destroyed: its origin's storage goes once no other page of that origin is open. */
    internal fun release(context: Context, lease: PluginBundleStorageLease) {
        val app = context.applicationContext
        if (ledger.closed(lease)) wipeOrigin(app, lease)
        if (lease.profile == null && !ledger.inUse(null)) {
            restoreAcceptCookie?.let { CookieManager.getInstance().setAcceptCookie(it) }
            restoreAcceptCookie = null
        }
        if (lease.profile != null && !ledger.inUse(lease.profile)) {
            if (lease.profile != pluginBundleProfileName(prefs(app).getString(KEY_SCOPE, null))) {
                markStale(app, lease.profile)
            }
            deleteStaleProfiles(app)
        }
    }

    /** Deletes the bundle storage of [scope]: its profile (or, if a page still runs in it, the profile's data). */
    @SuppressLint("RequiresFeature")
    private fun forget(context: Context, scope: String?) {
        if (profilesSupported()) {
            val name = pluginBundleProfileName(scope)
            runCatching {
                ProfileStore.getInstance().getProfile(name)?.let { profile ->
                    profile.webStorage.deleteAllData()
                    profile.cookieManager.removeAllCookies(null)
                }
            }
            markStale(context, name)
            deleteStaleProfiles(context)
        }
        wipeRemembered(context, skipOpen = false)
    }

    /** Before the first page opens: what a killed process left in the default profile or in the current profile. */
    @SuppressLint("RequiresFeature")
    private fun wipeLeftovers(context: Context) {
        wipeRemembered(context, skipOpen = true)
        if (!profilesSupported()) return
        deleteStaleProfiles(context)
        val name = pluginBundleProfileName(prefs(context).getString(KEY_SCOPE, null))
        runCatching {
            ProfileStore.getInstance().getProfile(name)?.let { profile ->
                profile.webStorage.deleteAllData()
                profile.cookieManager.removeAllCookies(null)
            }
        }
    }

    @SuppressLint("RequiresFeature")
    private fun wipeOrigin(context: Context, lease: PluginBundleStorageLease) {
        runCatching {
            val profile = lease.profile?.let { ProfileStore.getInstance().getProfile(it) }
            val storage = profile?.webStorage ?: WebStorage.getInstance()
            val cookies = profile?.cookieManager ?: CookieManager.getInstance()
            storage.deleteOrigin(lease.origin)
            expireCookies(cookies, lease.origin, lease.cookiePaths)
        }
        if (lease.profile == null) forgetOrigin(context, lease.origin)
    }

    private fun expireCookies(cookies: CookieManager, origin: String, paths: List<String>) {
        paths.forEach { path ->
            val url = origin + path
            pluginBundleCookieNames(cookies.getCookie(url)).forEach { name ->
                cookies.setCookie(url, pluginBundleExpiredCookie(name, path))
            }
        }
        cookies.flush()
    }

    /** Default-profile origins bundles may have written to; [skipOpen] keeps those a page uses right now. */
    private fun wipeRemembered(context: Context, skipOpen: Boolean) {
        val origins = prefs(context).getStringSet(KEY_ORIGINS, emptySet()).orEmpty().toSet()
        if (origins.isEmpty()) return
        if (skipOpen && ledger.inUse(null)) return
        val cookies = CookieManager.getInstance()
        origins.forEach { origin ->
            runCatching {
                WebStorage.getInstance().deleteOrigin(origin)
                expireCookies(cookies, origin, listOf("/"))
            }
        }
        prefs(context).edit().remove(KEY_ORIGINS).apply()
    }

    @SuppressLint("RequiresFeature")
    private fun deleteStaleProfiles(context: Context) {
        val prefs = prefs(context)
        val stale = prefs.getStringSet(KEY_STALE_PROFILES, emptySet()).orEmpty().toMutableSet()
        if (stale.isEmpty() || !profilesSupported()) return
        val current = pluginBundleProfileName(prefs.getString(KEY_SCOPE, null))
        val store = runCatching { ProfileStore.getInstance() }.getOrNull() ?: return
        stale.toList().forEach { name ->
            if (name == current && prefs.getString(KEY_SCOPE, null) != null) {
                // Signed in again as the same user: the profile is theirs again (its data was deleted on sign-out).
                stale.remove(name)
                return@forEach
            }
            if (ledger.inUse(name)) return@forEach
            // Deleting a profile a WebView still uses throws; it stays stale and goes next time.
            val gone = runCatching { store.deleteProfile(name); true }.getOrDefault(false)
            if (gone) stale.remove(name)
        }
        prefs.edit().putStringSet(KEY_STALE_PROFILES, stale).apply()
    }

    private fun markStale(context: Context, profile: String) {
        val prefs = prefs(context)
        val stale = prefs.getStringSet(KEY_STALE_PROFILES, emptySet()).orEmpty().toMutableSet()
        if (stale.add(profile)) prefs.edit().putStringSet(KEY_STALE_PROFILES, stale).apply()
    }

    private fun remember(context: Context, origin: String) {
        val prefs = prefs(context)
        val origins = prefs.getStringSet(KEY_ORIGINS, emptySet()).orEmpty().toMutableSet()
        // Written now, not at close: a killed process still leaves the origin to delete next time.
        if (origins.add(origin)) prefs.edit().putStringSet(KEY_ORIGINS, origins).commit()
    }

    private fun forgetOrigin(context: Context, origin: String) {
        val prefs = prefs(context)
        val origins = prefs.getStringSet(KEY_ORIGINS, emptySet()).orEmpty().toMutableSet()
        if (origins.remove(origin)) prefs.edit().putStringSet(KEY_ORIGINS, origins).apply()
    }

    private fun prefs(context: Context) = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
