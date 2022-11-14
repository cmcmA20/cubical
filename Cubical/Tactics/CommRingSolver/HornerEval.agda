{-# OPTIONS --safe #-}
module Cubical.Tactics.CommRingSolver.HornerEval where

open import Cubical.Foundations.Prelude

open import Cubical.Data.Nat using (ℕ)
open import Cubical.Data.Int hiding (_+_ ; _·_ ; -_)
open import Cubical.Data.Vec
open import Cubical.Data.Bool

open import Cubical.Relation.Nullary.Base using (¬_; yes; no)

open import Cubical.Tactics.CommRingSolver.Utility
open import Cubical.Tactics.CommRingSolver.RawAlgebra
open import Cubical.Tactics.CommRingSolver.IntAsRawRing
open import Cubical.Tactics.CommRingSolver.HornerForms
open import Cubical.Algebra.CommRing
open import Cubical.Algebra.Ring

private
  variable
    ℓ ℓ' : Level

module HornerEval (A : RawAlgebra ℤAsRawRing ℓ') where
  open RawAlgebra A
  
  eval : {n : ℕ}
         → (P : IteratedHornerForms n)
         → Vec ⟨ A ⟩ n → ⟨ A ⟩
  eval (const r) [] = RawAlgebra.scalar A r
  eval 0H (_ ∷ _) = 0r
  eval (P ·X+ Q) (x ∷ xs) =
       let P' = (eval P (x ∷ xs))
           Q' = eval Q xs
       in if (isZero A P)
          then Q'
          else P' · x + Q'

module _ (R : CommRing ℓ) where
  private
    νR = CommRing→RawℤAlgebra R
  open CommRingStr (snd R)
  open RingTheory (CommRing→Ring R)
  open IteratedHornerOperations νR
  open HornerEval νR
  
  someCalculation : {x : fst R} → _ ≡ _
  someCalculation {x = x} =
    0r                   ≡⟨ sym (+IdR 0r) ⟩
    0r + 0r              ≡[ i ]⟨ 0LeftAnnihilates x (~ i) + 0r ⟩
    0r · x + 0r          ∎


  evalIsZero : {n : ℕ} (P : IteratedHornerForms n)
             → (l : Vec (fst R) n)
             → isZero νR P ≡ true
             → eval P l ≡ 0r
  evalIsZero (const (pos ℕ.zero)) [] isZeroP = refl
  evalIsZero (const (pos (ℕ.suc n))) [] isZeroP = byBoolAbsurdity isZeroP
  evalIsZero (const (negsuc _)) [] isZeroP = byBoolAbsurdity isZeroP
  evalIsZero 0H (x ∷ xs) _ = refl
  evalIsZero {n = ℕ.suc n} (P ·X+ Q) (x ∷ xs) isZeroPandQ with isZero νR P
  ... | true = eval Q xs   ≡⟨ evalIsZero Q xs isZeroQ ⟩
               0r ∎
               where isZeroQ = snd (extractFromAnd _ _ isZeroPandQ)
  ... | false = byBoolAbsurdity isZeroP
               where isZeroP = fst (extractFromAnd _ _ isZeroPandQ)

  computeEvalSummandIsZero :
               {n : ℕ}
               (P : IteratedHornerForms (ℕ.suc n))
               (Q : IteratedHornerForms n)
             → (xs : Vec (fst R) n)
             → (x : (fst R))
             → isZero νR P ≡ true
             → eval (P ·X+ Q) (x ∷ xs) ≡ eval Q xs
  computeEvalSummandIsZero P Q xs x isZeroP with isZero νR P
  ... | true = refl
  ... | false = byBoolAbsurdity isZeroP

  computeEvalNotZero :
               {n : ℕ}
               (P : IteratedHornerForms (ℕ.suc n))
               (Q : IteratedHornerForms n)
             → (xs : Vec (fst R) n)
             → (x : (fst R))
             → ¬ (isZero νR P ≡ true)
             → eval (P ·X+ Q) (x ∷ xs) ≡ (eval P (x ∷ xs)) · x + eval Q xs
  computeEvalNotZero P Q xs x notZeroP with isZero νR P
  ... | true = byBoolAbsurdity (sym (¬true→false true notZeroP))
  ... | false = refl

  combineCasesEval :
    {n : ℕ}  (P : IteratedHornerForms (ℕ.suc n)) (Q : IteratedHornerForms n)
    (x : (fst R)) (xs : Vec (fst R) n)
    →   eval (P ·X+ Q) (x ∷ xs)
      ≡ (eval P (x ∷ xs)) · x + eval Q xs
  combineCasesEval P Q x xs with isZero νR P ≟ true
  ... | yes p =
       eval (P ·X+ Q) (x ∷ xs)            ≡⟨ computeEvalSummandIsZero P Q xs x p ⟩
       eval Q xs                          ≡⟨ sym (+IdL _) ⟩
       0r + eval Q xs                     ≡[ i ]⟨ 0LeftAnnihilates x (~ i) + eval Q xs ⟩
       0r · x + eval Q xs                 ≡[ i ]⟨ (evalIsZero P (x ∷ xs) p (~ i)) · x + eval Q xs ⟩
       (eval P (x ∷ xs)) · x + eval Q xs ∎
  ... | no p  = computeEvalNotZero P Q xs x p


  compute+ₕEvalBothZero :
    (n : ℕ) (P Q : IteratedHornerForms (ℕ.suc n))
    (r s : IteratedHornerForms n)
    (x : (fst R)) (xs : Vec (fst R) n)
    → (isZero νR (P +ₕ Q) and isZero νR (r +ₕ s)) ≡ true
    → eval ((P ·X+ r) +ₕ (Q ·X+ s)) (x ∷ xs) ≡ eval ((P +ₕ Q) ·X+ (r +ₕ s)) (x ∷ xs)
  compute+ₕEvalBothZero n P Q r s x xs bothZero with isZero νR (P +ₕ Q) and isZero νR (r +ₕ s) | bothZero
  ... | true | p =
               eval 0H (x ∷ xs)                            ≡⟨ refl ⟩
               0r                                                   ≡⟨ someCalculation ⟩
               0r · x + 0r                                          ≡⟨ step1  ⟩
               (eval (P +ₕ Q) (x ∷ xs)) · x + eval (r +ₕ s) xs       ≡⟨ step2 ⟩
               eval ((P +ₕ Q) ·X+ (r +ₕ s)) (x ∷ xs) ∎
            where step1 : 0r · x + 0r ≡ (eval (P +ₕ Q) (x ∷ xs)) · x + eval (r +ₕ s) xs
                  step1 i = (evalIsZero (P +ₕ Q) (x ∷ xs) (fst (extractFromAnd _ _ (bothZero))) (~ i)) · x
                    + (evalIsZero (r +ₕ s) xs (snd (extractFromAnd _ _ (bothZero))) (~ i))
                  step2 = sym (combineCasesEval (P +ₕ Q) (r +ₕ s) x xs)
  ... | false | p = byBoolAbsurdity p

  compute+ₕEvalNotBothZero :
    (n : ℕ) (P Q : IteratedHornerForms (ℕ.suc n))
    (r s : IteratedHornerForms n)
    (x : (fst R)) (xs : Vec (fst R) n)
    → (isZero νR (P +ₕ Q) and isZero νR (r +ₕ s)) ≡ false
    → eval ((P ·X+ r) +ₕ (Q ·X+ s)) (x ∷ xs) ≡ eval ((P +ₕ Q) ·X+ (r +ₕ s)) (x ∷ xs)
  compute+ₕEvalNotBothZero n P Q r s _ _ notBothZero
    with isZero νR (P +ₕ Q) and isZero νR (r +ₕ s) | notBothZero
  ... | true | p = byBoolAbsurdity (sym p)
  ... | false | p = refl
