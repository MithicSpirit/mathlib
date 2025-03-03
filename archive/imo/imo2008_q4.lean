/-
Copyright (c) 2021 Manuel Candales. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Manuel Candales
-/
import data.real.basic
import data.real.sqrt
import data.real.nnreal
import tactic.linear_combination

/-!
# IMO 2008 Q4
Find all functions `f : (0,∞) → (0,∞)` (so, `f` is a function from the positive real
numbers to the positive real numbers) such that
      ```
      (f(w)^2 + f(x)^2)/(f(y^2) + f(z^2)) = (w^2 + x^2)/(y^2 + z^2)
      ```
for all positive real numbers `w`, `x`, `y`, `z`, satisfying `wx = yz`.

# Solution
The desired theorem is that either `f = λ x, x` or `f = λ x, 1/x`
-/

open real

namespace imo

lemma abs_eq_one_of_pow_eq_one (x : ℝ) (n : ℕ) (hn : n ≠ 0) (h : x ^ n = 1) : |x| = 1 :=
by rw [← pow_left_inj (abs_nonneg x) zero_le_one (pos_iff_ne_zero.2 hn), one_pow, pow_abs, h,
  abs_one]

theorem imo2008_q4
  (f : ℝ → ℝ)
  (H₁ : ∀ x > 0, f(x) > 0) :
  (∀ w x y z : ℝ, 0 < w → 0 < x → 0 < y → 0 < z → w * x = y * z →
    (f(w) ^ 2 + f(x) ^ 2) / (f(y ^ 2) + f(z ^ 2)) = (w ^ 2 + x ^ 2) / (y ^ 2 + z ^ 2)) ↔
  ((∀ x > 0, f(x) = x) ∨ (∀ x > 0, f(x) = 1 / x)) :=
begin
  split, swap,
  -- proof that f(x) = x and f(x) = 1/x satisfy the condition
  { rintros (h | h),
    { intros w x y z hw hx hy hz hprod,
      rw [h w hw, h x hx, h (y ^ 2) (pow_pos hy 2), h (z ^ 2) (pow_pos hz 2)] },
    { intros w x y z hw hx hy hz hprod,
      rw [h w hw, h x hx, h (y ^ 2) (pow_pos hy 2), h (z ^ 2) (pow_pos hz 2)],
      have hy2z2 : y ^ 2 + z ^ 2 ≠ 0 := ne_of_gt (add_pos (pow_pos hy 2) (pow_pos hz 2)),
      have hz2y2 : z ^ 2 + y ^ 2 ≠ 0 := ne_of_gt (add_pos (pow_pos hz 2) (pow_pos hy 2)),
      have hp2 : w ^ 2 * x ^ 2 = y ^ 2 * z ^ 2,
      { linear_combination (w * x + y * z)*hprod },
      field_simp [ne_of_gt hw, ne_of_gt hx, ne_of_gt hy, ne_of_gt hz, hy2z2, hz2y2, hp2],
      ring } },

  -- proof that the only solutions are f(x) = x or f(x) = 1/x
  intro H₂,
  have h₀ : f(1) ≠ 0, { specialize H₁ 1 zero_lt_one, exact ne_of_gt H₁ },

  have h₁ : f(1) = 1,
  { specialize H₂ 1 1 1 1 zero_lt_one zero_lt_one zero_lt_one zero_lt_one rfl,
    norm_num [← two_mul] at H₂,
    rw mul_div_mul_left (f(1) ^ 2) (f 1) two_ne_zero at H₂,
    rwa ← (div_eq_iff h₀).mpr (sq (f 1)) },

  have h₂ : ∀ x > 0, (f(x) - x) * (f(x) - 1 / x) = 0,
  { intros x hx,
    have h1xss : 1 * x = (sqrt x) * (sqrt x), { rw [one_mul, mul_self_sqrt (le_of_lt hx)] },
    specialize H₂ 1 x (sqrt x) (sqrt x) zero_lt_one hx (sqrt_pos.mpr hx) (sqrt_pos.mpr hx) h1xss,
    rw [h₁, one_pow 2, sq_sqrt (le_of_lt hx), ← two_mul (f(x)), ← two_mul x] at H₂,
    have hx_ne_0 : x ≠ 0 := ne_of_gt hx,
    have hfx_ne_0 : f(x) ≠ 0, { specialize H₁ x hx, exact ne_of_gt H₁ },
    field_simp at H₂ ⊢,
    linear_combination 1/2 * H₂ },

  have h₃ : ∀ x > 0, f(x) = x ∨ f(x) = 1 / x, { simpa [sub_eq_zero] using h₂ },

  by_contra' h,
  rcases h with ⟨⟨b, hb, hfb₁⟩, ⟨a, ha, hfa₁⟩⟩,
  obtain hfa₂ := or.resolve_right (h₃ a ha) hfa₁, -- f(a) ≠ 1/a, f(a) = a
  obtain hfb₂ := or.resolve_left (h₃ b hb) hfb₁,  -- f(b) ≠ b, f(b) = 1/b

  have hab : a * b > 0 := mul_pos ha hb,
  have habss : a * b = sqrt(a * b) * sqrt(a * b) := (mul_self_sqrt (le_of_lt hab)).symm,

  specialize H₂ a b (sqrt (a * b)) (sqrt (a * b)) ha hb (sqrt_pos.mpr hab) (sqrt_pos.mpr hab) habss,
  rw [sq_sqrt (le_of_lt hab), ← two_mul (f(a * b)), ← two_mul (a * b)] at H₂,
  rw [hfa₂, hfb₂] at H₂,

  have h2ab_ne_0 : 2 * (a * b) ≠ 0 := mul_ne_zero two_ne_zero (ne_of_gt hab),

  specialize h₃ (a * b) hab,
  cases h₃ with hab₁ hab₂,

  -- f(ab) = ab → b^4 = 1 → b = 1 → f(b) = b → false
  { field_simp [hab₁] at H₂,
    field_simp [ne_of_gt hb] at H₂,
    have hb₁ : b ^ 4 = 1 := by linear_combination -H₂,
    obtain hb₂ := abs_eq_one_of_pow_eq_one b 4 (show 4 ≠ 0, by norm_num) hb₁,
    rw abs_of_pos hb at hb₂, rw hb₂ at hfb₁, exact hfb₁ h₁ },

  -- f(ab) = 1/ab → a^4 = 1 → a = 1 → f(a) = 1/a → false
  { have hb_ne_0 : b ≠ 0 := ne_of_gt hb,
    field_simp [hab₂] at H₂,
    have H₃ : 2 * b ^ 4 * (a ^ 4 - 1) = 0 := by linear_combination (H₂),
    have h2b4_ne_0 : 2 * (b ^ 4) ≠ 0 := mul_ne_zero two_ne_zero (pow_ne_zero 4 hb_ne_0),
    have ha₁ : a ^ 4 = 1, { simpa [sub_eq_zero, h2b4_ne_0] using H₃ },
    obtain ha₂ := abs_eq_one_of_pow_eq_one a 4 (show 4 ≠ 0, by norm_num) ha₁,
    rw abs_of_pos ha at ha₂, rw ha₂ at hfa₁, norm_num at hfa₁ },
end

end imo
