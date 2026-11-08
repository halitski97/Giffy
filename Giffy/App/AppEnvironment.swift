import Observation

@Observable
final class AppEnvironment {
    let sourceLoader: SourceLoader

    init(sourceLoader: SourceLoader = SourceLoader()) {
        self.sourceLoader = sourceLoader
    }
}
