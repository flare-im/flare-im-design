import SwiftUI

public enum FlareCallDeviceKind: String, Sendable { case microphone, speaker, camera }
public struct FlareCallDevice: Identifiable, Sendable {
 public let id:String; public let label:String; public let disabled:Bool
 public init(id:String,label:String,disabled:Bool=false){self.id=id;self.label=label;self.disabled=disabled}
}
public struct FlareCallDeviceGroup: Sendable {
 public let kind:FlareCallDeviceKind;public let label:String;public let selectedId:String?;public let devices:[FlareCallDevice];public let busy:Bool
 public init(kind:FlareCallDeviceKind,label:String,selectedId:String?=nil,devices:[FlareCallDevice],busy:Bool=false){self.kind=kind;self.label=label;self.selectedId=selectedId;self.devices=devices;self.busy=busy}
 public var uniqueDevices:[FlareCallDevice]{var ids=Set<String>();return devices.filter{!$0.id.isEmpty&&ids.insert($0.id).inserted}}
}
public struct CallDevicePickerView:View {
 private let groups:[FlareCallDeviceGroup];private let permission:FlareCapabilityState;private let permissionText:String;private let actionText:String?;private let placeholder:String;private let onSelect:((FlareCallDeviceKind,String)->Void)?;private let onPermissionAction:(()->Void)?
 public init(groups:[FlareCallDeviceGroup],permission:FlareCapabilityState,permissionText:String,actionText:String?=nil,placeholder:String="选择设备",onSelect:((FlareCallDeviceKind,String)->Void)?=nil,onPermissionAction:(()->Void)?=nil){self.groups=groups;self.permission=permission;self.permissionText=permissionText;self.actionText=actionText;self.placeholder=placeholder;self.onSelect=onSelect;self.onPermissionAction=onPermissionAction}
 public var body:some View {
  VStack(alignment:.leading,spacing:12){
   CapabilityBoundaryView(state:permission,text:permissionText,actionText:actionText,onAction:onPermissionAction){Text(permissionText)}
   ForEach(groups,id:\.kind){group in
    let devices=group.uniqueDevices
    let enabled=permission == .available && !group.busy && devices.contains{!$0.disabled} && onSelect != nil
    Picker(group.label,selection:Binding(get:{devices.contains{$0.id==group.selectedId} ? group.selectedId! : ""},set:{id in if enabled && devices.contains(where:{$0.id==id && !$0.disabled}){onSelect?(group.kind,id)}})){
     Text(placeholder).tag("")
     ForEach(devices){device in Text(device.label).tag(device.id).disabled(device.disabled)}
    }.pickerStyle(.menu).frame(maxWidth:.infinity,minHeight:48,alignment:.leading).disabled(!enabled)
   }
  }
 }
}
