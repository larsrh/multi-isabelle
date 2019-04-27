signature ML_COND = sig
  val isabelle_version: string

  type pattern = {wildcard: string, negate: bool}

  val raw_match: (char list * char list) -> bool
  val match: pattern -> string -> bool

  val cond_exec: Input.source -> pattern list -> generic_theory -> generic_theory
end

structure ML_Cond: ML_COND = struct

val isabelle_version =
  case try getenv_strict "ISABELLE_IDENTIFIER" of
    SOME id => unprefix "Isabelle" id
  | NONE => getenv_strict "ISABELLE_VERSION"

type pattern = {wildcard: string, negate: bool}

fun raw_match ([], []) = true
  | raw_match (#"*" :: ps, v :: vs) =
      raw_match (ps, vs) (* consume exactly one *) orelse
        raw_match (#"*" :: ps, vs) (* consume one or more *) orelse
        raw_match (ps, v :: vs) (* consume zero *)
  | raw_match (#"*" :: ps, []) = raw_match (ps, [])
  | raw_match (p :: ps, v :: vs) = p = v andalso raw_match (ps, vs)
  | raw_match _ = false

fun match {wildcard, negate} version =
  let
    val negate = negate ? not
    val result = raw_match (String.explode wildcard, String.explode version)
  in
    negate result
  end

val _ = writeln ("Initializing ML_COND with ISABELLE_VERSION=" ^ isabelle_version)

fun cond_exec source patterns =
  exists (fn pattern => match pattern isabelle_version) patterns ?
    ML_Context.exec (fn () =>
        ML_Context.eval_source (ML_Compiler.verbose true ML_Compiler.flags) source) #>
      Local_Theory.propagate_ml_env

val _ =
  let
    val parse_version =
      Parse.string >> (fn version => {wildcard = version, negate = false}) ||
        (Args.$$$ "~" |-- Parse.string) >> (fn version => {wildcard = version, negate = true})

    val parse_versions =
      Args.parens (Parse.list parse_version)
  in
    Outer_Syntax.command @{command_keyword ML_cond} "ML text within theory or local theory (conditional)"
      (parse_versions -- Parse.ML_source >> (fn (versions, source) =>
        Toplevel.generic_theory (cond_exec source versions)))
  end

end