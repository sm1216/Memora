import SwiftUI
import MapKit
import WebKit

struct MapMarkerData: Equatable {
    var id: String
    var coord: CLLocationCoordinate2D
    var title: String
    var color: String

    static func == (lhs: MapMarkerData, rhs: MapMarkerData) -> Bool {
        lhs.id == rhs.id
            && lhs.coord.latitude == rhs.coord.latitude
            && lhs.coord.longitude == rhs.coord.longitude
            && lhs.title == rhs.title
            && lhs.color == rhs.color
    }
}

/// Real Mapbox GL JS maps (uses your public token).
struct MapboxMapView: UIViewRepresentable {
    var center: CLLocationCoordinate2D
    var zoom: Double = 10
    var styleURL: String = AppConfig.mapboxStyleURL
    var projection: String = "mercator" // or "globe"
    var markers: [MapMarkerData] = []
    var route: [CLLocationCoordinate2D] = []
    var interactive: Bool = true
    var pitch: Double = 0
    var showTerrain: Bool = false
    /// Highlighted pin id (larger ring). Pass memory UUID string on globe.
    var activeMarkerId: String? = nil
    /// Camera animation length in ms (longer = more globe spin).
    var flyDurationMs: Double = 600
    var onMarkerTap: ((String) -> Void)? = nil

    /// Convenience for simple markers without ids
    init(
        center: CLLocationCoordinate2D,
        zoom: Double = 10,
        styleURL: String = AppConfig.mapboxStyleURL,
        projection: String = "mercator",
        markers: [(coord: CLLocationCoordinate2D, title: String, color: String)],
        route: [CLLocationCoordinate2D] = [],
        interactive: Bool = true,
        pitch: Double = 0,
        showTerrain: Bool = false,
        activeMarkerId: String? = nil,
        flyDurationMs: Double = 600,
        onMarkerTap: ((String) -> Void)? = nil
    ) {
        self.center = center
        self.zoom = zoom
        self.styleURL = styleURL
        self.projection = projection
        self.markers = markers.enumerated().map {
            MapMarkerData(id: "\($0.offset)", coord: $0.element.coord, title: $0.element.title, color: $0.element.color)
        }
        self.route = route
        self.interactive = interactive
        self.pitch = pitch
        self.showTerrain = showTerrain
        self.activeMarkerId = activeMarkerId
        self.flyDurationMs = flyDurationMs
        self.onMarkerTap = onMarkerTap
    }

    init(
        center: CLLocationCoordinate2D,
        zoom: Double = 10,
        styleURL: String = AppConfig.mapboxStyleURL,
        projection: String = "mercator",
        markerData: [MapMarkerData],
        route: [CLLocationCoordinate2D] = [],
        interactive: Bool = true,
        pitch: Double = 0,
        showTerrain: Bool = false,
        activeMarkerId: String? = nil,
        flyDurationMs: Double = 600,
        onMarkerTap: ((String) -> Void)? = nil
    ) {
        self.center = center
        self.zoom = zoom
        self.styleURL = styleURL
        self.projection = projection
        self.markers = markerData
        self.route = route
        self.interactive = interactive
        self.pitch = pitch
        self.showTerrain = showTerrain
        self.activeMarkerId = activeMarkerId
        self.flyDurationMs = flyDurationMs
        self.onMarkerTap = onMarkerTap
    }

    func makeCoordinator() -> Coordinator { Coordinator(onMarkerTap: onMarkerTap) }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "pinTap")
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.allowsInlineMediaPlayback = true
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 0.10, green: 0.12, blue: 0.14, alpha: 1)
        web.scrollView.isScrollEnabled = interactive
        web.scrollView.bounces = false
        web.navigationDelegate = context.coordinator
        context.coordinator.parent = self
        context.coordinator.onMarkerTap = onMarkerTap
        web.loadHTMLString(html, baseURL: URL(string: "https://api.mapbox.com"))
        return web
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.onMarkerTap = onMarkerTap
        let markerJSON = markers.map { m in
            "{id:\(jsString(m.id)),lng:\(m.coord.longitude),lat:\(m.coord.latitude),title:\(jsString(m.title)),color:\(jsString(m.color))}"
        }.joined(separator: ",")
        let routeJSON = route.map { "[\($0.longitude),\($0.latitude)]" }.joined(separator: ",")
        let activeJS = activeMarkerId.map { jsString($0) } ?? "null"
        let js = """
        if (window.__updateMap) {
          window.__updateMap({
            lat: \(center.latitude),
            lng: \(center.longitude),
            zoom: \(zoom),
            pitch: \(pitch),
            duration: \(flyDurationMs),
            activeId: \(activeJS),
            markers: [\(markerJSON)],
            route: [\(routeJSON)]
          });
        }
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func jsString(_ s: String) -> String {
        let escaped = s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
        return "'\(escaped)'"
    }

    private var html: String {
        let initialMarkers = markers.map {
            "{id:\(jsString($0.id)),lng:\($0.coord.longitude),lat:\($0.coord.latitude),title:\(jsString($0.title)),color:\(jsString($0.color))}"
        }.joined(separator: ",")
        let initialRoute = route.map { "[\($0.longitude),\($0.latitude)]" }.joined(separator: ",")

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
        <script src="https://api.mapbox.com/mapbox-gl-js/v3.6.0/mapbox-gl.js"></script>
        <link href="https://api.mapbox.com/mapbox-gl-js/v3.6.0/mapbox-gl.css" rel="stylesheet"/>
        <style>
          html,body,#map{margin:0;padding:0;height:100%;width:100%;background:#1a1c1e;}
          .mapboxgl-ctrl-logo{opacity:.75}
          .mapboxgl-ctrl-attrib{font-size:9px}
          .mapboxgl-marker{cursor:pointer;}
        </style>
        </head>
        <body>
        <div id="map"></div>
        <script>
          mapboxgl.accessToken = '\(AppConfig.mapboxAccessToken)';
          const map = new mapboxgl.Map({
            container: 'map',
            style: '\(styleURL)',
            center: [\(center.longitude), \(center.latitude)],
            zoom: \(zoom),
            pitch: \(pitch),
            interactive: \(interactive ? "true" : "false"),
            attributionControl: true,
            projection: '\(projection)'
          });
          let markers = [];
          function clearMarkers(){ markers.forEach(m=>m.remove()); markers=[]; }
          let activeId = null;
          function setMarkers(list){
            clearMarkers();
            (list||[]).forEach(m=>{
              const isActive = activeId && String(m.id) === String(activeId);
              const el = document.createElement('div');
              const size = isActive ? 28 : 18;
              el.style.width = size + 'px';
              el.style.height = size + 'px';
              el.style.borderRadius = '50%';
              el.style.background = m.color || '#E37333';
              el.style.border = isActive ? '3px solid #FFE4C8' : '2px solid #fff';
              el.style.boxShadow = isActive
                ? '0 0 0 6px rgba(230,115,51,0.35), 0 2px 12px rgba(0,0,0,0.45)'
                : '0 2px 8px rgba(0,0,0,0.35)';
              el.style.cursor = 'pointer';
              el.style.transition = 'transform 0.2s ease';
              if (isActive) el.style.transform = 'scale(1.05)';
              el.addEventListener('click', function(ev){
                ev.stopPropagation();
                try {
                  window.webkit.messageHandlers.pinTap.postMessage({ id: String(m.id), title: m.title || '' });
                } catch(e) {}
              });
              const marker = new mapboxgl.Marker({ element: el })
                .setLngLat([m.lng, m.lat])
                .addTo(map);
              markers.push(marker);
            });
          }
          function setRoute(coords){
            if (map.getLayer('route')) map.removeLayer('route');
            if (map.getSource('route')) map.removeSource('route');
            if (!coords || coords.length < 2) return;
            map.addSource('route', {
              type: 'geojson',
              data: { type:'Feature', properties:{}, geometry:{ type:'LineString', coordinates: coords } }
            });
            map.addLayer({
              id:'route', type:'line', source:'route',
              layout:{ 'line-join':'round','line-cap':'round' },
              paint:{
                'line-color':'#E37333',
                'line-width':3.5,
                'line-opacity':0.92,
                'line-dasharray': [0, 0]
              }
            });
          }
          map.on('load', () => {
            \(showTerrain ? """
            try {
              map.addSource('mapbox-dem', {
                type: 'raster-dem',
                url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
                tileSize: 512, maxzoom: 14
              });
              map.setTerrain({ source: 'mapbox-dem', exaggeration: 1.2 });
            } catch(e) {}
            """ : "")
            setMarkers([\(initialMarkers)]);
            setRoute([\(initialRoute)]);
          });
          window.__updateMap = (opts) => {
            if (!opts) return;
            if (opts.activeId !== undefined) activeId = opts.activeId;
            const dur = (typeof opts.duration === 'number') ? opts.duration : 600;
            map.flyTo({
              center: [opts.lng, opts.lat],
              zoom: opts.zoom,
              pitch: opts.pitch || 0,
              duration: dur,
              essential: true
            });
            setMarkers(opts.markers);
            if (map.isStyleLoaded()) setRoute(opts.route); else map.once('load', ()=>setRoute(opts.route));
          };
          window.__setView = (lat, lon, z) => map.flyTo({ center:[lon,lat], zoom:z, essential:true, duration: 1400 });
        </script>
        </body>
        </html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: MapboxMapView?
        var onMarkerTap: ((String) -> Void)?

        init(onMarkerTap: ((String) -> Void)?) {
            self.onMarkerTap = onMarkerTap
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "pinTap" else { return }
            if let dict = message.body as? [String: Any], let id = dict["id"] as? String {
                DispatchQueue.main.async {
                    self.onMarkerTap?(id)
                }
            } else if let id = message.body as? String {
                DispatchQueue.main.async {
                    self.onMarkerTap?(id)
                }
            }
        }
    }
}

/// Mapbox 3D globe with terracotta pins, route lines, and focus fly-to.
struct MapboxGlobeView: View {
    var memories: [Memory]
    /// Active pin — globe spins here when user swipes stories.
    var focusedId: UUID? = nil
    var onSelect: ((Memory) -> Void)?

    private var markerData: [MapMarkerData] {
        memories.map {
            MapMarkerData(
                id: $0.id.uuidString,
                coord: $0.coordinate,
                title: $0.title,
                color: "#D6662E"
            )
        }
    }

    /// Chronological path so connection lines read as a journey.
    private var routeCoords: [CLLocationCoordinate2D] {
        memories
            .sorted { $0.startDate < $1.startDate }
            .map(\.coordinate)
    }

    private var focusedMemory: Memory? {
        guard let focusedId else { return nil }
        return memories.first { $0.id == focusedId }
    }

    private var center: CLLocationCoordinate2D {
        focusedMemory?.coordinate
            ?? memories.first?.coordinate
            ?? CLLocationCoordinate2D(latitude: 20, longitude: 10)
    }

    private var zoom: Double {
        focusedMemory != nil ? 2.6 : 1.35
    }

    var body: some View {
        MapboxMapView(
            center: center,
            zoom: zoom,
            styleURL: AppConfig.mapboxDarkStyleURL,
            projection: "globe",
            markerData: markerData,
            route: routeCoords,
            interactive: true,
            pitch: focusedMemory != nil ? 15 : 0,
            showTerrain: false,
            activeMarkerId: focusedId?.uuidString,
            flyDurationMs: focusedMemory != nil ? 1600 : 800,
            onMarkerTap: { id in
                if let m = memories.first(where: { $0.id.uuidString == id }) {
                    onSelect?(m)
                }
            }
        )
        .ignoresSafeArea()
    }
}

/// Half-sheet horizontal pager for pin stories (globe stays visible behind).
struct MemoryPagerSheet: View {
    let memories: [Memory]
    let initial: Memory
    /// Keeps parent globe in sync as user swipes.
    @Binding var focusedId: UUID?
    var onClose: () -> Void

    @State private var selection: UUID

    init(memories: [Memory], initial: Memory, focusedId: Binding<UUID?>, onClose: @escaping () -> Void) {
        let ordered = memories.sorted { $0.startDate > $1.startDate }
        self.memories = ordered.isEmpty ? [initial] : ordered
        self.initial = initial
        self._focusedId = focusedId
        self.onClose = onClose
        _selection = State(initialValue: initial.id)
    }

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selection) {
                ForEach(memories) { memory in
                    NavigationStack {
                        MemoryDetailView(
                            memory: memory,
                            presentation: .halfSheet,
                            onClose: onClose
                        )
                    }
                    .tag(memory.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            if memories.count > 1 {
                Text("Swipe · globe follows")
                    .font(.memoraMicro(11))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.paperElevated.opacity(0.92))
                    .clipShape(Capsule())
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            focusedId = selection
        }
        .onChange(of: selection) { _, newId in
            focusedId = newId
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
}

struct NativeTripMap: View {
    var memories: [Memory]
    var focused: Memory?

    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $position) {
            ForEach(memories) { m in
                Annotation(m.title, coordinate: m.coordinate) {
                    Circle()
                        .fill(AppTheme.terracotta)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .onAppear {
            if let f = focused {
                position = .region(MKCoordinateRegion(
                    center: f.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
                ))
            }
        }
    }
}
