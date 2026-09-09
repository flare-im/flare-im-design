import SwiftUI

public struct FlareTransferQueueItem: Identifiable {
    public let id: String
    public let name: String
    public let state: FlareTransferState
    public let statusText: String
    public let progress: Double?
    public let actionLabels: [FlareTransferAction:String]
    public let busy: Bool
    public init(id:String,name:String,state:FlareTransferState,statusText:String,progress:Double?=nil,actionLabels:[FlareTransferAction:String]=[:],busy:Bool=false) {
        self.id=id; self.name=name; self.state=state; self.statusText=statusText; self.progress=progress; self.actionLabels=actionLabels; self.busy=busy
    }
}
public func retryableTransferIds(_ items:[FlareTransferQueueItem]) -> [String] {
    items.filter { $0.state == .failed && !$0.busy && !($0.actionLabels[.retry] ?? "").trimmingCharacters(in:.whitespacesAndNewlines).isEmpty }.map(\.id)
}
/// Place in a bounded-height parent. The host retains task state when this view leaves the screen.
public struct TransferQueueView: View {
    let items:[FlareTransferQueueItem]
    let loading:Bool
    let error:String?
    let title:String
    let emptyText:String
    let retryFailedText:String
    let reloadText:String
    let onAction:((String,FlareTransferAction)->Void)?
    let onRetryFailed:(([String])->Void)?
    let onReload:(()->Void)?
    public init(items:[FlareTransferQueueItem],loading:Bool=false,error:String?=nil,title:String="传输队列",emptyText:String="暂无传输任务",retryFailedText:String="重试失败任务",reloadText:String="重新加载",onAction:((String,FlareTransferAction)->Void)?=nil,onRetryFailed:(([String])->Void)?=nil,onReload:(()->Void)?=nil) {
        self.items=items;self.loading=loading;self.error=error;self.title=title;self.emptyText=emptyText;self.retryFailedText=retryFailedText;self.reloadText=reloadText;self.onAction=onAction;self.onRetryFailed=onRetryFailed;self.onReload=onReload
    }
    public var body: some View {
        let ids=retryableTransferIds(items)
        VStack(alignment:.leading,spacing:8) {
            Text("\(title) · \(items.count)").font(.headline)
            if !ids.isEmpty, let onRetryFailed {
                Button { onRetryFailed(ids) } label: { Text("\(retryFailedText) (\(ids.count))").frame(minWidth:48,minHeight:48) }
            }
            if loading { ProgressView().accessibilityLabel(title) }
            if let error { StatusBannerView(text:error,tone:.danger,actionText:reloadText,onAction:loading ? nil : onReload) }
            if items.isEmpty && !loading && error == nil { Text(emptyText).padding(16) }
            ScrollView {
                LazyVStack(spacing:8) {
                    ForEach(items) { item in
                        TransferProgressView(name:item.name,state:item.state,statusText:item.statusText,progress:item.progress,actionLabels:item.actionLabels,busy:item.busy,onAction:onAction == nil ? nil : { action in onAction?(item.id,action) })
                    }
                }
            }
        }
    }
}
