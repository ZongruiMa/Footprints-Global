import SwiftUI

struct PhotoViewer: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let provinceID: String
    @State private var selectedID: String
    @State private var choosing = false
    @State private var showDate = false
    init(provinceID: String, initialID: String) {
        self.provinceID = provinceID
        _selectedID = State(initialValue: initialID)
    }
    private var photos: [PhotoSnapshot] { state.photos(in: provinceID) }
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            let currentIndex = photos.firstIndex { $0.id == selectedID } ?? 0
            TabView(selection: $selectedID) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    Group {
                        if abs(index - currentIndex) <= 1 { ZoomablePhotoView(photo: photo) }
                        else { Color.black }
                    }.tag(photo.id)
                }
            }.tabViewStyle(.page(indexDisplayMode: .never)).ignoresSafeArea(edges: .bottom)
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel(L("Close photo"))
                Spacer()
                Text("\((photos.firstIndex { $0.id == selectedID } ?? 0) + 1) / \(photos.count)").font(.caption).foregroundStyle(.gray)
                Spacer()
                Menu {
                    Button(L("Reassign")) { choosing = true }
                    Button(L("View date")) { showDate = true }
                    Button(L("Remove from Footprints"), role: .destructive) { let id = selectedID; Task { await state.removePhoto(id) } }
                } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }.accessibilityLabel(L("Photo actions"))
            }.foregroundStyle(.white).padding(.horizontal, 12).background(.black)
        }
        .sheet(isPresented: $choosing) { ProvincePicker { province in
            let id = selectedID
            Task { await state.assign([id], to: province) }
        } }
        .alert(L("Date taken"), isPresented: $showDate) { Button(L("OK"), role: .cancel) {} } message: {
            Text(photos.first { $0.id == selectedID }?.creationDate?.formatted(date: .abbreviated, time: .shortened) ?? L("No date recorded."))
        }
        .onChange(of: photos.map(\.id)) { _, ids in
            if ids.isEmpty { dismiss() }
            else if !ids.contains(selectedID), let first = ids.first { selectedID = first }
        }
        .statusBarHidden()
    }
}

struct ZoomablePhotoView: UIViewControllerRepresentable {
    let photo: PhotoSnapshot
    func makeUIViewController(context: Context) -> ZoomController { ZoomController(photo: photo) }
    func updateUIViewController(_ controller: ZoomController, context: Context) {
        controller.host.rootView = PhotoThumbnailView(photo: photo, fit: true, pixels: 2560)
    }
    @MainActor final class ZoomController: UIViewController, UIScrollViewDelegate {
        let host: UIHostingController<PhotoThumbnailView>
        private let scroll = UIScrollView()
        init(photo: PhotoSnapshot) {
            host = UIHostingController(rootView: PhotoThumbnailView(photo: photo, fit: true, pixels: 2560))
            super.init(nibName: nil, bundle: nil)
        }
        @available(*, unavailable)
        required init?(coder: NSCoder) { return nil }
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            scroll.minimumZoomScale = 1
            scroll.maximumZoomScale = 4
            scroll.showsVerticalScrollIndicator = false
            scroll.showsHorizontalScrollIndicator = false
            scroll.backgroundColor = .black
            scroll.delegate = self
            scroll.panGestureRecognizer.isEnabled = false
            scroll.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(scroll)
            addChild(host)
            guard let hosted = host.view else { return }
            hosted.backgroundColor = .clear
            hosted.translatesAutoresizingMaskIntoConstraints = false
            scroll.addSubview(hosted)
            NSLayoutConstraint.activate([
                scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scroll.topAnchor.constraint(equalTo: view.topAnchor),
                scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                hosted.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
                hosted.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
                hosted.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
                hosted.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
                hosted.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
                hosted.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
            ])
            host.didMove(toParent: self)
            let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
            tap.numberOfTapsRequired = 2
            scroll.addGestureRecognizer(tap)
        }
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { host.view }
        func scrollViewDidZoom(_ scrollView: UIScrollView) { scrollView.panGestureRecognizer.isEnabled = scrollView.zoomScale > 1.01 }
        @objc func doubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scroll = gesture.view as? UIScrollView else { return }
            if scroll.zoomScale > 1.01 { scroll.setZoomScale(1, animated: true) }
            else {
                let point = gesture.location(in: host.view)
                let size = CGSize(width: scroll.bounds.width / 2.5, height: scroll.bounds.height / 2.5)
                scroll.zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height), animated: true)
            }
        }
    }
}
