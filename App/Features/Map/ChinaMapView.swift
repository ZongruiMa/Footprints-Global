import SwiftUI

@MainActor struct ChinaMapView: View {
    let provinces: [ProvinceDefinition]
    let visited: Set<String>
    let selectedID: String?
    let theme: ThemeDefinition
    let select: (ProvinceDefinition) -> Void
    @State private var model = MapViewModel()
    @State private var scale: CGFloat = 1
    @State private var offset = CGSize.zero
    @GestureState private var magnification: CGFloat = 1
    @GestureState private var translation = CGSize.zero
    var body: some View {
        GeometryReader { geometry in
            let zoom = min(6, max(1, scale * magnification))
            let pan = clamped(CGSize(width: offset.width + translation.width, height: offset.height + translation.height), zoom: zoom, size: geometry.size)
            Canvas { context, size in
                context.translateBy(x: size.width / 2 + pan.width, y: size.height / 2 + pan.height)
                context.scaleBy(x: zoom, y: zoom)
                context.translateBy(x: -size.width / 2, y: -size.height / 2)
                for shape in model.shapes {
                    let selected = selectedID == shape.id
                    let fill = selected ? theme.mapSelected : visited.contains(shape.id) ? theme.mapVisited : theme.mapUnvisited
                    context.fill(shape.path, with: .color(fill), style: FillStyle(eoFill: true))
                    context.stroke(shape.path, with: .color(selected ? theme.accent : theme.border), lineWidth: (selected ? 1.3 : 0.7) / zoom)
                }
            }
            .contentShape(Rectangle())
            .gesture(SpatialTapGesture().onEnded { value in
                let point = CGPoint(x: (value.location.x - geometry.size.width / 2 - pan.width) / zoom + geometry.size.width / 2,
                                    y: (value.location.y - geometry.size.height / 2 - pan.height) / zoom + geometry.size.height / 2)
                if let province = ProvinceHitTester.province(at: point, shapes: model.shapes) { select(province) }
            })
            .simultaneousGesture(MagnifyGesture()
                .updating($magnification) { value, state, _ in state = value.magnification }
                .onEnded { value in
                    scale = min(6, max(1, scale * value.magnification))
                    offset = clamped(offset, zoom: scale, size: geometry.size)
                })
            .simultaneousGesture(DragGesture(minimumDistance: 8)
                .updating($translation) { value, state, _ in state = value.translation }
                .onEnded { value in
                    offset = clamped(CGSize(width: offset.width + value.translation.width, height: offset.height + value.translation.height), zoom: scale, size: geometry.size)
                })
            .onAppear { model.prepare(provinces: provinces, size: geometry.size) }
            .onChange(of: geometry.size) { _, size in model.prepare(provinces: provinces, size: size) }
            .onChange(of: provinces.map(\.id)) { _, _ in model.prepare(provinces: provinces, size: geometry.size) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L("Travel map. Use the place list to select a region."))
        }
    }
    private func clamped(_ value: CGSize, zoom: CGFloat, size: CGSize) -> CGSize {
        let x = size.width * (zoom - 1) / 2
        let y = size.height * (zoom - 1) / 2
        return CGSize(width: min(x, max(-x, value.width)), height: min(y, max(-y, value.height)))
    }
}
