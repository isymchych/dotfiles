user_pref("layout.frame_rate", -1); // for 60hz monitor
// user_pref("layout.frame_rate", 120);

// do not detach tabs with drag-n-drop
user_pref("browser.tabs.allowTabDetach", false);

user_pref("browser.tabs.drawInTitlebar", false);

// make tabs take less space
user_pref("browser.uidensity", 1);

// Disable Ctrl-q to close FF
user_pref("browser.quitShortcut.disabled", true);

// https://wiki.archlinux.org/index.php/Firefox#Right_mouse_button_instantly_clicks_the_first_option_in_window_managers
user_pref("ui.context_menus.after_mouseup", true);

// disable Pocket
user_pref("extensions.pocket.enabled", false);


// disable video autoplay
user_pref("media.autoplay.default", 5);


// force enable webrender https://wiki.archlinux.org/index.php/Firefox/Tweaks#Enable_WebRender_compositor
user_pref("gfx.webrender.all", true);

// enable hardware video acceleration https://wiki.archlinux.org/index.php/Firefox#Hardware_video_acceleration
user_pref("media.ffmpeg.vaapi-drm-display.enabled", true);
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.ffvpx.enabled", false);
// user_pref("media.rdd-vpx.enabled", false);
// user_pref("media.av1.enabled", false); // youtube crashes as of FF82

// disable kinetic scroll
user_pref("apz.gtk.kinetic_scroll.enabled", false);

// lower touch scroll sensitivity
user_pref("mousewheel.default.delta_multiplier_y", 55);

// better privacy
user_pref("privacy.trackingprotection.enabled", true);
user_pref("media.peerconnection.ice.default_address_only", true);
user_pref("toolkit.telemetry.enabled", false);
user_pref("privacy.donottrackheader.enabled", true);
user_pref("geo.enabled", false);
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);

// open "search in google" tab in background
user_pref("browser.search.context.loadInBackground", true);
