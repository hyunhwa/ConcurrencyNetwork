# ConcurrencyNetwork

Swift 5.5에 발표된 Concurrency로 구현한 간단한 네트워크 모듈입니다.

Rest API 요청, 다운로드, 네트워크 상태 모니터링, 업로드 기능을 지원합니다.

모듈 지원을 위한 최소 사양은 다음과 같습니다.

```swift
platforms: [.macOS(.v11), .iOS(.v14), .tvOS(.v14), .watchOS(.v7)]
```

## 시작하기

`Package.swift`에 아래와 같이 종속성을 추가합니다. 

```swift
.package(url: "https://github.com/hyunhwa/ConcurrencyNetwork.git", from: "0.0.1"),
```

```swift
.target(name: "ExampleApp", dependencies: [
    .product(name: "ConcurrencyAPI", package: "ConcurrencyNetwork")
],
```

## 사용방법

### Rest API 요청

아래와 같이 API 프로토콜을 구현합니다.

```swift
enum SampleAPI {
    case getSampleData
    case saveSampleData
}

extension SampleAPI: API {
    var baseUrlString: String {
        "https://your-api-endpoint.com"
    }

    var path: String {
        switch self {
        case .getSampleData,
            .saveSampleData:
            return "/SampleData"
        }
    }
    ...
}
```

Async 방식으로 응답 데이터(Codable)를 가져올 수 있습니다.

```swift
struct SampleResponse: Codable, Equatable { 
    ... 
}

let response = try await SampleAPI
    .getSampleData
    .request()
    .response(SampleResponse.self)
```

### 다운로드 요청

아래와 같이 Downloadable 프로토콜을 구현합니다.

```swift
struct DownloadableObject {
    let fileURL: URL
}

extension DownloadableObject: Downloadable {
    var directoryURL: URL {
        let directoryPaths = NSSearchPathForDirectoriesInDomains(
            .libraryDirectory,
            .userDomainMask,
            true
        )
        
        let directoryURL = URL(fileURLWithPath: directoryPaths.first!)
        return directoryURL.appendingPathComponent("ConcurrencyDownload")
    }
    
    var sourceURL: URL {
        get throws {
            fileURL
        }
    }
}
```

다운로더 객체를 선언합니다.

```swift
let downloader = Downloader(
    progressInterval: 1, // 진행률 업데이트 이벤트를 수신 간격
    maxActiveTask: 1 // 동시에 활성화될 downloadTask 숫자
)
```

단일 다운로드 이벤트를 수신하기 위해서 다음과 같이 호출 가능합니다.

```swift
for try await event in try await downloader.events(
    fileInfo: downloadableObject
) {
    switch event {
    // 다운로드 진행률
    case let .update(currentBytes, totalBytes):
    // 다운로드 완료
    case let .completed(data, downloadInfo):
    // 다운로드 시작
    case let .start(index, _):
}
```

멀티 다운로드 이벤트를 수신하실 때는 다음과 같이 호출 가능합니다.
```swift
for try await event in try await downloader.events(
    fileInfos: downloadableObjects
) {
    switch event {
    // 전체 다운로드 완료
    case .allCompleted(downloadInfos):
    // 단일 다운로드 이벤트 수신
    case let .unit(unitEvents):
        for try await unitEvent in unitEvents {
            switch unitEvent {
            case let .completed(data, downloadInfo):
            case let .update(currentBytes, totalBytes):
            case let .start(index, _):
        }
    // 전체 다운로드 시작
    case let .start(downloadInfos: downloadInfos):
    }
}
```
