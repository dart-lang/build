import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:built_value/built_value.dart';
import 'dart_types.dart';

/// Common logic between `ValueSourceField` and `SerializerSourceField`.
mixin FieldMixin {
  PropertyInducingElement? get builderElement;
  ParsedLibraryResult get parsedLibrary;

  bool get builderFieldExists => builderElement != null;

  /// The type written in the declaration of the manual builder field, read
  /// from the AST, or null if the field is not declared with a type.
  ///
  /// The type follows any `late`, `final` or `covariant` keyword.
  String? get builderFieldDeclaredType {
    final declarationList = parsedLibrary
        .getFragmentDeclaration(builderElement!.firstFragment)
        ?.node
        .parent;
    if (declarationList is! VariableDeclarationList) return null;
    return declarationList.type?.toSource();
  }

  /// Gets the type of the field in a manually written builder.
  ///
  /// Returns `dynamic` if there is no such field.
  ///
  /// Goes via the AST if needed. This happens if the type has not been
  /// generated yet, which will be the case for a nested builder field if the
  /// builder is in this same library.
  @memoized
  String get fullBuildElementType {
    if (!builderFieldExists) return 'dynamic';

    // Try to get a resolved type first, it's faster.
    var result = DartTypes.tryGetName(
      builderElement!.getter?.returnType,
      withNullabilitySuffix: true,
    );

    if (result != null && result != 'dynamic') return result;
    // Go via AST to allow use of unresolvable types not yet generated;
    // this includes generated Builder types.
    result = builderFieldDeclaredType;

    if (result != null) return result;

    result = builderElement!.getter != null
        ? (parsedLibrary
                .getFragmentDeclaration(
                  builderElement!.getter!.firstFragment,
                )
                ?.node as MethodDeclaration?)
            ?.returnType
            .toString()
        : null;

    return result ?? 'dynamic';
  }
}
