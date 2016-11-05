signature ML_COND = sig
  val isabelle_version: string

  val cond_exec: Input.source -> string list -> generic_theory -> generic_theory
end

structure ML_Cond: ML_COND = struct

val isabelle_version = getenv_strict "ISABELLE_VERSION"

val _ = writeln ("Initializing ML_COND with ISABELLE_VERSION=" ^ isabelle_version)

fun cond_exec source versions =
  member op = versions isabelle_version ?
    ML_Context.exec (fn () =>
        ML_Context.eval_source (ML_Compiler.verbose true ML_Compiler.flags) source) #>
      Local_Theory.propagate_ml_env

val _ =
  let
    val parse_versions = Args.parens (Parse.list Parse.string)
  in
    Outer_Syntax.command @{command_keyword ML_cond} "ML text within theory or local theory (conditional)"
      (parse_versions -- Parse.ML_source >> (fn (versions, source) =>
        Toplevel.generic_theory (cond_exec source versions)))
  end

end