use tokio::time::Duration;

pub struct SyncConfigDefaults {
    pub initial_block_interval: u32,
    pub backoff_multiplicative: f32,
    pub acceleration_additive: u32,
    pub interval_ceiling: u32,
    pub backoff_millis: u32,
    pub query_timeout_millis: u32,
}

pub const SYNC_CONFIG: SyncConfigDefaults = SyncConfigDefaults {
    initial_block_interval: 10_000,
    backoff_multiplicative: 0.8,
    acceleration_additive: 2_000,
    interval_ceiling: 10_000,
    backoff_millis: 5000,
    query_timeout_millis: 20_000,
};

pub const JAVASCRIPT_RESERVED_WORDS: &[&str] = &[
    "abstract",
    "arguments",
    "await",
    "boolean",
    "break",
    "byte",
    "case",
    "catch",
    "char",
    "class",
    "const",
    "continue",
    "debugger",
    "default",
    "delete",
    "do",
    "double",
    "else",
    "enum",
    "eval",
    "export",
    "extends",
    "false",
    "final",
    "finally",
    "float",
    "for",
    "function",
    "goto",
    "if",
    "implements",
    "import",
    "in",
    "instanceof",
    "int",
    "interface",
    "let",
    "long",
    "native",
    "new",
    "null",
    "package",
    "private",
    "protected",
    "public",
    "return",
    "short",
    "static",
    "super",
    "switch",
    "synchronized",
    "this",
    "throw",
    "throws",
    "transient",
    "true",
    "try",
    "typeof",
    "var",
    "void",
    "volatile",
    "while",
    "with",
    "yield",
];

pub const TYPESCRIPT_RESERVED_WORDS: &[&str] = &[
    "any",
    "as",
    "boolean",
    "break",
    "case",
    "catch",
    "class",
    "const",
    "constructor",
    "continue",
    "declare",
    "default",
    "delete",
    "do",
    "else",
    "enum",
    "export",
    "extends",
    "false",
    "finally",
    "for",
    "from",
    "function",
    "get",
    "if",
    "implements",
    "import",
    "in",
    "instanceof",
    "interface",
    "let",
    "module",
    "new",
    "null",
    "number",
    "of",
    "package",
    "private",
    "protected",
    "public",
    "require",
    "return",
    "set",
    "static",
    "string",
    "super",
    "switch",
    "symbol",
    "this",
    "throw",
    "true",
    "try",
    "type",
    "typeof",
    "var",
    "void",
    "while",
    "with",
    "yield",
];

pub const RESCRIPT_RESERVED_WORDS: &[&str] = &[
    "and",
    "as",
    "assert",
    "constraint",
    "else",
    "exception",
    "external",
    "false",
    "for",
    "if",
    "in",
    "include",
    "lazy",
    "let",
    "module",
    "mutable",
    "of",
    "open",
    "rec",
    "switch",
    "true",
    "try",
    "type",
    "when",
    "while",
    "with",
];

// maximum backoff period for fetching files from IPFS
pub const MAXIMUM_BACKOFF: Duration = Duration::from_secs(32);
