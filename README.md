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
            return "/RealData"
        }
    }
    ...
}
```

async 방식으로 응답 데이터(Codable)를 가져올 수 있습니다.

```swift
struct SampleResponse: Codable, Equatable { ... }

let response = try await SampleAPI.getSampleData.request(responseAs: SampleResponse.self)
```
