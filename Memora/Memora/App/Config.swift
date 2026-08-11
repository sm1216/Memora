import Foundation

enum AppConfig {
    // MARK: - Mapbox
    /// Public token (pk.*) for Mapbox GL JS client.
    /// Set locally — do not commit real tokens (GitHub push protection blocks them).
    /// Dashboard: https://account.mapbox.com/access-tokens/
    /// Or copy from Secrets.local (gitignored): MAPBOX_PUBLIC_TOKEN
    static let mapboxAccessToken = ""

    /// Secret token (sk.*) — NEVER ship inside the app binary (extractable from IPA).
    /// Use only on a server / Supabase Edge Function for privileged Mapbox APIs
    /// (e.g. Temporary tokens, tilequery server-side, account APIs).
    /// Stored in `Secrets.local.xcconfig` / env for server use only — not compiled into the app.
    static let mapboxSecretTokenAvailableServerSide = true

    static let mapboxStyleURL = "mapbox://styles/mapbox/outdoors-v12"
    static let mapboxDarkStyleURL = "mapbox://styles/mapbox/dark-v11"
    static let mapboxSatelliteStyleURL = "mapbox://styles/mapbox/satellite-streets-v12"

    // MARK: - Supabase (project memora-nfc)
    /// https://supabase.com/dashboard/project/uxdvvrvjzqpzbwseduny
    static let supabaseURL = URL(string: "https://uxdvvrvjzqpzbwseduny.supabase.co")!
    /// anon / public key only (never ship service_role in the app)
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV4ZHZ2cnZqenFwemJ3c2VkdW55Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYzMTU2MDYsImV4cCI6MjEwMTg5MTYwNn0.TxNT08nknc-sar58mbufNpHIEUXbvUxrIDLRffH8r_Y"
    static let supabaseStorageBucket = "memories"

    /// Public share base written to NFC tags
    static let publicShareBase = "https://uxdvvrvjzqpzbwseduny.supabase.co/storage/v1/object/public/memories"
    /// Deep link for in-app open: memora://m/{shortId}
    static let urlScheme = "memora"

    /// NFC payload base (short id path). App + browser can resolve shortId.
    static var nfcShareBase: String {
        "https://uxdvvrvjzqpzbwseduny.supabase.co/functions/v1/m"
    }

    /// Optional Google OAuth (configure in Supabase Auth providers too)
    static let googleClientID = ""

    static var googleURLScheme: String {
        guard !googleClientID.isEmpty else { return "" }
        let parts = googleClientID.split(separator: ".")
        guard let first = parts.first else { return "" }
        return "com.googleusercontent.apps.\(first)"
    }

    static let appDisplayName = "Memories"
    static let appTagline = "Moments Forever"
    static let bundleID = "com.smohanty.memora"
}
