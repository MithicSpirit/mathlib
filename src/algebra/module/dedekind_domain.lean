/-
Copyright (c) 2022 Pierre-Alexandre Bazin. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Pierre-Alexandre Bazin
-/
import algebra.module.torsion
import ring_theory.dedekind_domain.ideal

/-!
# Modules over a Dedekind domain

Over a Dedekind domain, a `I`-torsion module is the internal direct sum of its `p i ^ e i`-torsion
submodules, where `I = ∏ i, p i ^ e i` is its unique decomposition in prime ideals.
Therefore, as any finitely generated torsion module is `I`-torsion for some `I`, it is an internal
direct sum of its `p i ^ e i`-torsion submodules for some prime ideals `p i` and numbers `e i`.
-/

universes u v
open_locale big_operators

variables {R : Type u} [comm_ring R] [is_domain R] {M : Type v} [add_comm_group M] [module R M]

open_locale direct_sum

namespace submodule
variables [is_dedekind_domain R]
open unique_factorization_monoid

open_locale classical

/--Over a Dedekind domain, a `I`-torsion module is the internal direct sum of its `p i ^ e i`-
torsion submodules, where `I = ∏ i, p i ^ e i` is its unique decomposition in prime ideals.-/
lemma is_internal_prime_power_torsion_of_is_torsion_by_ideal {I : ideal R} (hI : I ≠ ⊥)
  (hM : module.is_torsion_by_set R M I) :
  direct_sum.is_internal (λ p : (factors I).to_finset,
    torsion_by_set R M (p ^ (factors I).count p : ideal R)) :=
begin
  let P := factors I,
  have prime_of_mem := λ p (hp : p ∈ P.to_finset), prime_of_factor p (multiset.mem_to_finset.mp hp),
  apply @torsion_by_set_is_internal _ _ _ _ _ _ _ _ (λ p, p ^ P.count p) _,
  { convert hM,
    rw [← finset.inf_eq_infi, is_dedekind_domain.inf_prime_pow_eq_prod,
      ← finset.prod_multiset_count, ← associated_iff_eq],
    { exact factors_prod hI },
    { exact prime_of_mem }, { exact λ _ _ _ _ ij, ij } },
  { intros p hp q hq pq, dsimp,
    rw irreducible_pow_sup,
    { suffices : (normalized_factors _).count p = 0,
      { rw [this, zero_min, pow_zero, ideal.one_eq_top] },
      { rw [multiset.count_eq_zero, normalized_factors_of_irreducible_pow
          (prime_of_mem q hq).irreducible, multiset.mem_replicate],
        exact λ H, pq $ H.2.trans $ normalize_eq q } },
    { rw ← ideal.zero_eq_bot, apply pow_ne_zero, exact (prime_of_mem q hq).ne_zero },
    { exact (prime_of_mem p hp).irreducible } }
end

/--A finitely generated torsion module over a Dedekind domain is an internal direct sum of its
`p i ^ e i`-torsion submodules where `p i` are factors of `(⊤ : submodule R M).annihilator` and
`e i` are their multiplicities. -/
theorem is_internal_prime_power_torsion [module.finite R M] (hM : module.is_torsion R M) :
  direct_sum.is_internal (λ p : (factors (⊤ : submodule R M).annihilator).to_finset,
    torsion_by_set R M (p ^ (factors (⊤ : submodule R M).annihilator).count p : ideal R)) :=
begin
  have hM' := module.is_torsion_by_set_annihilator_top R M,
  have hI := submodule.annihilator_top_inter_non_zero_divisors hM,
  refine is_internal_prime_power_torsion_of_is_torsion_by_ideal _ hM',
  rw ←set.nonempty_iff_ne_empty at hI, rw submodule.ne_bot_iff,
  obtain ⟨x, H, hx⟩ := hI, exact ⟨x, H, non_zero_divisors.ne_zero hx⟩
end

/--A finitely generated torsion module over a Dedekind domain is an internal direct sum of its
`p i ^ e i`-torsion submodules for some prime ideals `p i` and numbers `e i`.-/
theorem exists_is_internal_prime_power_torsion [module.finite R M] (hM : module.is_torsion R M) :
  ∃ (P : finset $ ideal R) [decidable_eq P] [∀ p ∈ P, prime p] (e : P → ℕ),
  by exactI direct_sum.is_internal (λ p : P, torsion_by_set R M (p ^ e p : ideal R)) :=
⟨_, _, λ p hp, prime_of_factor p (multiset.mem_to_finset.mp hp), _,
    is_internal_prime_power_torsion hM⟩

end submodule
