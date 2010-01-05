(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, * CNRS-Ecole Polytechnique-INRIA Futurs-Universite Paris Sud *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(*i $Id$ i*)

Require Export NAxioms NSub.

(** This functor summarizes all known facts about N.
    For the moment it is only an alias to [NSubPropFunct], which
    subsumes all others.
*)

Module Type NPropSig := NSubPropFunct.

Module NPropFunct (N:NAxiomsSig). (* <: NPropSig N.  BUG !! *)
 Include Type NPropSig N.
End NPropFunct.
