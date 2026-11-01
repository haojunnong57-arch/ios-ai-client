import Foundation

enum AppError: Error, LocalizedError, Equatable {
    case invalidURL
    case invalidAPIKey
    case httpStatus(Int, String)
    case network(underlying: String)
    case decoding
    case streamCancelled
    case modelNotAvailable
    case searchUnavailable
    case storage(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "接口地址无效，请检查 Base URL。"
        case .invalidAPIKey: return "API Key 无效或未填写，请在模型设置中检查。"
        case .httpStatus(let code, let body):
            if code == 401 { return "API Key 未授权（401），请检查密钥。" }
            if code == 429 { return "请求过于频繁或额度已用尽（429），请稍后再试。" }
            if code >= 500 { return "服务端错误（\(code)），请稍后再试。" }
            return "请求失败（\(code)）：\(body)"
        case .network(let u): return "网络错误：\(u)"
        case .decoding: return "返回数据解析失败。"
        case .streamCancelled: return "已停止生成。"
        case .modelNotAvailable: return "当前模型暂不可用。"
        case .searchUnavailable: return "联网搜索暂不可用。"
        case .storage(let m): return "存储错误：\(m)"
        case .unknown(let m): return m
        }
    }
}
