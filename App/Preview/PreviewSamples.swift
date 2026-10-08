#if DEBUG
import SwiftUI

@MainActor enum PreviewSamples {
    static func make() -> AppState {
        let state = AppState()
        state.isLoading = false
        state.snapshot.settings.hasCompletedOnboarding = true
        if let url = Bundle.main.url(forResource: "china_provinces", withExtension: "geojson"),
           let data = try? Data(contentsOf: url), let regions = try? MapGeometryLoader.decode(data) { state.provinces = regions }
        for (province, count) in [("320000",3),("510000",5),("530000",2)] {
            let samples = (0..<count).map { index in
                let photo = PhotoRecord(id: "preview:\(province):\(index)")
                photo.manualProvinceID = province
                photo.creationDate = Date(timeIntervalSince1970: 1_700_000_000 + Double(index * 86_400))
                return PhotoSnapshot(photo)
            }
            state.photosByProvince[province] = samples
            state.snapshot.photos += samples
        }
        state.snapshot.provinces["320000"] = ProvinceSnapshot(note: "第一次真正见到‘梅子黄时雨’。", manualVisited: false)
        return state
    }
}
#Preview("地图 · 仅预览数据") { MapScreen().environment(PreviewSamples.make()) }
#Preview("江苏 · 仅预览数据") {
    let state = PreviewSamples.make()
    if let province = state.provinces.first(where: { $0.id == "320000" }) { ProvinceSheet(province: province).environment(state) }
}
#endif
