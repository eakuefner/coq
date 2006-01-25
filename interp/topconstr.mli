(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, * CNRS-Ecole Polytechnique-INRIA Futurs-Universite Paris Sud *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(*i $Id$ i*)

(*i*)
open Pp
open Util
open Names
open Libnames
open Rawterm
open Term
open Mod_subst
(*i*)

(*s This is the subtype of rawconstr allowed in syntactic extensions *)
(* No location since intended to be substituted at any place of a text *)
(* Complex expressions such as fixpoints and cofixpoints are excluded, *)
(* non global expressions such as existential variables also *)

type aconstr =
  (* Part common to [rawconstr] and [cases_pattern] *)
  | ARef of global_reference
  | AVar of identifier
  | AApp of aconstr * aconstr list
  | AList of identifier * identifier * aconstr * aconstr * bool
  (* Part only in [rawconstr] *)
  | ALambda of name * aconstr * aconstr
  | AProd of name * aconstr * aconstr
  | ALetIn of name * aconstr * aconstr
  | ACases of aconstr option *
      (aconstr * (name * (inductive * name list) option)) list *
      (identifier list * cases_pattern list * aconstr) list
  | ALetTuple of name list * (name * aconstr option) * aconstr * aconstr
  | AIf of aconstr * (name * aconstr option) * aconstr * aconstr
  | ASort of rawsort
  | AHole of Evd.hole_kind
  | APatVar of patvar
  | ACast of aconstr * cast_kind * aconstr

val rawconstr_of_aconstr_with_binders : loc -> 
  (identifier -> 'a -> identifier * 'a) ->
  ('a -> aconstr -> rawconstr) -> 'a -> aconstr -> rawconstr

val rawconstr_of_aconstr : loc -> aconstr -> rawconstr

val subst_aconstr : substitution -> Names.identifier list -> aconstr -> aconstr

val aconstr_of_rawconstr : identifier list -> rawconstr -> aconstr

val eq_rawconstr : rawconstr -> rawconstr -> bool

(* [match_aconstr metas] match a rawconstr against an aconstr with
   metavariables in [metas]; it raises [No_match] if the matching fails *)
exception No_match

type scope_name = string
type interpretation = 
    (identifier * (scope_name option * scope_name list)) list * aconstr

val match_aconstr : rawconstr -> interpretation ->
      (rawconstr * (scope_name option * scope_name list)) list

(*s Concrete syntax for terms *)

type notation = string

type explicitation = ExplByPos of int | ExplByName of identifier

type proj_flag = int option (* [Some n] = proj of the n-th visible argument *)

type prim_token = Numeral of Bigint.bigint | String of string

type cases_pattern_expr =
  | CPatAlias of loc * cases_pattern_expr * identifier
  | CPatCstr of loc * reference * cases_pattern_expr list
  | CPatAtom of loc * reference option
  | CPatOr of loc * cases_pattern_expr list
  | CPatNotation of loc * notation * cases_pattern_expr list
  | CPatPrim of loc * prim_token
  | CPatDelimiters of loc * string * cases_pattern_expr

type constr_expr =
  | CRef of reference
  | CFix of loc * identifier located * fixpoint_expr list
  | CCoFix of loc * identifier located * cofixpoint_expr list
  | CArrow of loc * constr_expr * constr_expr
  | CProdN of loc * (name located list * constr_expr) list * constr_expr
  | CLambdaN of loc * (name located list * constr_expr) list * constr_expr
  | CLetIn of loc * name located * constr_expr * constr_expr
  | CAppExpl of loc * (proj_flag * reference) * constr_expr list
  | CApp of loc * (proj_flag * constr_expr) * 
        (constr_expr * explicitation located option) list
  | CCases of loc * constr_expr option *
      (constr_expr * (name option * constr_expr option)) list *
      (loc * cases_pattern_expr list * constr_expr) list
  | CLetTuple of loc * name list * (name option * constr_expr option) *
      constr_expr * constr_expr
  | CIf of loc * constr_expr * (name option * constr_expr option)
      * constr_expr * constr_expr
  | CHole of loc
  | CPatVar of loc * (bool * patvar)
  | CEvar of loc * existential_key
  | CSort of loc * rawsort
  | CCast of loc * constr_expr * cast_kind * constr_expr
  | CNotation of loc * notation * constr_expr list
  | CPrim of loc * prim_token
  | CDelimiters of loc * string * constr_expr
  | CDynamic of loc * Dyn.t

and fixpoint_expr =
    identifier * int * local_binder list * constr_expr * constr_expr

and cofixpoint_expr =
    identifier * local_binder list * constr_expr * constr_expr

and local_binder =
  | LocalRawDef of name located * constr_expr
  | LocalRawAssum of name located list * constr_expr


val constr_loc : constr_expr -> loc

val cases_pattern_loc : cases_pattern_expr -> loc

val replace_vars_constr_expr :
  (identifier * identifier) list -> constr_expr -> constr_expr

val occur_var_constr_expr : identifier -> constr_expr -> bool

(* Specific function for interning "in indtype" syntax of "match" *)
val names_of_cases_indtype : constr_expr -> identifier list

val mkIdentC : identifier -> constr_expr
val mkRefC : reference -> constr_expr
val mkAppC : constr_expr * constr_expr list -> constr_expr
val mkCastC : constr_expr * cast_kind * constr_expr -> constr_expr
val mkLambdaC : name located list * constr_expr * constr_expr -> constr_expr
val mkLetInC : name located * constr_expr * constr_expr -> constr_expr
val mkProdC : name located list * constr_expr * constr_expr -> constr_expr

val coerce_to_id : constr_expr -> identifier located

val abstract_constr_expr : constr_expr -> local_binder list -> constr_expr
val prod_constr_expr : constr_expr -> local_binder list -> constr_expr

(* For binders parsing *)

(* Includes let binders *)
val local_binders_length : local_binder list -> int

(* Does not take let binders into account *)
val names_of_local_assums : local_binder list -> name located list

(* Used in correctness and interface; absence of var capture not guaranteed *)
(* in pattern-matching clauses and in binders of the form [x,y:T(x)] *)

val map_constr_expr_with_binders :
  ('a -> constr_expr -> constr_expr) ->
      (identifier -> 'a -> 'a) -> 'a -> constr_expr -> constr_expr

(* Concrete syntax for modules and modules types *)

type with_declaration_ast = 
  | CWith_Module of identifier list located * qualid located
  | CWith_Definition of identifier list located * constr_expr

type module_type_ast = 
  | CMTEident of qualid located
  | CMTEwith of module_type_ast * with_declaration_ast

type module_ast = 
  | CMEident of qualid located
  | CMEapply of module_ast * module_ast

(* Special identifier to encode recursive notations *)
val ldots_var : identifier
