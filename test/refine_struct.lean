import tactic.interactive

/-!
`refine_struct` caused a variety of interesting problems,
which were identified in
https://github.com/leanprover-community/mathlib/pull/2251
and
https://leanprover.zulipchat.com/#narrow/stream/113488-general/topic/Need.20help.20with.20class.20instance.20resolution

These tests are quite specific to testing the patch made in
https://github.com/leanprover-community/mathlib/pull/2319
and are not a complete test suite for `refine_struct`.
-/

instance pi_has_one {α : Type*} {β : α → Type*} [Π x, has_one (β x)] : has_one (Π x, β x) :=
by refine_struct { .. }; exact λ _, 1

open tactic

run_cmd (do
  (declaration.defn _ _ _ b _ _) ← get_decl ``pi_has_one,
  -- Make sure that `eq.mpr` really doesn't occur in the body:
  eq_mpr ← mk_const `eq.mpr,
  k ← kabstract b eq_mpr, -- `expr.occurs` doesn't work here, always giving `ff` even before the patch.
  when (b.list_constant.contains ``eq.mpr) $
    fail "result generated by `refine_struct` contained an unnecessary `eq.mpr`",
  -- Make sure that `id` really doesn't occur in the body:
  id ← mk_const `id,
  k ← kabstract b id,
  guard (k = b) <|>
    fail "result generated by `refine_struct` contained an unnecessary `id`")

-- Next we check that fields defined for embedded structures are unfolded
-- when seen by fields in the outer structure.
structure foo (α : Type):=
(a : α)

structure bar (α : Type) extends foo α :=
(b : a = a)

example : bar ℕ :=
begin
  refine_struct { a := 1, .. },
  -- We're making sure that the goal is
  -- ⊢ 1 = 1
  -- rather than
  -- ⊢ {a := 1}.a = {a := 1}.a
  guard_target 1 = 1,
  trivial
end

section
variables {α : Type} [_inst : monoid α]
include _inst

example : true :=
begin
  have : group α,
  { refine_struct { .._inst },
    guard_tags _field inv group, admit,
    guard_tags _field mul_left_inv group, admit, },
  trivial
end
end

def my_foo {α} (x : semigroup α) (y : group α) : true := trivial

example {α : Type} : true :=
begin
  have : true,
  { refine_struct (@my_foo α { .. } { .. } ),
      -- 9 goals
    guard_tags _field mul semigroup, admit,
      -- case semigroup, mul
      -- α : Type
      -- ⊢ α → α → α

    guard_tags _field mul_assoc semigroup, admit,
      -- case semigroup, mul_assoc
      -- α : Type
      -- ⊢ ∀ (a b c : α), a * b * c = a * (b * c)

    guard_tags _field mul group, admit,
      -- case group, mul
      -- α : Type
      -- ⊢ α → α → α

    guard_tags _field mul_assoc group, admit,
      -- case group, mul_assoc
      -- α : Type
      -- ⊢ ∀ (a b c : α), a * b * c = a * (b * c)

    guard_tags _field one group, admit,
      -- case group, one
      -- α : Type
      -- ⊢ α

    guard_tags _field one_mul group, admit,
      -- case group, one_mul
      -- α : Type
      -- ⊢ ∀ (a : α), 1 * a = a

    guard_tags _field mul_one group, admit,
      -- case group, mul_one
      -- α : Type
      -- ⊢ ∀ (a : α), a * 1 = a

    guard_tags _field inv group, admit,
      -- case group, inv
      -- α : Type
      -- ⊢ α → α

    guard_tags _field mul_left_inv group, admit,
      -- case group, mul_left_inv
      -- α : Type
      -- ⊢ ∀ (a : α), a⁻¹ * a = 1
  },
  trivial
end

def my_bar {α} (x : semigroup α) (y : group α) (i j : α) : α := i

example {α : Type} : true :=
begin
  have : monoid α,
  { refine_struct { mul := my_bar { .. } { .. } },
    guard_tags _field mul semigroup, admit,
    guard_tags _field mul_assoc semigroup, admit,
    guard_tags _field mul group, admit,
    guard_tags _field mul_assoc group, admit,
    guard_tags _field one group, admit,
    guard_tags _field one_mul group, admit,
    guard_tags _field mul_one group, admit,
    guard_tags _field inv group, admit,
    guard_tags _field mul_left_inv group, admit,
    guard_tags _field mul_assoc monoid, admit,
    guard_tags _field one monoid, admit,
    guard_tags _field one_mul monoid, admit,
    guard_tags _field mul_one monoid, admit, },
  trivial
end
