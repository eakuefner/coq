open Ascent;;
open Evd;;
open Proof_type;;
open Environ;;
open Term;;

val translate_goal : goal -> ct_RULE;;
val translate_constr : env -> constr -> ct_FORMULA;;
