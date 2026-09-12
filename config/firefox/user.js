// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  🔥 ASH DOTFILES v5.0 OMEGA — FIREFOX USER.JS ULTRA                        ║
// ║  🦊 Privacy • Performance • Security • Aesthetics                           ║
// ║  📚 Based on: arkenfox user.js + custom ASH optimizations                  ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  🚀  STARTUP & HOME
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Disable default browser check
user_pref("browser.shell.checkDefaultBrowser",              false);
// Don't show What's New on startup
user_pref("browser.startup.homepage_override.mstone",       "ignore");
// Blank new tab page (no tiles, no ads)
user_pref("browser.newtabpage.enabled",                     false);
user_pref("browser.newtabpage.activity-stream.enabled",     false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.telemetry",   false);
user_pref("browser.newtabpage.activity-stream.feeds.snippets", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.visited", false);
user_pref("startup.homepage_welcome_url",                   "");
user_pref("startup.homepage_welcome_url.additional",        "");
user_pref("startup.homepage_override_url",                  "");

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  🎨  UI & APPEARANCE — ASH THEME INTEGRATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Allow custom userChrome & userContent
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
// Enable SVG context properties (needed for icon theming)
user_pref("svg.context-properties.content.enabled",         true);
// Enable CSS color-mix() & oklch() in chrome
user_pref("layout.css.color-mix.enabled",                   true);
user_pref("layout.css.oklch.enabled",                       true);
// Enable :has() CSS selector
user_pref("layout.css.has-selector.enabled",                true);
// Enable CSS nesting
user_pref("layout.css.nesting.enabled",                     true);
// Enable blur filters in chrome (glassmorphism)
user_pref("layout.css.backdrop-filter.enabled",             true);
// Enable CSS @layer
user_pref("layout.css.cascade-layers.enabled",              true);
// Enable CSS container queries
user_pref("layout.css.container-queries.enabled",           true);
// Hardware acceleration
user_pref("gfx.webrender.all",                              true);
user_pref("gfx.webrender.enabled",                          true);
user_pref("gfx.webrender.compositor",                       true);
user_pref("gfx.webrender.compositor.force-enabled",         true);
user_pref("media.hardware-video-decoding.enabled",          true);
user_pref("media.hardware-video-decoding.force-enabled",    true);
// System theme integration
user_pref("widget.use-xdg-desktop-portal",                  true);
user_pref("widget.use-xdg-desktop-portal.mime-handler",     1);
user_pref("widget.use-xdg-desktop-portal.file-picker",      1);
// Dark color scheme preference
user_pref("ui.systemUsesDarkTheme",                         1);
user_pref("layout.css.prefers-color-scheme.content-override", 0);
// Smooth scrolling
user_pref("general.smoothScroll",                           true);
user_pref("general.smoothScroll.msdPhysics.enabled",        true);
user_pref("general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMSec", 12);
user_pref("general.smoothScroll.msdPhysics.deceleration",   1250);
user_pref("general.smoothScroll.msdPhysics.motionBeginSpringConstant", 600);
user_pref("general.smoothScroll.msdPhysics.regularSpringConstant", 650);
user_pref("general.smoothScroll.msdPhysics.slowdownMinDeltaMSec", 12);
user_pref("general.smoothScroll.msdPhysics.slowdownSpringConstant", 250);
user_pref("general.smoothScroll.currentVelocityWeighting",  1.0);
user_pref("general.smoothScroll.stopDecelerationWeighting",  0.82);
user_pref("mousewheel.default.delta_multiplier_y",          300);
// Font rendering
user_pref("gfx.font_rendering.cleartype_params.cleartype_level", 100);
user_pref("gfx.font_rendering.cleartype_params.force_gdi_classic_for_families", "");
user_pref("gfx.font_rendering.cleartype_params.force_gdi_classic_max_size", 6);
user_pref("gfx.font_rendering.cleartype_params.pixel_structure", 1);
user_pref("gfx.font_rendering.cleartype_params.rendering_mode", 5);
user_pref("gfx.font_rendering.fontconfig.fontlist.enabled", true);
// Full-screen fade animation
user_pref("full-screen-api.transition-duration.enter",      "0 0");
user_pref("full-screen-api.transition-duration.leave",      "0 0");
user_pref("full-screen-api.warning.delay",                  -1);
user_pref("full-screen-api.warning.timeout",                0);
// Tab previews
user_pref("browser.ctrlTab.recentlyUsedOrder",              false);
// Show more tabs
user_pref("browser.tabs.tabMinWidth",                       76);
// Autohide download button
user_pref("browser.download.autohideButton",                true);
// Enable tab scroll
user_pref("browser.tabs.tabmanager.enabled",                true);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  🔒  PRIVACY — FINGERPRINTING RESISTANCE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Resist fingerprinting (lite mode — full breaks too many sites)
user_pref("privacy.resistFingerprinting",                   false);
user_pref("privacy.resistFingerprinting.block_mozAddonManager", true);
// Enhanced Tracking Protection — strict
user_pref("browser.contentblocking.category",               "strict");
user_pref("privacy.trackingprotection.enabled",             true);
user_pref("privacy.trackingprotection.pbmode.enabled",      true);
user_pref("privacy.trackingprotection.emailtracking.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
// Total Cookie Protection (partitioned cookies)
user_pref("network.cookie.cookieBehavior",                  5);
user_pref("network.cookie.cookieBehavior.pbmode",           5);
// Global Privacy Control
user_pref("privacy.globalprivacycontrol.enabled",           true);
user_pref("privacy.globalprivacycontrol.pbmode.enabled",    true);
// Do Not Track
user_pref("privacy.donottrackheader.enabled",               true);
// Disable hyperlink auditing
user_pref("browser.send_pings",                             false);
// Disable beacon API
user_pref("beacon.enabled",                                 false);
// Disable Battery API
user_pref("dom.battery.enabled",                            false);
// Disable gamepad API (fingerprinting)
user_pref("dom.gamepad.enabled",                            false);
// Disable VR (fingerprinting)
user_pref("dom.vr.enabled",                                 false);
// Disable Web Speech API
user_pref("media.webspeech.recognition.enable",             false);
user_pref("media.webspeech.synth.enabled",                  false);
// Disable sensor API
user_pref("device.sensors.enabled",                         false);
// Disable idle detection API
user_pref("dom.idle-observers-api.enabled",                 false);
// Disable clipboard events
user_pref("dom.event.clipboardevents.enabled",              false);
// Limit WebGL fingerprinting
user_pref("webgl.disabled",                                 false);
user_pref("webgl.renderer-string-override",                 " ");
user_pref("webgl.vendor-string-override",                   " ");
// Canvas fingerprinting protection
user_pref("privacy.partition.network_state.ocsp_cache",     true);
// Disable Web MIDI
user_pref("dom.webmidi.enabled",                            false);
// Disable Presentation API
user_pref("dom.presentation.enabled",                       false);
// Disable raw TCP socket API
user_pref("dom.mozTCPSocket.enabled",                       false);
// Disable Network Information API
user_pref("dom.netinfo.enabled",                            false);
// Disable telemetry origin trials
user_pref("dom.origin-trials.enabled",                      false);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  📡  TELEMETRY — ALL DISABLED
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

user_pref("toolkit.telemetry.unified",                      false);
user_pref("toolkit.telemetry.enabled",                      false);
user_pref("toolkit.telemetry.server",                       "data:,");
user_pref("toolkit.telemetry.archive.enabled",              false);
user_pref("toolkit.telemetry.newProfilePing.enabled",       false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled",   false);
user_pref("toolkit.telemetry.updatePing.enabled",           false);
user_pref("toolkit.telemetry.bhrPing.enabled",              false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled",    false);
user_pref("toolkit.telemetry.coverage.opt-out",             true);
user_pref("toolkit.coverage.opt-out",                       true);
user_pref("toolkit.coverage.endpoint.base",                 "");
user_pref("datareporting.healthreport.uploadEnabled",       false);
user_pref("datareporting.policy.dataSubmissionEnabled",     false);
user_pref("datareporting.sessions.current.clean",           true);
user_pref("browser.ping-centre.telemetry",                  false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.telemetry",   false);
user_pref("browser.newtabpage.activity-stream.telemetry.ut.events", false);
user_pref("browser.newtabpage.activity-stream.telemetry.structuredIngestion.endpoint", "");
// Crash reports
user_pref("breakpad.reportURL",                             "");
user_pref("browser.tabs.crashReporting.sendReport",         false);
user_pref("browser.crashReports.unsubmittedCheck.enabled",  false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);
// Studies
user_pref("app.shield.optoutstudies.enabled",               false);
user_pref("app.normandy.enabled",                           false);
user_pref("app.normandy.api_url",                           "");
// Experiments
user_pref("messaging-system.rsexperimentloader.enabled",    false);
// Captive portal detection
user_pref("captivedetect.canonicalURL",                     "");
user_pref("network.captive-portal-service.enabled",         false);
user_pref("network.connectivity-service.enabled",           false);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  🔐  SECURITY
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// HTTPS-Only mode
user_pref("dom.security.https_only_mode",                   true);
user_pref("dom.security.https_only_mode_pbm",               true);
user_pref("dom.security.https_only_mode.upgrade_local",     false);
user_pref("dom.security.https_first",                       true);
user_pref("dom.security.https_first_pbm",                   true);
// HSTS preload
user_pref("network.stricttransportsecurity.preloadlist",    true);
// XSS protection header
user_pref("security.xssfilter.enable",                      true);
// Block mixed content
user_pref("security.mixed_content.block_active_content",    true);
user_pref("security.mixed_content.block_display_content",   true);
user_pref("security.mixed_content.upgrade_display_content", true);
// Disable insecure passive content
user_pref("security.insecure_connection_text.enabled",      true);
user_pref("security.insecure_connection_text.pbmode.enabled", true);
// Disable SHA-1
user_pref("security.pki.sha1_enforcement_level",            1);
// TLS minimum version
user_pref("security.tls.version.min",                       3);
user_pref("security.tls.version.max",                       4);
user_pref("security.tls.enable_0rtt_data",                  false);
// Certificate pinning
user_pref("security.cert_pinning.enforcement_level",        2);
// CRLite certificate revocation
user_pref("security.remote_settings.crlite_filters.enabled", true);
user_pref("security.pki.crlite_mode",                       2);
// OCSP
user_pref("security.OCSP.enabled",                          1);
user_pref("security.OCSP.require",                          true);
// Block dangerous file types
user_pref("browser.download.forbid_open_with",              true);
// Safe browsing
user_pref("browser.safebrowsing.malware.enabled",           true);
user_pref("browser.safebrowsing.phishing.enabled",          true);
user_pref("browser.safebrowsing.blockedURIs.enabled",       true);
user_pref("browser.safebrowsing.downloads.enabled",         true);
user_pref("browser.safebrowsing.downloads.remote.block_dangerous", true);
user_pref("browser.safebrowsing.downloads.remote.block_dangerous_host", true);
user_pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", true);
user_pref("browser.safebrowsing.downloads.remote.block_uncommon", true);
// Disable JavaScript JIT (security, can break sites — optional)
// user_pref("javascript.options.ion",                      false);
// user_pref("javascript.options.baselinejit",              false);
// Content Security Policy
user_pref("security.csp.enable",                            true);
// Subresource integrity
user_pref("security.sri.enable",                            true);
// Iframe sandbox
user_pref("dom.iframe_sandbox_allow_top_navigation_by_user_activation", false);
// Disable SharedArrayBuffer (Spectre mitigation)
user_pref("javascript.options.shared_memory",               false);
// Disable WebAssembly (optional — breaks WASM sites)
// user_pref("javascript.options.wasm",                     false);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  🌍  NETWORK
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// DNS over HTTPS (DoH) — Cloudflare + Quad9 fallback
user_pref("network.trr.mode",                               2);
user_pref("network.trr.hostname",                           "dns.quad9.net");
user_pref("network.trr.bootstrapAddress",                   "9.9.9.9");
user_pref("network.trr.excluded-domains",                   "");
user_pref("network.trr.builtin-excluded-domains",           "localhost,local");
// Disable WebRTC IP leak
user_pref("media.peerconnection.enabled",                   true);
user_pref("media.peerconnection.ice.no_host",               true);
user_pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);
user_pref("media.peerconnection.ice.default_address_only",  true);
// HTTP/3 QUIC
user_pref("network.http.http3.enabled",                     true);
// Prefetch — disable for privacy
user_pref("network.prefetch-next",                          false);
user_pref("network.dns.disablePrefetch",                    true);
user_pref("network.dns.disablePrefetchFromHTTPS",           true);
user_pref("browser.urlbar.speculativeConnect.enabled",      false);
user_pref("network.preload",                                false);
user_pref("network.early-hints.enabled",                    false);
user_pref("network.early-hints.preconnect.enabled",         false);
// Speculative connections
user_pref("browser.places.speculativeConnect.enabled",      false);
// Proxy bypass protection
user_pref("network.proxy.socks_remote_dns",                 true);
user_pref("network.file.disable_unc_paths",                 true);
user_pref("network.gio.supported-protocols",                "");
// HTTP
user_pref("network.http.referer.XOriginPolicy",             2);
user_pref("network.http.referer.XOriginTrimmingPolicy",     2);
// Cache
user_pref("browser.cache.disk.enable",                      true);
user_pref("browser.cache.disk.capacity",                    524288);
user_pref("browser.cache.memory.enable",                    true);
user_pref("browser.cache.memory.capacity",                  131072);
user_pref("browser.cache.offline.enable",                   false);
// Connection limits
user_pref("network.http.max-connections",                   1500);
user_pref("network.http.max-persistent-connections-per-server", 10);
user_pref("network.http.max-urgent-start-excessive-connections-per-host", 5);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  🔍  URL BAR & SEARCH
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Disable search suggestions in URL bar
user_pref("browser.search.suggest.enabled",                 false);
user_pref("browser.urlbar.suggest.searches",                false);
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
user_pref("browser.urlbar.suggest.quicksuggest.sponsored",  false);
user_pref("browser.urlbar.quicksuggest.enabled",            false);
user_pref("browser.urlbar.quicksuggest.dataCollection.enabled", false);
// URL bar features
user_pref("browser.urlbar.suggest.history",                 true);
user_pref("browser.urlbar.suggest.bookmark",                true);
user_pref("browser.urlbar.suggest.openpage",                true);
user_pref("browser.urlbar.suggest.topsites",                false);
user_pref("browser.urlbar.suggest.engines",                 false);
user_pref("browser.urlbar.suggest.recentsearches",          false);
// Don't submit form history
user_pref("browser.formfill.enable",                        false);
// Show full URL always
user_pref("browser.urlbar.trimURLs",                        false);
user_pref("browser.urlbar.showSearchTerms.enabled",         false);
// Open new tab on address bar focus
user_pref("browser.urlbar.openintab",                       false);
// URL bar width
user_pref("browser.urlbar.maxRichResults",                  10);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  🍪  COOKIES & STORAGE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Cookie lifetime (session only for third-party)
user_pref("network.cookie.lifetimePolicy",                  0);
// Third-party cookies — blocked via ETP
user_pref("network.cookie.thirdparty.sessionOnly",          true);
user_pref("network.cookie.thirdparty.nonsecureSessionOnly", true);
// IndexedDB
user_pref("dom.indexedDB.enabled",                          true);
// localStorage
user_pref("dom.storage.enabled",                            true);
// Service workers
user_pref("dom.serviceWorkers.enabled",                     true);
// Push notifications
user_pref("dom.push.enabled",                               false);
user_pref("dom.push.connection.enabled",                    false);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  📸  MEDIA & PERMISSIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Camera / microphone — prompt
user_pref("permissions.default.camera",                     0);
user_pref("permissions.default.microphone",                 0);
// Geolocation — deny
user_pref("permissions.default.geo",                        2);
user_pref("geo.enabled",                                    false);
user_pref("geo.provider.network.url",                       "");
user_pref("geo.provider.ms-windows-location",               false);
user_pref("geo.provider.use_corelocation",                  false);
user_pref("geo.provider.use_gpsd",                          false);
user_pref("geo.provider.use_geoclue",                       false);
// Desktop notifications — prompt
user_pref("permissions.default.desktop-notification",       0);
// XR (Virtual Reality) — deny
user_pref("permissions.default.xr",                        2);
// Autoplay
user_pref("media.autoplay.default",                         5);
user_pref("media.autoplay.blocking_policy",                 2);
user_pref("media.block-autoplay-until-in-foreground",       true);
// DRM content
user_pref("media.eme.enabled",                              true);
user_pref("media.gmp-provider.enabled",                     true);
// AV1 / VP9 hardware decoding
user_pref("media.ffmpeg.vaapi.enabled",                     true);
user_pref("media.av1.enabled",                              true);
user_pref("media.ffvpx.enabled",                            true);
// Enable AVIF images
user_pref("image.avif.enabled",                             true);
// Enable WebP images
user_pref("image.webp.enabled",                             true);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  📂  DOWNLOADS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Always ask where to save
user_pref("browser.download.useDownloadDir",                false);
user_pref("browser.download.always_ask_before_handling_new_types", true);
user_pref("browser.download.alwaysOpenPanel",               false);
// Download manager
user_pref("browser.download.animateNotifications",          false);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  📖  READING & MISC
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Reader mode font
user_pref("reader.font_type",                               "sans-serif");
user_pref("reader.color_scheme",                            "dark");
user_pref("reader.font_size",                               5);
user_pref("reader.content_width",                           4);
user_pref("reader.line_height",                             4);
// PDF viewer
user_pref("pdfjs.defaultZoomValue",                         "page-width");
user_pref("pdfjs.enabledCache.state",                       true);
user_pref("pdfjs.sidebarViewOnLoad",                        2);
// Spell check
user_pref("layout.spellcheckDefault",                       1);
// Warn before quitting
user_pref("browser.warnOnQuit",                             false);
user_pref("browser.warnOnQuitShortcut",                     true);
// Disable pocket
user_pref("extensions.pocket.enabled",                      false);
user_pref("extensions.pocket.site",                         "");
user_pref("extensions.pocket.oAuthConsumerKey",             "");
// Screenshot tool
user_pref("extensions.screenshots.disabled",                true);
// Middle click paste (Linux)
user_pref("middlemouse.paste",                              true);
// Accessibility services
user_pref("accessibility.force_disabled",                   0);
// DevTools
user_pref("devtools.theme",                                 "dark");
user_pref("devtools.toolbox.host",                          "bottom");
user_pref("devtools.cache.disabled",                        false);
// Disable Google account integration
user_pref("identity.fxaccounts.enabled",                    false);
// Disable Sync
user_pref("services.sync.enabled",                          false);
// Disable about:config warning
user_pref("browser.aboutConfig.showWarning",                false);
// Restore previous session
user_pref("browser.sessionstore.resume_from_crash",         true);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  🐧  LINUX / WAYLAND SPECIFIC
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Native Wayland support
user_pref("widget.wayland.use-dmabuf-webgl",                true);
user_pref("widget.wayland.fractional-scale.enabled",        true);
user_pref("widget.wayland.opaque-region.enabled",           true);
// Touch scrolling on Wayland
user_pref("apz.gtk.kinetic_scroll.delta_mode",              2);
// Pipewire screenshare
user_pref("media.webrtc.hw.h264.enabled",                   true);
user_pref("media.webrtc.platformencoder",                   true);
// RDD process
user_pref("media.rdd-ffmpeg.enabled",                       true);
// XDG portals
user_pref("widget.use-xdg-desktop-portal.file-picker",      1);
user_pref("widget.use-xdg-desktop-portal.mime-handler",     1);
user_pref("widget.use-xdg-desktop-portal.settings",         1);
user_pref("widget.use-xdg-desktop-portal.location",         1);
user_pref("widget.use-xdg-desktop-portal.open-uri",         1);
// GTK theme integration
user_pref("widget.gtk.ignore-bogus-leave-notify",           1);
user_pref("widget.gtk.overlay-scrollbars.enabled",          true);
user_pref("widget.gtk.rounded-bottom-corners.enabled",      true);
// Touchpad gestures
user_pref("dom.w3c_touch_events.enabled",                   1);
user_pref("apz.overscroll.enabled",                         true);
user_pref("apz.allow_zooming",                              true);
user_pref("apz.allow_double_tap_zooming",                   true);