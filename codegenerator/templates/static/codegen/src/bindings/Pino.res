type logLevelBuiltin = [
  | #trace
  | #debug
  | #info
  | #warn
  | #error
  | #fatal
]
@genType
type logLevelUser = [
  | #userDebug
  | #userInfo
  | #userWarn
  | #userError
]
type logLevel = [logLevelBuiltin | logLevelUser]

type pinoConfig = {level: logLevel}

type pinoMessageBlob
type t = {
  trace: (. pinoMessageBlob) => unit,
  debug: (. pinoMessageBlob) => unit,
  info: (. pinoMessageBlob) => unit,
  warn: (. pinoMessageBlob) => unit,
  error: (. pinoMessageBlob) => unit,
  fatal: (. pinoMessageBlob) => unit,
}
@send external errorWithExn: (t, exn, pinoMessageBlob) => unit = "error"

@module("pino") external make: pinoConfig => t = "default"

// Bind to the 'level' property getter
@get external getLevel: t => logLevel = "level"

@ocaml.doc(`Get the available logging levels`) @get
external levels: t => 'a = "levels"

// Bind to the 'level' property setter
@set external setLevel: (t, logLevel) => unit = "level"

@ocaml.doc(`Identity function to help co-erce any type to a pino log message`)
let createPinoMessage = (message): pinoMessageBlob => Obj.magic(message)

module Trasport = {
  type t
  @module("pino")
  external make: 'a => t = "transport"
}

@module("pino") external makeWithTransport: Trasport.t => t = "default"

type hooks = {logMethod: (array<string>, string, logLevel) => unit}

type formatters = {
  level: (string, int) => Js.Json.t,
  bindings: Js.Json.t => Js.Json.t,
  log: Js.Json.t => Js.Json.t,
}

type serializers = {err: Js.Json.t => Js.Json.t}

type options = {
  name?: string,
  level?: logLevel,
  customLevels?: Js.Dict.t<int>,
  useOnlyCustomLevels?: bool,
  depthLimit?: int,
  edgeLimit?: int,
  mixin?: unit => Js.Json.t,
  mixinMergeStrategy?: (Js.Json.t, Js.Json.t) => Js.Json.t,
  redact?: array<string>,
  hooks?: hooks,
  formatters?: formatters,
  serializers?: serializers,
  msgPrefix?: string,
  base?: Js.Json.t,
  enabled?: bool,
  crlf?: bool,
  timestamp?: bool,
  messageKey?: string,
}

@module("pino") external makeWithOptionsAndTransport: (options, Trasport.t) => t = "default"

type childParams
let createChildParams: 'a => childParams = Obj.magic
@send external child: (t, childParams) => t = "child"

module ECS = {
  @module
  external make: 'a => options = "@elastic/ecs-pino-format"
}
