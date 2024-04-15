import Foundation

/// Base protocol for `enum` types that can be used as properties of types conforming to ``CloudKitRecordRepresentable``.
public protocol CloudKitEnum {

    /// The fallback `enum` `case` to be used when decoding from `CKRecord` encounters an unknown `case`.
    ///
    /// You implement this in custom enums that can be properties of ``CloudKitRecordRepresentable`` types in order to provide
    /// a fallback value when ``CloudKitRecordDecoder`` encounters a raw value that's unknown.
    ///
    /// This can happen if for example you add more cases to your enum type in an app update. If a user has different versions of your app installed,
    /// then it's possible for data on CloudKit to contain raw values that can't be decoded by an older version of the app.
    ///
    /// - Tip: if you'd like to have the model decoding fail completely if one of its `enum` properties has an unknown raw value,
    /// then just return `nil` from your implementation.
    static var cloudKitFallbackCase: Self? { get }
}

public extension CloudKitEnum where Self: CaseIterable {
    /// Uses the first `enum` case as the fallback when decoding from `CKRecord` encounters an unknown `case`.
    static var cloudKitFallbackCase: Self? { allCases.first }
}

/// Implemented by `enum` types with `String` raw value that can be used as properties of types conforming to ``CloudKitRecordRepresentable``.
///
/// See ``CloudKitEnum`` for more details.
public protocol CloudKitStringEnum: Codable, RawRepresentable, CloudKitEnum where RawValue == String { }

/// Implemented by `enum` types with `Int` raw value that can be used as properties of types conforming to ``CloudKitRecordRepresentable``.
///
/// See ``CloudKitEnum`` for more details.
public protocol CloudKitIntEnum: Codable, RawRepresentable, CloudKitEnum where RawValue == Int { }
