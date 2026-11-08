import FactoryKit

/// DI registration point: every Services/ type resolvable via `@Injected` is registered here.
extension Container {
    var sourceLoader: Factory<SourceLoader> {
        self { SourceLoader() }
    }

    var sizeEstimateService: Factory<SizeEstimateService> {
        self { SizeEstimateService() }
    }

    var saveFolderService: Factory<SaveFolderService> {
        self { SaveFolderService() }
    }

    var pasteboard: Factory<Pasteboard> {
        self { Pasteboard() }
    }

    var fileActions: Factory<FileActions> {
        self { FileActions() }
    }

    @MainActor
    var conversionQueue: Factory<ConversionQueue> {
        self { ConversionQueue() }.singleton
    }
}
