import Foundation
import UIKit
import Display
import SwiftSignalKit
import AccountContext
import NaturalLanguage
import TelegramCore
import TelegramUIPreferences
import SwiftUI
import Translation
import Combine
import AyuGramCore

// Incuding at least one Objective-C class in a swift file ensures that it doesn't get stripped by the linker
private final class LinkHelperClass: NSObject {
}

private final class AyuGramTranslationCache {
    static let shared = AyuGramTranslationCache()

    private let lock = NSLock()
    private var values: [String: (String, [MessageTextEntity])] = [:]
    private var order: [String] = []
    private let limit = 256

    func get(key: String) -> (String, [MessageTextEntity])? {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        return self.values[key]
    }

    func set(key: String, value: (String, [MessageTextEntity])) {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        if self.values[key] == nil {
            self.order.append(key)
        }
        self.values[key] = value
        while self.order.count > self.limit {
            let removedKey = self.order.removeFirst()
            self.values.removeValue(forKey: removedKey)
        }
    }
}

public var supportedTranslationLanguages = [
    "af",
    "sq",
    "am",
    "ar",
    "hy",
    "az",
    "eu",
    "be",
    "bn",
    "bs",
    "bg",
    "ca",
    "ceb",
    "zh",
    "co",
    "hr",
    "cs",
    "da",
    "nl",
    "en",
    "eo",
    "et",
    "fi",
    "fr",
    "fy",
    "gl",
    "ka",
    "de",
    "el",
    "gu",
    "ht",
    "ha",
    "haw",
    "he",
    "hi",
    "hmn",
    "hu",
    "is",
    "ig",
    "id",
    "ga",
    "it",
    "ja",
    "jv",
    "kn",
    "kk",
    "km",
    "rw",
    "ko",
    "ku",
    "ky",
    "lo",
    "lv",
    "lt",
    "lb",
    "mk",
    "mg",
    "ms",
    "ml",
    "mt",
    "mi",
    "mr",
    "mn",
    "my",
    "ne",
    "no",
    "ny",
    "or",
    "ps",
    "fa",
    "pl",
    "pt",
    "pa",
    "ro",
    "ru",
    "sm",
    "gd",
    "sr",
    "st",
    "sn",
    "sd",
    "si",
    "sk",
    "sl",
    "so",
    "es",
    "su",
    "sw",
    "sv",
    "tl",
    "tg",
    "ta",
    "tt",
    "te",
    "th",
    "tr",
    "tk",
    "uk",
    "ur",
    "ug",
    "uz",
    "vi",
    "cy",
    "xh",
    "yi",
    "yo",
    "zu"
]

public var popularTranslationLanguages = [
    "en",
    "ar",
    "zh",
    "fr",
    "de",
    "it",
    "ja",
    "ko",
    "pt",
    "ru",
    "es",
    "uk"
]

@available(iOS 12.0, *)
private let languageRecognizer = NLLanguageRecognizer()

public func effectiveIgnoredTranslationLanguages(context: AccountContext, ignoredLanguages: [String]?) -> Set<String> {
    var baseLang = context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode
    let rawSuffix = "-raw"
    if baseLang.hasSuffix(rawSuffix) {
        baseLang = String(baseLang.dropLast(rawSuffix.count))
    }

    var dontTranslateLanguages = Set<String>()
    if let ignoredLanguages = ignoredLanguages {
        dontTranslateLanguages = Set(ignoredLanguages)
    } else {
        dontTranslateLanguages.insert(baseLang)
        for language in systemLanguageCodes() {
            dontTranslateLanguages.insert(language)
        }
    }
    return dontTranslateLanguages
}

public func normalizeTranslationLanguage(_ code: String) -> String {
    var code = code
    if code.contains("-") {
        code = code.components(separatedBy: "-").first ?? code
    }
    if code == "nb" {
        code = "no"
    }
    return code
}

public func canTranslateChats(context: AccountContext) -> Bool {
    let translationConfiguration = TranslationConfiguration.with(appConfiguration: context.currentAppConfiguration.with { $0 })
    var chatTranslationAvailable = true
    switch translationConfiguration.auto {
    case .system:
        if #available(iOS 18.0, *) {
        } else {
            chatTranslationAvailable = false
        }
    case .alternative, .disabled:
        chatTranslationAvailable = false
    default:
        break
    }
    return chatTranslationAvailable
}

public func canTranslateText(context: AccountContext, text: String, showTranslate: Bool, showTranslateIfTopical: Bool = false, ignoredLanguages: [String]?) -> (canTranslate: Bool, language: String?) {
    guard showTranslate || showTranslateIfTopical, text.count > 0 else {
        return (false, nil)
    }

    let translationConfiguration = TranslationConfiguration.with(appConfiguration: context.currentAppConfiguration.with { $0 })
    var translateButtonAvailable = false
    switch translationConfiguration.manual {
    case .enabled, .alternative:
        translateButtonAvailable = true
    case .system:
        if #available(iOS 18.0, *) {
            translateButtonAvailable = true
        }
    default:
        break
    }

    let showTranslate = showTranslate && translateButtonAvailable

    if #available(iOS 12.0, *) {
        if context.sharedContext.immediateExperimentalUISettings.disableLanguageRecognition {
            return (true, nil)
        }

        let dontTranslateLanguages = effectiveIgnoredTranslationLanguages(context: context, ignoredLanguages: ignoredLanguages)

        let text = String(text.prefix(64))
        languageRecognizer.processString(text)
        let hypotheses = languageRecognizer.languageHypotheses(withMaximum: 3)
        languageRecognizer.reset()

        var supportedTranslationLanguages = supportedTranslationLanguages
        if !showTranslate && showTranslateIfTopical {
            supportedTranslationLanguages = ["uk", "ru"]
        }

        let filteredLanguages = hypotheses.filter { supportedTranslationLanguages.contains(normalizeTranslationLanguage($0.key.rawValue)) }.sorted(by: { $0.value > $1.value })
        if let language = filteredLanguages.first {
            let languageCode = normalizeTranslationLanguage(language.key.rawValue)
            return (!dontTranslateLanguages.contains(languageCode), languageCode)
        } else {
            return (false, nil)
        }
    } else {
        return (false, nil)
    }
}

public func systemLanguageCodes() -> [String] {
    var languages: [String] = []
    for language in Locale.preferredLanguages.prefix(2) {
        let language = language.components(separatedBy: "-").first ?? language
        languages.append(language)
    }
    if languages.count == 2 && languages != ["en", "ru"] {
        languages = Array(languages.prefix(1))
    }
    return languages
}

@available(iOS 13.0, *)
class ExternalTranslationTrigger: ObservableObject {
    @Published var shouldInvalidate: Int = 0
}

@available(iOS 18.0, *)
private struct TranslationViewImpl: View {
    @State private var configuration: TranslationSession.Configuration?
    @ObservedObject var externalCondition: ExternalTranslationTrigger
    private let taskContainer: Atomic<ExperimentalInternalTranslationServiceImpl.TranslationTaskContainer>

    init(externalCondition: ExternalTranslationTrigger, taskContainer: Atomic<ExperimentalInternalTranslationServiceImpl.TranslationTaskContainer>) {
        self.externalCondition = externalCondition
        self.taskContainer = taskContainer
    }

    var body: some View {
        Text("ABC")
        .onChange(of: self.externalCondition.shouldInvalidate) { _ in
            let firstTaskLanguagePair = self.taskContainer.with { taskContainer -> (String, String)? in
                if let firstTask = taskContainer.tasks.first {
                    return (firstTask.fromLang, firstTask.toLang)
                } else {
                    return nil
                }
            }

            if let firstTaskLanguagePair {
                if let configuration = self.configuration, configuration.source?.languageCode?.identifier == firstTaskLanguagePair.0, configuration.target?.languageCode?.identifier == firstTaskLanguagePair.1 {
                    self.configuration?.invalidate()
                } else {
                    self.configuration = .init(
                        source: Locale.Language(identifier: firstTaskLanguagePair.0),
                        target: Locale.Language(identifier: firstTaskLanguagePair.1)
                    )
                }
            }
        }
        .translationTask(self.configuration, action: { session in
            var task: ExperimentalInternalTranslationServiceImpl.TranslationTask?
            task = self.taskContainer.with { taskContainer -> ExperimentalInternalTranslationServiceImpl.TranslationTask? in
                if !taskContainer.tasks.isEmpty {
                    return taskContainer.tasks.removeFirst()
                } else {
                    return nil
                }
            }

            guard let task else {
                return
            }

            do {
                var nextClientIdentifier: Int = 0
                var clientIdentifierMap: [String: AnyHashable] = [:]
                let translationRequests = task.texts.map { key, value in
                    let id = nextClientIdentifier
                    nextClientIdentifier += 1
                    clientIdentifierMap["\(id)"] = key
                    return TranslationSession.Request(sourceText: value, clientIdentifier: "\(id)")
                }

                let responses = try await session.translations(from: translationRequests)
                var resultMap: [AnyHashable: String] = [:]
                for response in responses {
                    if let clientIdentifier = response.clientIdentifier, let originalKey = clientIdentifierMap[clientIdentifier] {
                        resultMap[originalKey] = "\(response.targetText)"
                    }
                }

                task.completion(resultMap)
            } catch let e {
                print("Translation error: \(e)")
                task.completion(nil)
            }

            let firstTaskLanguagePair = self.taskContainer.with { taskContainer -> (String, String)? in
                if let firstTask = taskContainer.tasks.first {
                    return (firstTask.fromLang, firstTask.toLang)
                } else {
                    return nil
                }
            }

            if let firstTaskLanguagePair {
                if let configuration = self.configuration, configuration.source?.languageCode?.identifier == firstTaskLanguagePair.0, configuration.target?.languageCode?.identifier == firstTaskLanguagePair.1 {
                    self.configuration?.invalidate()
                } else {
                    self.configuration = .init(
                        source: Locale.Language(identifier: firstTaskLanguagePair.0),
                        target: Locale.Language(identifier: firstTaskLanguagePair.1)
                    )
                }
            }
        })
    }
}

@available(iOS 18.0, *)
public final class ExperimentalInternalTranslationServiceImpl: ExperimentalInternalTranslationService {
    fileprivate final class TranslationTask {
        let id: Int
        let texts: [AnyHashable: String]
        let fromLang: String
        let toLang: String
        let completion: ([AnyHashable: String]?) -> Void

        init(id: Int, texts: [AnyHashable: String], fromLang: String, toLang: String, completion: @escaping ([AnyHashable: String]?) -> Void) {
            self.id = id
            self.texts = texts
            self.fromLang = fromLang
            self.toLang = toLang
            self.completion = completion
        }
    }

    fileprivate final class TranslationTaskContainer {
        var tasks: [TranslationTask] = []

        init() {
        }
    }

    private final class Impl {
        private let hostingController: UIViewController

        private let taskContainer = Atomic(value: TranslationTaskContainer())
        private let taskTrigger = ExternalTranslationTrigger()

        private var nextId: Int = 0

        init(view: UIView) {
            self.hostingController = UIHostingController(rootView: TranslationViewImpl(
                externalCondition: self.taskTrigger,
                taskContainer: self.taskContainer
            ))

            view.addSubview(self.hostingController.view)
        }

        func translate(texts: [AnyHashable: String], fromLang: String, toLang: String, onResult: @escaping ([AnyHashable: String]?) -> Void) -> Disposable {
            let id = self.nextId
            self.nextId += 1
            self.taskContainer.with { taskContainer in
                taskContainer.tasks.append(TranslationTask(
                    id: id,
                    texts: texts,
                    fromLang: fromLang,
                    toLang: toLang,
                    completion: { result in
                        onResult(result)
                    }
                ))
            }
            self.taskTrigger.shouldInvalidate += 1

            return ActionDisposable { [weak self] in
                Queue.mainQueue().async {
                    guard let self else {
                        return
                    }
                    self.taskContainer.with { taskContainer in
                        taskContainer.tasks.removeAll(where: { $0.id == id })
                    }
                }
            }
        }
    }

    private let impl: QueueLocalObject<Impl>

    public init(view: UIView) {
        self.impl = QueueLocalObject(queue: .mainQueue(), generate: {
            return Impl(view: view)
        })
    }

    public func translate(texts: [AnyHashable: String], fromLang: String, toLang: String) -> Signal<[AnyHashable: String]?, NoError> {
        return self.impl.signalWith { impl, subscriber in
            return impl.translate(texts: texts, fromLang: fromLang, toLang: toLang, onResult: { result in
                subscriber.putNext(result)
                subscriber.putCompletion()
            })
        }
    }
}

func ayuGramTranslationProvider(context: AccountContext) -> Signal<AyuTranslationProvider, NoError> {
    return context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.ayuGramSettings])
    |> take(1)
    |> map { sharedData -> AyuTranslationProvider in
        return ayuGramSettings(sharedData: sharedData).translationProvider
    }
}

func alternativeTranslateText(text: String, fromLang: String?, toLang: String, provider: AyuTranslationProvider = .google) -> Signal<(String, [MessageTextEntity])?, TelegramCore.TranslationError> {
    return Signal { subscriber in
        var task: URLSessionTask?
        Queue.concurrentDefaultQueue().async {
            let effectiveFromLang: String
            if let fromLang {
                effectiveFromLang = fromLang
            } else {
                languageRecognizer.processString(text)
                let hypotheses = languageRecognizer.languageHypotheses(withMaximum: 3)
                languageRecognizer.reset()

                let filteredLanguages = hypotheses.filter { supportedTranslationLanguages.contains(normalizeTranslationLanguage($0.key.rawValue)) }.sorted(by: { $0.value > $1.value })
                if let language = filteredLanguages.first {
                    let languageCode = normalizeTranslationLanguage(language.key.rawValue)
                    effectiveFromLang = languageCode
                } else {
                    effectiveFromLang = "en"
                }
            }

            let cacheKey = "\(provider.rawValue)|\(effectiveFromLang)|\(toLang)|\(text)"
            if let cached = AyuGramTranslationCache.shared.get(key: cacheKey) {
                subscriber.putNext(cached)
                subscriber.putCompletion()
                return
            }

            let uri: String
            switch provider {
            case .telegram, .native:
                subscriber.putError(.generic)
                return
            case .google:
                var googleUri = "https://translate.goo"
                googleUri += "gleapis.com/transl"
                googleUri += "ate_a"
                googleUri += "/singl"
                googleUri += "e?client=gtx&sl=\(effectiveFromLang.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                googleUri += "&tl=\(toLang.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                googleUri += "&dt=t&ie=UTF-8&oe=UTF-8&otf=1&ssel=0&tsel=0&kc=7&dt=at&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&q="
                googleUri += text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                uri = googleUri
            case .yandex:
                var yandexUri = "https://translate.yandex.net/api/v1/tr.json/translate?srv=tr-text"
                yandexUri += "&lang=\(effectiveFromLang.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")-\(toLang.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                yandexUri += "&text="
                yandexUri += text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                uri = yandexUri
            }

            guard let url = URL(string: uri) else {
                subscriber.putError(.generic)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(getRandomUserAgent(), forHTTPHeaderField: "User-Agent")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Translation failed: \(error.localizedDescription)")
                    subscriber.putError(.generic)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    subscriber.putError(.generic)
                    return
                }

                if httpResponse.statusCode != 200 {
                    print("Translation failed with status code: \(httpResponse.statusCode)")
                    let isRateLimit = httpResponse.statusCode == 429
                    subscriber.putError(isRateLimit ? .limitExceeded : .generic)
                    return
                }

                guard let data = data else {
                    subscriber.putError(.generic)
                    return
                }

                do {
                    var result = ""
                    switch provider {
                    case .google:
                        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [Any] else {
                            subscriber.putError(.generic)
                            return
                        }
                        guard let translationArray = jsonArray.first as? [Any] else {
                            subscriber.putError(.generic)
                            return
                        }
                        for element in translationArray {
                            if let translationBlock = element as? [Any],
                               translationBlock.count > 0,
                               let blockText = translationBlock[0] as? String,
                               blockText != "null" && !blockText.isEmpty {
                                result += blockText
                            }
                        }
                    case .yandex:
                        guard let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                            subscriber.putError(.generic)
                            return
                        }
                        if let textArray = jsonDict["text"] as? [String] {
                            result = textArray.joined(separator: "\n")
                        }
                    case .telegram, .native:
                        break
                    }

                    if text.hasPrefix("\n") {
                        result = "\n" + result
                    }
                    if result.isEmpty {
                        subscriber.putError(.generic)
                        return
                    }

                    let value = (result, [MessageTextEntity]())
                    AyuGramTranslationCache.shared.set(key: cacheKey, value: value)
                    subscriber.putNext(value)
                    subscriber.putCompletion()
                } catch {
                    print("JSON parsing error: \(error)")
                    subscriber.putError(.generic)
                }
            }
            task?.resume()
        }
        return ActionDisposable {
            task?.cancel()
        }
    }
}

func getRandomUserAgent() -> String {
    let userAgents = [
        "Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1"
    ]
    return userAgents.randomElement() ?? userAgents[0]
}
