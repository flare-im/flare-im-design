import Foundation

public func flareScanPluginCanRefresh(visible: Bool, foreground: Bool, loading: Bool, refreshing: Bool, busy: Bool, interaction: Bool) -> Bool {
    visible && foreground && !loading && !refreshing && !busy && !interaction
}
