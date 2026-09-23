/// Weaves contract programming checks into a copy of Dart source.
///
/// A Dart imitation of Cofoja, Contracts for Java. Contracts are written as
/// expression strings in annotations, and woven into a throwaway copy of the
/// source for runs that want them checked. Nothing is generated into the
/// repository and no dependency is added to the code under contract: the
/// annotations are matched by name, so each package declares its own.
library;

export 'src/transform.dart'
    show
        ContractImportRule,
        transformContracts,
        transformDirectory,
        transformFile;
