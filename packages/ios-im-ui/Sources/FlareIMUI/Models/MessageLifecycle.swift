import Foundation

public enum FlareMessageSendState: String, Sendable { case draft, sending, sent, failed }
public enum FlareMessageLifecycleDeliveryState: String, Sendable { case serverAccepted, delivered, partiallyDelivered }
public enum FlareMessageReadState: String, Sendable { case unread, partiallyRead, read }
public enum FlareMessageMutationState: String, Sendable { case normal, edited, recalled, deleted }
public enum FlareMessageEphemeralState: String, Sendable { case none, readOnce, burnAfterRead, expired }

/// UI-facing lifecycle projection mapped from authoritative host state.
public struct FlareMessageLifecycle: Sendable {
    public let transfer: FlareTransferState
    public let send: FlareMessageSendState
    public let delivery: FlareMessageLifecycleDeliveryState
    public let read: FlareMessageReadState
    public let mutation: FlareMessageMutationState
    public let ephemeral: FlareMessageEphemeralState

    public init(
        transfer: FlareTransferState = .idle,
        send: FlareMessageSendState = .sent,
        delivery: FlareMessageLifecycleDeliveryState = .serverAccepted,
        read: FlareMessageReadState = .unread,
        mutation: FlareMessageMutationState = .normal,
        ephemeral: FlareMessageEphemeralState = .none
    ) {
        self.transfer = transfer
        self.send = send
        self.delivery = delivery
        self.read = read
        self.mutation = mutation
        self.ephemeral = ephemeral
    }

    public var visualStatus: FlareMessageDeliveryStatus {
        if send == .failed || transfer == .failed { return .failed }
        if send == .draft || transfer == .queued { return .pending }
        if send == .sending || transfer == .transferring || transfer == .paused { return .sending }
        // Delivery has no glyph of its own: a single check is "the server has it", a double check "read"
        // (spec/message-receipt-vectors.json). The delivery dimension stays in the lifecycle for hosts that
        // need it; it never changes what the row draws.
        if read == .read { return .read }
        return .sent
    }
}
