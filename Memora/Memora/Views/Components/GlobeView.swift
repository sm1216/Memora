import SwiftUI
import SceneKit

/// Stylized 3D globe matching Memoried App Store hero: soft land, dark ocean, terracotta pins.
struct GlobeView: UIViewRepresentable {
    var memories: [Memory]
    var onSelect: ((Memory) -> Void)?

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = buildScene()
        view.backgroundColor = .clear
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = .multisampling4X
        view.defaultCameraController.interactionMode = .orbitTurntable
        view.defaultCameraController.minimumVerticalAngle = -10
        view.defaultCameraController.maximumVerticalAngle = 10
        view.defaultCameraController.inertiaEnabled = true

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        context.coordinator.view = view
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.memories = memories
        context.coordinator.onSelect = onSelect
        // Rebuild pins when count changes
        if let globe = uiView.scene?.rootNode.childNode(withName: "globe", recursively: false) {
            globe.childNodes.filter { $0.name?.hasPrefix("pin_") == true }.forEach { $0.removeFromParentNode() }
            for memory in memories {
                globe.addChildNode(pinNode(for: memory))
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(memories: memories, onSelect: onSelect)
    }

    private func buildScene() -> SCNScene {
        let scene = SCNScene()

        // Soft starfield
        let stars = SCNNode(geometry: SCNSphere(radius: 40))
        stars.geometry?.firstMaterial?.diffuse.contents = UIColor(white: 0.08, alpha: 1)
        stars.geometry?.firstMaterial?.isDoubleSided = true
        stars.geometry?.firstMaterial?.cullMode = .front
        scene.rootNode.addChildNode(stars)

        let globe = SCNNode(geometry: SCNSphere(radius: 1.0))
        globe.name = "globe"
        globe.geometry?.firstMaterial?.diffuse.contents = proceduralGlobeTexture()
        globe.geometry?.firstMaterial?.lightingModel = .blinn
        globe.geometry?.firstMaterial?.shininess = 0.15
        scene.rootNode.addChildNode(globe)

        // Atmosphere rim
        let atmosphere = SCNNode(geometry: SCNSphere(radius: 1.05))
        atmosphere.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        atmosphere.geometry?.firstMaterial?.transparent.contents = UIColor(white: 1, alpha: 0.08)
        atmosphere.geometry?.firstMaterial?.transparencyMode = .rgbZero
        scene.rootNode.addChildNode(atmosphere)

        for memory in memories {
            globe.addChildNode(pinNode(for: memory))
        }

        // Slow spin
        let spin = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 48))
        globe.runAction(spin)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 40
        camera.position = SCNVector3(0, 0.15, 3.2)
        scene.rootNode.addChildNode(camera)

        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = .omni
        light.light?.intensity = 900
        light.position = SCNVector3(4, 6, 8)
        scene.rootNode.addChildNode(light)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 400
        ambient.light?.color = UIColor(white: 0.85, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        return scene
    }

    private func pinNode(for memory: Memory) -> SCNNode {
        let container = SCNNode()
        container.name = "pin_\(memory.id.uuidString)"

        let pin = SCNNode(geometry: SCNSphere(radius: 0.035))
        pin.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 0.89, green: 0.45, blue: 0.20, alpha: 1)
        pin.geometry?.firstMaterial?.emission.contents = UIColor(red: 0.89, green: 0.45, blue: 0.20, alpha: 0.35)

        // Stem
        let stem = SCNNode(geometry: SCNCylinder(radius: 0.008, height: 0.08))
        stem.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 0.89, green: 0.45, blue: 0.20, alpha: 1)
        stem.position = SCNVector3(0, -0.05, 0)

        container.addChildNode(stem)
        container.addChildNode(pin)

        let pos = latLonToVector(lat: memory.latitude, lon: memory.longitude, radius: 1.06)
        container.position = pos
        container.look(at: SCNVector3Zero)

        // Count badge via billboard text for multi-memory clusters — single pin for simplicity
        return container
    }

    private func latLonToVector(lat: Double, lon: Double, radius: Double) -> SCNVector3 {
        let latR = lat * .pi / 180
        let lonR = lon * .pi / 180
        // SceneKit: y up, rotate so 0,0 is front
        let x = radius * cos(latR) * sin(lonR)
        let y = radius * sin(latR)
        let z = radius * cos(latR) * cos(lonR)
        return SCNVector3(x, y, z)
    }

    private func proceduralGlobeTexture() -> UIImage {
        let size = CGSize(width: 1024, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Ocean
            UIColor(red: 0.16, green: 0.18, blue: 0.20, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Soft land blobs approximating continents
            let land = UIColor(red: 0.78, green: 0.84, blue: 0.80, alpha: 1)
            land.setFill()
            let blobs: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                // Africa / Europe
                (480, 180, 160, 200),
                (500, 120, 100, 80),
                // Americas
                (220, 140, 90, 220),
                (250, 320, 70, 120),
                // Asia
                (700, 120, 220, 140),
                // Australia
                (820, 340, 80, 60)
            ]
            for (x, y, w, h) in blobs {
                let rect = CGRect(x: x, y: y, width: w, height: h)
                UIBezierPath(ovalIn: rect).fill()
            }

            // Subtle grid
            UIColor(white: 1, alpha: 0.04).setStroke()
            for i in 0..<12 {
                let y = size.height * CGFloat(i) / 12
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                path.lineWidth = 1
                path.stroke()
            }
        }
    }

    final class Coordinator: NSObject {
        var memories: [Memory]
        var onSelect: ((Memory) -> Void)?
        weak var view: SCNView?

        init(memories: [Memory], onSelect: ((Memory) -> Void)?) {
            self.memories = memories
            self.onSelect = onSelect
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view else { return }
            let point = gesture.location(in: view)
            let hits = view.hitTest(point, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
            for hit in hits {
                var node: SCNNode? = hit.node
                while let n = node {
                    if let name = n.name, name.hasPrefix("pin_") {
                        let idString = String(name.dropFirst(4))
                        if let id = UUID(uuidString: idString),
                           let memory = memories.first(where: { $0.id == id }) {
                            onSelect?(memory)
                            return
                        }
                    }
                    node = n.parent
                }
            }
        }
    }
}

struct GlobeBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.13, blue: 0.15),
                    Color(red: 0.18, green: 0.19, blue: 0.21),
                    Color(red: 0.10, green: 0.11, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            // Soft star dots
            GeometryReader { geo in
                Canvas { context, size in
                    for i in 0..<80 {
                        let x = CGFloat((i * 73) % 1000) / 1000 * size.width
                        let y = CGFloat((i * 137) % 1000) / 1000 * size.height
                        let r = CGFloat((i % 3) + 1) * 0.6
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                            with: .color(.white.opacity(0.35))
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}
