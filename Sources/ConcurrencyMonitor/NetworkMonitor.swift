//
//  NetworkMonitor.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/06/29.
//

import Foundation
import Network

/// 네트워크 모니터링 이벤트
public enum NetworkMonitorEvent: Equatable {
    /// 네트워크 모니터링 시작 (초기 상태 반환)
    case start(isConnected: Bool, isCellular: Bool)
    /// 네트워크 연결 상태 변경
    case updateStatus(isConnected: Bool)
    /// 네트워크 타입 변경
    case updateInterfaceType(isCellular: Bool)
}

/// 네트워크 모니터
///
/// 네트워크 상태를 모니터링 합니다.
///
/// 온/오프라인 여부와 네트워크 상태 변화 이벤트를 수신할 수 있습니다.
///
/// 다음과 같이 사용하실 수 있습니다.
/// ```swift
/// let monitor = NetworkMonitor()
///
/// /// 모니터링 시작
/// func startMonitoring() async {
///     for await event in await monitor.events {
///         switch event {
///         case let .start(isConnected, isCellular):
///             self.isConnected = isConnected
///             self.isCellular = isCellular
///         case let .updateStatus(isConnected):
///             self.isConnected = isConnected
///         case let .updateInterfaceType(isCellular):
///             self.isCellular = isCellular
///         }
///     }
/// }
///
/// /// 모니터링 멈춤
/// func stopMonitoring() async {
///     await monitor.stop()
/// }
/// ```
///
/// 전역에서 싱글톤 객체로 사용하려는 경우 프로젝트에서 @globalActor 키워드를 붙여 Class나 Struct를 생성합니다.
/// ```swift
/// @globalActor
/// struct GlobalNetworkMonitor {
///     static var shared = NetworkMonitor()
/// }
///```
///```swift
/// @globalActor
/// final class GlobalNetworkMonitor {
///     static var shared = NetworkMonitor()
/// }
/// ```
public actor NetworkMonitor {
    /// 네트워크 모니터 (재시작이 필요한 경우 새로 생성한다 - 중단 후 재시작 불가)
    private var monitor: NWPathMonitor?
    /// 모니터링 시작여부를 판별할 수 있는 값 (값의 존재 유무로 판별)
    private var currentPath: NWPath?
    /// 네트워크 모니터링 이벤트
    private var continuation: AsyncStream<NetworkMonitorEvent>.Continuation?
    /// 네트워크 연결 여부
    public private(set) var isConnected: Bool?
    /// 데이터 셀룰러 상태 여부 확인
    public private(set) var isCellular: Bool?
    
    public init(
        continuation: AsyncStream<NetworkMonitorEvent>.Continuation? = nil,
        isConnected: Bool? = nil,
        isCellular: Bool? = nil
    ) {
        self.continuation = continuation
        self.isConnected = isConnected
        self.isCellular = isCellular
    }
    
    /// 네트워크 상태 모니터링 이벤트 수신
    public var events: AsyncStream<NetworkMonitorEvent> {
        AsyncStream { continuation in
            self.continuation = continuation
            
            if monitor == nil {
                monitor = .init()
                monitor?.start(queue: .main)
            }
            
            monitor?.pathUpdateHandler = { path in
                Task {
                    await self.setCurrentPath(path)
                }
            }
        }
    }
    
    /// 네트워크 상태 모니터링 중지
    public func stop() {
        monitor?.cancel()
        monitor = nil
        currentPath = nil
    }
    
    private func setCurrentPath(_ currentPath: NWPath) async {
        let isConnected = currentPath.status == .satisfied
        await self.setConnnected(isConnected)
        
        let isCellular = currentPath.usesInterfaceType(.cellular)
        await self.setCellular(isCellular)
        
        if self.currentPath == nil {
            continuation?.yield(.start(isConnected: isConnected, isCellular: isCellular))
        }
        
        self.currentPath = currentPath
    }
    
    private func setConnnected(_ isConnected: Bool) async {
        guard isConnected != self.isConnected
        else { return }
        
        if self.isConnected != nil {
            continuation?.yield(.updateStatus(isConnected: isConnected))
        }
        self.isConnected = isConnected
    }
    
    private func setCellular(_ isCellular: Bool) async {
        guard isCellular != self.isCellular
        else { return }
        
        if self.isCellular != nil {
            continuation?.yield(.updateInterfaceType(isCellular: isCellular))
        }
        self.isCellular = isCellular
    }
}
