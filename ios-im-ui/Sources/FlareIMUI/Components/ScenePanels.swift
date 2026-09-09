import SwiftUI

public enum FlareCapabilityState { case loading, available, unavailable, denied, failed }
public struct FlareSceneAction:Identifiable {
 public let id:String;public let label:String;public let destructive:Bool;public let disabled:Bool
 public init(id:String,label:String,destructive:Bool=false,disabled:Bool=false){self.id=id;self.label=label;self.destructive=destructive;self.disabled=disabled}
}
public struct FlareSceneEntry:Identifiable {
 public let id:String;public let title:String;public let detail:String;public let badge:String?;public let busy:Bool;public let actions:[FlareSceneAction];public let error:String?
 public init(id:String,title:String,detail:String,badge:String?=nil,busy:Bool=false,actions:[FlareSceneAction]=[],error:String?=nil){self.id=id;self.title=title;self.detail=detail;self.badge=badge;self.busy=busy;self.actions=actions;self.error=error}
}
public struct FlareDeviceSessionEntry {
 public let entry:FlareSceneEntry;public let current:Bool
 public init(entry:FlareSceneEntry,current:Bool=false){self.entry=entry;self.current=current}
}
public enum FlareMediaAvailability {case available,expired,unavailable}
public enum FlareMediaKind {case image,video,audio,file}
public struct FlareMediaEntry {
 public let entry:FlareSceneEntry;public let kind:FlareMediaKind;public let availability:FlareMediaAvailability
 public init(entry:FlareSceneEntry,kind:FlareMediaKind,availability:FlareMediaAvailability){self.entry=entry;self.kind=kind;self.availability=availability}
}
public struct FlareNotificationPreference:Identifiable {
 public let id:String;public let title:String;public let detail:String;public let value:Bool;public let enabled:Bool;public let busy:Bool
 public init(id:String,title:String,detail:String,value:Bool,enabled:Bool,busy:Bool=false){self.id=id;self.title=title;self.detail=detail;self.value=value;self.enabled=enabled;self.busy=busy}
}
private struct SceneList:View {
 let title:String;let items:[FlareSceneEntry];let loading:Bool;let error:String?;let onAction:((String,String)->Void)?;let onReload:(()->Void)?
 var body:some View {
  VStack(alignment:.leading,spacing:8) {
   Text(title).font(.headline)
   if loading {ProgressView().accessibilityLabel(title)}
   if let error {StatusBannerView(text:error,tone:.danger,actionText:"重试",onAction:loading ? nil : onReload)}
   if items.isEmpty && !loading && error == nil {Text("暂无内容").padding(16)}
   ForEach(items) { item in
    VStack(alignment:.leading,spacing:8){Text(item.title).font(.headline);if let badge=item.badge {Text(badge).font(.caption)};Text(item.detail)
     if let error=item.error {StatusBannerView(text:error,tone:.danger)}
     if item.busy {ProgressView().accessibilityLabel(item.title)}
     ForEach(item.actions.filter{!$0.label.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty}) { a in
      Button(role:a.destructive ? .destructive : nil){onAction?(item.id,a.id)} label:{Text(a.label).frame(minWidth:48,minHeight:48)}.disabled(item.busy || a.disabled || onAction == nil)
     }
    }.frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,12)
   }
  }
 }
}
public struct MemberPanelView:View {
 let items:[FlareSceneEntry];let title:String;let loading:Bool;let error:String?;let onAction:((String,String)->Void)?;let onReload:(()->Void)?
 public init(items:[FlareSceneEntry],title:String="群成员",loading:Bool=false,error:String?=nil,onAction:((String,String)->Void)?=nil,onReload:(()->Void)?=nil){self.items=items;self.title=title;self.loading=loading;self.error=error;self.onAction=onAction;self.onReload=onReload}
 public var body:some View {SceneList(title:title,items:items,loading:loading,error:error,onAction:onAction,onReload:onReload)}
}
public struct DeviceSessionsView:View {
 let items:[FlareDeviceSessionEntry];let title:String;let currentText:String;let loading:Bool;let error:String?;let onAction:((String,String)->Void)?;let onReload:(()->Void)?
 public init(items:[FlareDeviceSessionEntry],title:String="登录设备",currentText:String="当前设备",loading:Bool=false,error:String?=nil,onAction:((String,String)->Void)?=nil,onReload:(()->Void)?=nil){self.items=items;self.title=title;self.currentText=currentText;self.loading=loading;self.error=error;self.onAction=onAction;self.onReload=onReload}
 public var body:some View {SceneList(title:title,items:items.map{i in FlareSceneEntry(id:i.entry.id,title:i.entry.title,detail:i.entry.detail,badge:i.current ? currentText : i.entry.badge,busy:i.entry.busy,actions:i.current ? [] : i.entry.actions,error:i.entry.error)},loading:loading,error:error,onAction:onAction,onReload:onReload)}
}
public struct MediaCenterView:View {
 let items:[FlareMediaEntry];let transfers:[FlareTransferQueueItem]?;let title:String;let loading:Bool;let error:String?;let onAction:((String,String)->Void)?;let onReload:(()->Void)?;let onTransferAction:((String,FlareTransferAction)->Void)?;let onRetryFailed:(([String])->Void)?
 public init(items:[FlareMediaEntry],transfers:[FlareTransferQueueItem]?=nil,title:String="文件与媒体",loading:Bool=false,error:String?=nil,onAction:((String,String)->Void)?=nil,onReload:(()->Void)?=nil,onTransferAction:((String,FlareTransferAction)->Void)?=nil,onRetryFailed:(([String])->Void)?=nil){self.items=items;self.transfers=transfers;self.title=title;self.loading=loading;self.error=error;self.onAction=onAction;self.onReload=onReload;self.onTransferAction=onTransferAction;self.onRetryFailed=onRetryFailed}
 public var body:some View {VStack {SceneList(title:title,items:items.map{i in FlareSceneEntry(id:i.entry.id,title:i.entry.title,detail:i.entry.detail,badge:i.entry.badge,busy:i.entry.busy,actions:i.entry.actions.filter{i.availability == .available || $0.id != "open"},error:i.entry.error)},loading:loading,error:error,onAction:onAction,onReload:onReload)
 if let transfers {TransferQueueView(items:transfers,onAction:onTransferAction,onRetryFailed:onRetryFailed).frame(height:400)}
 }}
}
public struct CapabilityBoundaryView<Content:View>:View {
 let state:FlareCapabilityState;let text:String;let actionText:String?;let onAction:(()->Void)?;let content:()->Content
 public init(state:FlareCapabilityState,text:String,actionText:String?=nil,onAction:(()->Void)?=nil,@ViewBuilder content:@escaping ()->Content){self.state=state;self.text=text;self.actionText=actionText;self.onAction=onAction;self.content=content}
 public var body:some View {if state == .available {content()} else {VStack {if state == .loading {ProgressView().accessibilityLabel(text)};StatusBannerView(text:text,tone:state == .failed ? .danger : .neutral,actionText:actionText,onAction:state == .loading ? nil : onAction)}}}
}
public struct NotificationPreferencesView:View {
 let items:[FlareNotificationPreference];let permission:FlareCapabilityState;let permissionText:String;let permissionActionText:String?;let title:String;let onChange:((String,Bool)->Void)?;let onPermissionAction:(()->Void)?
 public init(items:[FlareNotificationPreference],permission:FlareCapabilityState,permissionText:String,permissionActionText:String?=nil,title:String="通知设置",onChange:((String,Bool)->Void)?=nil,onPermissionAction:(()->Void)?=nil){self.items=items;self.permission=permission;self.permissionText=permissionText;self.permissionActionText=permissionActionText;self.title=title;self.onChange=onChange;self.onPermissionAction=onPermissionAction}
 public var body:some View {VStack(alignment:.leading,spacing:12){Text(title).font(.headline);CapabilityBoundaryView(state:permission,text:permissionText,actionText:permissionActionText,onAction:onPermissionAction){Text(permissionText)}
 ForEach(items){i in Toggle(isOn:Binding(get:{i.value},set:{onChange?(i.id,$0)})){VStack(alignment:.leading){Text(i.title);Text(i.detail).font(.caption)}}.frame(minHeight:48).disabled(permission != .available || !i.enabled || i.busy || onChange == nil)}
 }}
}
/// Present inside a sheet; host keeps it open after failures. Interactive dismissal is blocked while busy.
public struct DangerConfirmView:View {
 let title:String;let description:String;let target:String;let busy:Bool;let error:String?;let confirmText:String;let cancelText:String;let onConfirm:()->Void;let onCancel:()->Void
 public init(title:String,description:String,target:String,busy:Bool=false,error:String?=nil,confirmText:String="确认",cancelText:String="取消",onConfirm:@escaping ()->Void,onCancel:@escaping ()->Void){self.title=title;self.description=description;self.target=target;self.busy=busy;self.error=error;self.confirmText=confirmText;self.cancelText=cancelText;self.onConfirm=onConfirm;self.onCancel=onCancel}
 public var body:some View {ScrollView{VStack(alignment:.leading,spacing:12){Text(title).font(.headline);Text(description);Text(target).bold();if let error {Text(error)};Button(action:onCancel){Text(cancelText).frame(minWidth:48,minHeight:48)}.disabled(busy);Button(role:.destructive,action:onConfirm){Text(confirmText).frame(minWidth:48,minHeight:48)}.disabled(busy)}.padding(20)}.interactiveDismissDisabled(busy)}
}
