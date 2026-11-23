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
 private let groups:[FlareCallDeviceGroup];private let permission:FlareCapabilityState;private let permissionText:String;private let actionText:String?;private let placeholder:String?;private let onSelect:((FlareCallDeviceKind,String)->Void)?;private let onPermissionAction:(()->Void)?
 @Environment(\.flareStrings) private var strings
 @Environment(\.flareBrandTheme) private var flareBrandTheme
 public init(groups:[FlareCallDeviceGroup],permission:FlareCapabilityState,permissionText:String,actionText:String?=nil,placeholder:String?=nil,onSelect:((FlareCallDeviceKind,String)->Void)?=nil,onPermissionAction:(()->Void)?=nil){self.groups=groups;self.permission=permission;self.permissionText=permissionText;self.actionText=actionText;self.placeholder=placeholder;self.onSelect=onSelect;self.onPermissionAction=onPermissionAction}
 public var body:some View {
  #if os(macOS)
  panel
  #else
  // iPhone and iPad route through the host's system key in the control bar's `devices` slot (§12.14).
  VStack(alignment:.leading,spacing:FlareSizes.spacingMd){
   CapabilityBoundaryView(state:permission,text:permissionText,actionText:actionText,onAction:onPermissionAction){Text(permissionText)}
   ForEach(groups,id:\.kind){group in
    let devices=group.uniqueDevices
    let enabled=permission == .available && !group.busy && devices.contains{!$0.disabled} && onSelect != nil
    Picker(group.label,selection:Binding(get:{devices.contains{$0.id==group.selectedId} ? group.selectedId! : ""},set:{id in if enabled && devices.contains(where:{$0.id==id && !$0.disabled}){onSelect?(group.kind,id)}})){
     Text(placeholder ?? strings.selectDevice).tag("")
     ForEach(devices){device in Text(device.label).tag(device.id).disabled(device.disabled)}
    }.pickerStyle(.menu).frame(maxWidth:.infinity,minHeight:FlareSizes.touchTarget,alignment:.leading).disabled(!enabled)
   }
  }
  #endif
 }

 /// §3.6 on a pointer: the panel the host's device key pops over — 280 wide on the call popover colour, radius card,
 /// padding md; per group a 12 title (a spinner after it while the group switches, its rows off) and single-choice
 /// rows 44 high, the name 14 on one line, the chosen one with check 16 at its end.
 private var panel: some View {
  let c = FlareColors.of(.dark, brand: flareBrandTheme)
  return VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
   CapabilityBoundaryView(state: permission, text: permissionText, actionText: actionText, onAction: onPermissionAction) { Text(permissionText) }
   ForEach(groups, id: \.kind) { group in
    let enabled = permission == .available && !group.busy && onSelect != nil
    VStack(alignment: .leading, spacing: 0) {
     HStack(spacing: FlareSizes.spacingXs) {
      Text(group.label).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(c.callOnStageSecondary)
      if group.busy { ProgressView().controlSize(.mini).tint(c.callOnStageSecondary) }
     }
     .accessibilityAddTraits(.isHeader)
     ForEach(group.uniqueDevices) { device in
      let chosen = device.id == group.selectedId
      Button { onSelect?(group.kind, device.id) } label: {
       HStack(spacing: FlareSizes.spacingSm) {
        Text(device.label).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(c.callOnStage)
         .lineLimit(1).truncationMode(.tail)
        Spacer(minLength: 0)
        if chosen { IconView("check", size: FlareSizes.iconSizeSm, color: c.callOnStage) }
       }
       .padding(.horizontal, FlareSizes.spacingXs)
       .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTargetMin)
       .contentShape(Rectangle())
      }
      .buttonStyle(FlarePressStyle(fill: .clear, pressed: c.callControlHover,
                                   shape: AnyShape(RoundedRectangle(cornerRadius: FlareSizes.radiusSm))))
      .disabled(!enabled || device.disabled)
      .accessibilityAddTraits(chosen ? .isSelected : [])
     }
    }
   }
  }
  .padding(FlareSizes.spacingMd)
  .frame(width: FlareSizes.componentCallDevicePanelWidth, alignment: .leading)
  .background(RoundedRectangle(cornerRadius: FlareSizes.radiusCard).fill(c.callPopover))
 }
}
