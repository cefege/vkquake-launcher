import AppKit
import UniformTypeIdentifiers

private let installRoot = Bundle.main.bundleURL.deletingLastPathComponent()
private let releaseRoot = installRoot.appendingPathComponent("rerelease", isDirectory: true)
private let vkQuakeApp = releaseRoot.appendingPathComponent("vkQuake.app", isDirectory: true)

private struct Campaign {
    let title: String
    let subtitle: String
    let edition: String
    let imageName: String
    let arguments: [String]
    var requiredDirectory: String? = nil
    var requiredFiles: [String] = []
}

private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

private final class CampaignCardButton: NSButton {
    let campaign: Campaign
    private var trackingAreaRef: NSTrackingArea?
    private var hovered = false { didSet { needsDisplay = true } }

    init(campaign: Campaign) {
        self.campaign = campaign
        super.init(frame: .zero)
        title = campaign.title
        isBordered = false
        setButtonType(.momentaryChange)
        focusRingType = .exterior
        toolTip = "Launch \(campaign.title)"
        setAccessibilityLabel("Launch \(campaign.title)")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef { removeTrackingArea(trackingAreaRef) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self)
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func mouseEntered(with event: NSEvent) { hovered = true }
    override func mouseExited(with event: NSEvent) { hovered = false }

    override func draw(_ dirtyRect: NSRect) {
        let cardRect = bounds.insetBy(dx: 1.5, dy: 1.5)
        let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 12, yRadius: 12)
        NSGraphicsContext.saveGraphicsState()
        cardPath.addClip()

        NSColor(calibratedWhite: 0.07, alpha: 1).setFill()
        cardRect.fill()

        if let image = NSImage(named: campaign.imageName) {
            let sourceSize = image.size
            let scale = max(cardRect.width / sourceSize.width, cardRect.height / sourceSize.height)
            let sourceWidth = cardRect.width / scale
            let sourceHeight = cardRect.height / scale
            let sourceRect = NSRect(
                x: (sourceSize.width - sourceWidth) / 2,
                y: (sourceSize.height - sourceHeight) / 2,
                width: sourceWidth,
                height: sourceHeight
            )
            image.draw(in: cardRect, from: sourceRect, operation: .sourceOver, fraction: isHighlighted ? 0.70 : 0.88, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
        }

        let gradient = NSGradient(colorsAndLocations:
            (NSColor(calibratedWhite: 0.02, alpha: 0.96), 0.0),
            (NSColor(calibratedWhite: 0.02, alpha: 0.66), 0.36),
            (NSColor(calibratedWhite: 0.02, alpha: 0.02), 0.78)
        )!
        gradient.draw(in: cardRect, angle: 90)

        NSColor(calibratedRed: 0.72, green: 0.34, blue: 0.16, alpha: 1).setFill()
        NSRect(x: cardRect.minX, y: cardRect.minY, width: 4, height: cardRect.height).fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let editionAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Avenir Next Condensed Demi Bold", size: 11) ?? NSFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: NSColor(calibratedRed: 0.90, green: 0.58, blue: 0.34, alpha: 1),
            .kern: 1.4,
            .paragraphStyle: paragraph
        ]
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Avenir Next Condensed Demi Bold", size: campaign.title.count > 24 ? 22 : 26) ?? NSFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: NSColor.white,
            .kern: 0.2,
            .paragraphStyle: paragraph
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Avenir Next", size: 12) ?? NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor(calibratedWhite: 0.84, alpha: 1),
            .paragraphStyle: paragraph
        ]

        let inset: CGFloat = 22
        campaign.edition.uppercased().draw(in: NSRect(x: inset, y: 69, width: cardRect.width - 44, height: 16), withAttributes: editionAttributes)
        campaign.title.draw(in: NSRect(x: inset, y: 38, width: cardRect.width - 44, height: 34), withAttributes: titleAttributes)
        campaign.subtitle.draw(in: NSRect(x: inset, y: 18, width: cardRect.width - 44, height: 18), withAttributes: subtitleAttributes)

        if hovered || isHighlighted {
            (hovered ? NSColor(calibratedRed: 0.90, green: 0.57, blue: 0.30, alpha: 0.95) : NSColor.white.withAlphaComponent(0.8)).setStroke()
            cardPath.lineWidth = hovered ? 3 : 2
            cardPath.stroke()
        } else {
            NSColor.white.withAlphaComponent(0.15).setStroke()
            cardPath.lineWidth = 1
            cardPath.stroke()
        }
        NSGraphicsContext.restoreGraphicsState()
    }
}

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.regular)
        application.run()
    }

    private var window: NSWindow!

    private lazy var campaigns: [Campaign] = {
        let fileManager = FileManager.default
        let hasSharewarePak = fileManager.fileExists(atPath: releaseRoot.appendingPathComponent("id1/pak0.pak").path)
        let hasRegisteredPak = fileManager.fileExists(atPath: releaseRoot.appendingPathComponent("id1/pak1.pak").path)
        let hasEnhancedData = fileManager.fileExists(atPath: releaseRoot.appendingPathComponent("quakeex.kpf").path)
        let shareware = hasSharewarePak && !hasRegisteredPak && !hasEnhancedData
        let base = shareware
            ? Campaign(title: "Quake Shareware", subtitle: "Official demo · Episode One", edition: "Shareware Demo", imageName: "base", arguments: [], requiredFiles: ["id1/pak0.pak"])
            : Campaign(title: "Quake Enhanced", subtitle: "The original campaign, remastered", edition: "Original Campaign", imageName: "base", arguments: [], requiredFiles: ["quakeex.kpf", "id1/pak0.pak"])
        return [
            base,
            Campaign(title: "Scourge of Armagon", subtitle: "Mission Pack No. 1", edition: "Hipnotic Interactive · 1997", imageName: "hipnotic", arguments: ["-hipnotic"], requiredFiles: ["hipnotic/pak0.pak"]),
            Campaign(title: "Dissolution of Eternity", subtitle: "Mission Pack No. 2", edition: "Rogue Entertainment · 1997", imageName: "rogue", arguments: ["-rogue"], requiredFiles: ["rogue/pak0.pak"]),
            Campaign(title: "Dimension of the Past", subtitle: "A MachineGames episode", edition: "MachineGames · 2016", imageName: "dopa", arguments: ["-game", "dopa"], requiredFiles: ["dopa/pak0.pak"]),
            Campaign(title: "Dimension of the Machine", subtitle: "The new MachineGames campaign", edition: "MachineGames · 2021", imageName: "mg1", arguments: ["-game", "mg1"], requiredFiles: ["mg1/pak0.pak"]),
            Campaign(title: "Dawn of the Machine", subtitle: "30th Anniversary campaign · Not installed", edition: "MachineGames · 2026", imageName: "mg3", arguments: ["-game", "mg3"], requiredDirectory: "mg3")
        ]
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildWindow()
        NSApp.activate(ignoringOtherApps: true)
        if !FileManager.default.fileExists(atPath: vkQuakeApp.path) {
            showError(
                "vkQuake isn’t installed",
                "Keep this launcher beside the rerelease folder and restore vkQuake.app at:\n\(vkQuakeApp.path)"
            )
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "vkQuake Launcher"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.minSize = NSSize(width: 760, height: 600)
        window.center()

        let backdrop = NSVisualEffectView()
        backdrop.material = .underWindowBackground
        backdrop.blendingMode = .behindWindow
        backdrop.state = .active
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = backdrop

        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        backdrop.addSubview(scroll)

        let content = FlippedView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.documentView = content

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 30, left: 32, bottom: 28, right: 32)
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        let eyebrow = label("NATIVE CAMPAIGN LIBRARY", size: 12, weight: .semibold, color: NSColor(calibratedRed: 0.88, green: 0.52, blue: 0.28, alpha: 1), tracking: 2.2)
        let title = label("vkQuake", size: 42, weight: .bold, color: .white, tracking: -0.8)
        let intro = label("Choose a campaign. Every card launches the signed Apple Silicon build with its verified game data and soundtrack.", size: 13, weight: .regular, color: NSColor(calibratedWhite: 0.72, alpha: 1), tracking: 0)
        intro.maximumNumberOfLines = 2
        intro.lineBreakMode = .byWordWrapping

        stack.addArrangedSubview(eyebrow)
        stack.setCustomSpacing(2, after: eyebrow)
        stack.addArrangedSubview(title)
        stack.setCustomSpacing(4, after: title)
        stack.addArrangedSubview(intro)
        stack.setCustomSpacing(22, after: intro)

        let baseCard = card(for: campaigns[0], height: 195)
        stack.addArrangedSubview(baseCard)
        baseCard.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -64).isActive = true

        for pairStart in stride(from: 1, to: 5, by: 2) {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 16
            row.distribution = .fillEqually
            row.translatesAutoresizingMaskIntoConstraints = false
            let first = card(for: campaigns[pairStart], height: 154)
            row.addArrangedSubview(first)
            if pairStart + 1 < campaigns.count {
                row.addArrangedSubview(card(for: campaigns[pairStart + 1], height: 154))
            }
            stack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -64).isActive = true
        }

        let dawnCard = card(for: campaigns[5], height: 175)
        stack.addArrangedSubview(dawnCard)
        dawnCard.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -64).isActive = true

        let divider = NSBox()
        divider.boxType = .separator
        stack.addArrangedSubview(divider)
        divider.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -64).isActive = true
        stack.setCustomSpacing(12, after: divider)

        let customHeader = label("CUSTOM CONTENT", size: 11, weight: .semibold, color: NSColor(calibratedWhite: 0.60, alpha: 1), tracking: 1.6)
        stack.addArrangedSubview(customHeader)

        let actions = NSStackView()
        actions.orientation = .horizontal
        actions.spacing = 10
        let modButton = actionButton("Install a Mod…", action: #selector(chooseMod))
        modButton.toolTip = "Choose an extracted Quake mod folder, install it, and launch"
        let mapButton = actionButton("Play a BSP Map…", action: #selector(chooseMap))
        mapButton.toolTip = "Choose a loose .bsp map, install it, and launch"
        actions.addArrangedSubview(modButton)
        actions.addArrangedSubview(mapButton)
        stack.addArrangedSubview(actions)

        let footer = NSStackView()
        footer.orientation = .horizontal
        footer.alignment = .centerY
        footer.spacing = 10
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        footer.addArrangedSubview(spacer)
        footer.addArrangedSubview(label("Made by Mihai Mateias · MIT", size: 11, weight: .regular, color: NSColor(calibratedWhite: 0.55, alpha: 1), tracking: 0))
        let reportButton = NSButton(title: "View on GitHub ↗", target: self, action: #selector(openProject))
        reportButton.isBordered = false
        reportButton.font = NSFont(name: "Avenir Next Demi Bold", size: 11) ?? NSFont.systemFont(ofSize: 11, weight: .semibold)
        reportButton.contentTintColor = NSColor(calibratedRed: 0.88, green: 0.52, blue: 0.28, alpha: 1)
        reportButton.toolTip = "Open the vkQuake Launcher project on GitHub"
        footer.addArrangedSubview(reportButton)
        stack.addArrangedSubview(footer)
        footer.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -64).isActive = true


        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: backdrop.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: backdrop.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: backdrop.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: backdrop.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentView.trailingAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentView.topAnchor),
            content.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            intro.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -64)
        ])

        window.makeKeyAndOrderFront(nil)
    }

    private func card(for campaign: Campaign, height: CGFloat) -> CampaignCardButton {
        let button = CampaignCardButton(campaign: campaign)
        button.target = self
        button.action = #selector(playCampaign(_:))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: height).isActive = true
        return button
    }

    private func label(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, tracking: CGFloat) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        let fontName = weight >= .semibold ? "Avenir Next Condensed Demi Bold" : "Avenir Next"
        field.font = NSFont(name: fontName, size: size) ?? NSFont.systemFont(ofSize: size, weight: weight)
        field.textColor = color
        field.allowsEditingTextAttributes = true
        field.attributedStringValue = NSAttributedString(string: text, attributes: [.font: field.font!, .foregroundColor: color, .kern: tracking])
        return field
    }

    private func actionButton(_ title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.font = NSFont(name: "Avenir Next Demi Bold", size: 13) ?? NSFont.systemFont(ofSize: 13, weight: .semibold)
        return button
    }

    @objc private func openProject() {
        NSWorkspace.shared.open(URL(string: "https://github.com/cefege/vkquake-launcher")!)
    }

    @objc private func playCampaign(_ sender: CampaignCardButton) {
        let campaign = sender.campaign
        if campaign.requiredDirectory != nil {
            showError(
                "\(campaign.title) isn’t installed yet",
                "This campaign was released on August 6, 2026, but it is not yet included in your GOG or Steam builds. It also needs a newer Dawn-capable vkQuake build; the installed vkQuake 1.35 predates required text and model fixes."
            )
            return
        }
        let missingFiles = campaign.requiredFiles.filter {
            !FileManager.default.fileExists(atPath: releaseRoot.appendingPathComponent($0).path)
        }
        guard missingFiles.isEmpty else {
            showError(
                "\(campaign.title) data is missing",
                "Restore these files inside the rerelease folder:\n\(missingFiles.joined(separator: "\n"))"
            )
            return
        }
        launch(arguments: campaign.arguments, displayName: campaign.title)
    }

    private func launch(arguments: [String], displayName: String) {
        guard FileManager.default.fileExists(atPath: vkQuakeApp.path) else {
            showError("vkQuake isn’t installed", "Restore rerelease/vkQuake.app beside this launcher, then try again.")
            return
        }
        if let running = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleURL?.standardizedFileURL == vkQuakeApp.standardizedFileURL
        }) {
            running.activate(options: [.activateAllWindows])
            showError("vkQuake is already running", "Quit the current game before launching a different campaign or custom map.")
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.arguments = arguments
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: vkQuakeApp, configuration: configuration) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error {
                    self?.showError("Couldn’t launch \(displayName)", error.localizedDescription)
                } else {
                    NSApp.terminate(nil)
                }
            }
        }
    }

    @objc private func chooseMod() {
        let panel = NSOpenPanel()
        panel.title = "Choose an Extracted Quake Mod Folder"
        panel.prompt = "Install and Play"
        panel.message = "Choose the folder that contains the mod's PAK, PK3, progs.dat, maps, or other game files."
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let source = panel.url else { return }
            self?.installAndLaunchMod(from: source)
        }
    }

    private func installAndLaunchMod(from source: URL) {
        let name = source.lastPathComponent
        let reservedNames: Set<String> = ["id1", "hipnotic", "rogue", "dopa", "mg1", "mg3", "ctf", "movies", "custom", "vkquake.app"]
        guard !name.isEmpty, name != ".", name != "..", !name.hasPrefix("."), !name.contains("/") else {
            showError("That folder name can’t be used", "Rename the folder and try again.")
            return
        }
        guard !reservedNames.contains(name.lowercased()) else {
            showError("That name is reserved", "Rename the mod folder. “\(name)” belongs to installed game content and will never be replaced by the launcher.")
            return
        }
        guard source.standardizedFileURL != releaseRoot.standardizedFileURL else {
            showError("Choose a mod folder", "Choose a folder inside or outside the rerelease folder—not the rerelease folder itself.")
            return
        }
        guard containsPlayableModData(at: source) else {
            showError("No Quake mod data was found", "Choose the extracted folder containing a PAK, PK3, PK4, progs.dat, or BSP file.")
            return
        }

        let destination = releaseRoot.appendingPathComponent(name, isDirectory: true)
        if source.standardizedFileURL != destination.standardizedFileURL {
            if FileManager.default.fileExists(atPath: destination.path) {
                let alert = NSAlert()
                alert.messageText = "Replace the installed “\(name)” mod?"
                alert.informativeText = "A folder with this name is already installed. Its current contents will be replaced."
                alert.addButton(withTitle: "Replace and Play")
                alert.addButton(withTitle: "Cancel")
                guard alert.runModal() == .alertFirstButtonReturn else { return }
                do { try FileManager.default.removeItem(at: destination) }
                catch { showError("Couldn’t replace the installed mod", error.localizedDescription); return }
            }
            do { try FileManager.default.copyItem(at: source, to: destination) }
            catch { showError("Couldn’t install the mod", error.localizedDescription); return }
        }
        launch(arguments: ["-game", name], displayName: name)
    }

    private func containsPlayableModData(at source: URL) -> Bool {
        guard let enumerator = FileManager.default.enumerator(
            at: source,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return false }
        let extensions: Set<String> = ["pak", "pk3", "pk4", "bsp"]
        while let file = enumerator.nextObject() as? URL {
            if extensions.contains(file.pathExtension.lowercased()) || file.lastPathComponent.lowercased() == "progs.dat" {
                return true
            }
        }
        return false
    }

    @objc private func chooseMap() {
        let panel = NSOpenPanel()
        panel.title = "Choose a Quake BSP Map"
        panel.prompt = "Install and Play"
        panel.message = "Choose a compiled .bsp map file. The launcher will install it in a dedicated custom game folder."
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType(filenameExtension: "bsp") ?? .data]
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let source = panel.url else { return }
            self?.installAndLaunchMap(from: source)
        }
    }

    private func installAndLaunchMap(from source: URL) {
        guard source.pathExtension.lowercased() == "bsp" else {
            showError("That isn’t a BSP map", "Choose a file ending in .bsp.")
            return
        }
        let mapName = source.deletingPathExtension().lastPathComponent
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        guard !mapName.isEmpty, mapName.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            showError("That map name can’t be launched", "Rename the BSP using only letters, numbers, hyphens, and underscores.")
            return
        }
        guard isSupportedQuakeBSP(source) else {
            showError("That isn’t a supported Quake BSP", "The file does not have a Quake BSP29 or BSP2 header.")
            return
        }
        let mapsDirectory = releaseRoot.appendingPathComponent("custom/maps", isDirectory: true)
        let destination = mapsDirectory.appendingPathComponent(source.lastPathComponent)
        if source.standardizedFileURL == destination.standardizedFileURL {
            launch(arguments: ["-game", "custom", "+map", mapName], displayName: mapName)
            return
        }
        do {
            try FileManager.default.createDirectory(at: mapsDirectory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
        } catch {
            showError("Couldn’t install the map", error.localizedDescription)
            return
        }
        launch(arguments: ["-game", "custom", "+map", mapName], displayName: mapName)
    }

    private func isSupportedQuakeBSP(_ source: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: source) else { return false }
        defer { try? handle.close() }
        guard let header = try? handle.read(upToCount: 4), header.count == 4 else { return false }
        if header == Data("BSP2".utf8) || header == Data("2PSB".utf8) { return true }
        let version = header.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
        return UInt32(littleEndian: version) == 29
    }

    private func showError(_ title: String, _ detail: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = detail
        if window != nil { alert.beginSheetModal(for: window) }
        else { alert.runModal() }
    }

}
