/// This is kept as a seperate library from the generator intentionally to
/// minimize transitive dependencies of types that are annotated as
/// serializable.
library source_gen.json_serial.annotation;

class JsonSerializable {
  final bool createFactory;
  final bool createToJson;

  const JsonSerializable({bool createFactory: true, bool createToJson: true})
      : this.createFactory = createFactory,
        this.createToJson = createToJson;
}
