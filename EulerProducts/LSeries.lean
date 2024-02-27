import Mathlib.NumberTheory.LSeries.Basic
import Mathlib.NumberTheory.LSeries.Convergence
import Mathlib.NumberTheory.VonMangoldt
import Mathlib.Analysis.Calculus.SmoothSeries
import Mathlib.Analysis.Convex.Complex
import Mathlib.Data.Complex.ExponentialBounds
import Mathlib.Topology.Instances.EReal
import Mathlib.Analysis.Normed.Field.InfiniteSum
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv

/-!
# More results on L-series
-/

namespace ArithmeticFunction

/-!
### Coercion to complex-valued arithmetic functions
-/

open Complex Nat

section toComplex

variable {R : Type*} [CommSemiring R] [Algebra R ℂ]

/-- Coerce an arithmetic function with values in `R` to one with values in `ℂ`.
We cannot inline this in `instToComplexAritmeticFunction` because it gets unfolded too much. -/
@[coe] def toComplexArithmeticFunction (f : ArithmeticFunction R) : ArithmeticFunction ℂ where
  toFun n := algebraMap R ℂ (f n)
  map_zero' := by simp only [map_zero, _root_.map_zero]

instance instToComplexAritmeticFunction : CoeHead (ArithmeticFunction R) (ArithmeticFunction ℂ) :=
  ⟨toComplexArithmeticFunction (R := R)⟩

@[simp]
lemma toComplexArithmeticFunction_apply {f : ArithmeticFunction R} {n : ℕ} :
    (f : ArithmeticFunction ℂ) n = algebraMap R ℂ (f n) := rfl

@[simp, norm_cast]
lemma toComplexArithmeticFunction_add {f g : ArithmeticFunction R} :
    (↑(f + g) : ArithmeticFunction ℂ) = ↑f + g := by
  ext
  simp only [toComplexArithmeticFunction_apply, add_apply, map_add]

@[simp, norm_cast]
lemma toComplexArithmeticFunction_mul {f g : ArithmeticFunction R} :
    (↑(f * g) : ArithmeticFunction ℂ) = ↑f * g := by
  ext
  simp only [toComplexArithmeticFunction_apply, mul_apply, map_sum, map_mul]

@[simp, norm_cast]
lemma toComplexArithmeticFunction_pmul {f g : ArithmeticFunction R} :
    (↑(pmul f g) : ArithmeticFunction ℂ) = pmul (f : ArithmeticFunction ℂ) (↑g) := by
  ext
  simp only [toComplexArithmeticFunction_apply, pmul_apply, map_mul]

@[simp, norm_cast]
lemma toComplexArithmeticFunction_ppow {f : ArithmeticFunction R} {n : ℕ} :
    (↑(ppow f n) : ArithmeticFunction ℂ) = ppow (f : ArithmeticFunction ℂ) n := by
  ext m
  rcases n.eq_zero_or_pos with rfl | hn
  · simp only [ppow_zero, toComplexArithmeticFunction_apply, natCoe_apply, zeta_apply, cast_ite,
      cast_zero, cast_one, RingHom.map_ite_zero_one, CharP.cast_eq_zero]
  · simp only [toComplexArithmeticFunction_apply, ppow_apply hn, map_pow]

end toComplex

section nat_int_real

lemma toComplexArithmeticFunction_real_injective :
    Function.Injective (toComplexArithmeticFunction (R := ℝ)) := by
  intro f g hfg
  ext n
  simpa only [toComplexArithmeticFunction_apply, coe_algebraMap, ofReal_inj]
    using congr_arg (· n) hfg

@[simp, norm_cast]
lemma toComplexArithmeticFunction_real_inj {f g : ArithmeticFunction ℝ} :
    (f : ArithmeticFunction ℂ) = g ↔ f = g :=
  toComplexArithmeticFunction_real_injective.eq_iff

lemma toComplexArithmeticFunction_int_injective :
    Function.Injective (toComplexArithmeticFunction (R := ℤ)) := by
  intro f g hfg
  ext n
  simpa only [toComplexArithmeticFunction_apply, algebraMap_int_eq, eq_intCast, Int.cast_inj]
    using congr_arg (· n) hfg

@[simp, norm_cast]
lemma toComplexArithmeticFunction_int_inj {f g : ArithmeticFunction ℤ} :
    (f : ArithmeticFunction ℂ) = g ↔ f = g :=
  toComplexArithmeticFunction_int_injective.eq_iff

lemma toComplexArithmeticFunction_nat_injective :
    Function.Injective (toComplexArithmeticFunction (R := ℕ)) := by
  intro f g hfg
  ext n
  simpa only [toComplexArithmeticFunction_apply, eq_natCast, Nat.cast_inj]
    using congr_arg (· n) hfg

@[simp, norm_cast]
lemma toComplexArithmeticFunction_nat_inj {f g : ArithmeticFunction ℕ} :
    (f : ArithmeticFunction ℂ) = g ↔ f = g :=
  toComplexArithmeticFunction_nat_injective.eq_iff

@[norm_cast]
lemma toComplexArithmeticFunction_real_int {f : ArithmeticFunction ℤ} :
    ((f : ArithmeticFunction ℝ) : ArithmeticFunction ℂ) = f := rfl

@[norm_cast]
lemma toComplexArithmeticFunction_real_nat {f : ArithmeticFunction ℕ} :
    ((f : ArithmeticFunction ℝ) : ArithmeticFunction ℂ) = f := rfl

@[norm_cast]
lemma toComplexArithmeticFunction_int_nat {f : ArithmeticFunction ℕ} :
    ((f : ArithmeticFunction ℤ) : ArithmeticFunction ℂ) = f := rfl

end nat_int_real

/-!
### Convergence of L-series
-/

/-- An open right half plane is open. -/
lemma _root_.Complex.isOpen_rightHalfPlane (x : EReal) : IsOpen {z : ℂ | x < z.re} :=
  isOpen_lt continuous_const <| EReal.continuous_coe_iff.mpr continuous_re

-- ATTN: the following needs the coercion of `log` to an arithmetic function over `ℂ`

lemma norm_log_mul_LSeriesTerm_le_of_re_lt_re (f : ArithmeticFunction ℂ) {w : ℂ} {z : ℂ}
    (h : w.re < z.re) (n : ℕ) :
    ‖log n * f n / n ^ z‖ ≤ ‖f n / n ^ w‖ / (z.re - w.re) := by
  have hwz : 0 < z.re - w.re := sub_pos.mpr h
  rw [mul_div_assoc, norm_mul, log_apply, ofReal_log n.cast_nonneg]
  refine mul_le_mul_of_nonneg_right (norm_log_natCast_le_rpow_div n hwz) (norm_nonneg _)|>.trans ?_
  rw [mul_comm_div, mul_div, div_le_div_right hwz]
  rcases n.eq_zero_or_pos with rfl | hn
  · simp
  simp_rw [norm_div, norm_natCast_cpow_of_pos hn]
  rw [mul_div_left_comm, ← Real.rpow_sub <| Nat.cast_pos.mpr hn, sub_sub_cancel_left,
    Real.rpow_neg n.cast_nonneg, div_eq_mul_inv]

/-- If the L-series of `f` is summable at `w` and `re w < re z`, then the L-series of the
point-wise product of `log` with `f` is summable at `z`. -/
lemma LSeriesSummable.log_pmul_of_re_lt_re {f : ArithmeticFunction ℂ} {w : ℂ} {z : ℂ}
    (h : w.re < z.re) (hf : LSeriesSummable f w) : LSeriesSummable (pmul log f) z := by
  rw [LSeriesSummable, ← summable_norm_iff] at hf ⊢
  exact (hf.div_const _).of_nonneg_of_le (fun _ ↦ norm_nonneg _)
    (norm_log_mul_LSeriesTerm_le_of_re_lt_re f h)

/-- If the L-series of the point-wise product of `log` with `f` is summable at `z`, then
so is the L-series of `f`. -/
lemma LSeriesSummable.of_LSeriesSummable_pmul_log  {f : ArithmeticFunction ℂ} {z : ℂ}
    (h : LSeriesSummable (pmul log f) z) : LSeriesSummable f z := by
  refine h.norm.of_norm_bounded_eventually_nat (fun n ↦ ‖(log n * f n / n ^ z : ℂ)‖) ?_
  simp only [norm_div, log_apply, natCast_log, norm_mul, Filter.eventually_atTop]
  refine ⟨3, fun n hn ↦ ?_⟩
  conv => enter [1, 1]; rw [← one_mul (‖f n‖)]
  gcongr
  rw [← natCast_log, norm_eq_abs, abs_ofReal,
    _root_.abs_of_nonneg <| Real.log_nonneg <| by norm_cast; linarith]
  calc 1
    _ = Real.log (Real.exp 1) := by rw [Real.log_exp]
    _ ≤ Real.log 3 := Real.log_le_log (by positivity) <|
                       (Real.exp_one_lt_d9.trans <| by norm_num).le
    _ ≤ Real.log n := Real.log_le_log zero_lt_three <| by exact_mod_cast hn

/-- The abscissa of absolute convergence of the point-wise product of `log` and `f`
is the same as that of `f`. -/
lemma abscissaOfAbsConv_pmul_log {f : ArithmeticFunction ℂ} :
    abscissaOfAbsConv (pmul log f) = abscissaOfAbsConv f := by
  refine le_antisymm ?_ ?_
  · refine abscissaOfAbsConv_le_of_forall_lt_LSeriesSummable' fun y hy ↦ ?_
    obtain ⟨x, hx₁, hx₂⟩ := EReal.exists_between_coe_real hy
    have hx₁' : abscissaOfAbsConv f < ↑((x : ℂ).re) := by simp only [ofReal_re, hx₁]
    have hx₂' : (x : ℂ).re < (y : ℂ).re := by simp only [ofReal_re, EReal.coe_lt_coe_iff.mp hx₂]
    exact (LSeriesSummable_of_abscissaOfAbsConv_lt_re hx₁').log_pmul_of_re_lt_re hx₂'
  · refine abscissaOfAbsConv_le_of_forall_lt_LSeriesSummable' fun y hy ↦ ?_
    have hy' : abscissaOfAbsConv (pmul (↑log) f) < ↑((y : ℂ).re) := by simp only [ofReal_re, hy]
    exact (LSeriesSummable_of_abscissaOfAbsConv_lt_re hy').of_LSeriesSummable_pmul_log

/-- The abscissa of absolute convergence of the point-wise product of a power of `log` and `f`
is the same as that of `f`. -/
lemma absicssaOfAbsConv_pmul_ppow_log {f : ArithmeticFunction ℂ} {n : ℕ} :
    abscissaOfAbsConv (pmul (ppow log n) f) = abscissaOfAbsConv f := by
  induction' n with n ih
  · simp only [zero_eq, ppow_zero, zeta_pmul]
  · rwa [ppow_succ, pmul_assoc, abscissaOfAbsConv_pmul_log]

/-!
### Differentiability and derivatives of L-series
-/

/-- The derivative of the terms of an L-series. -/
lemma LSeriesTerm_hasDerivAt (f : ArithmeticFunction ℂ) (n : ℕ) (s : ℂ) :
    HasDerivAt (fun z ↦ f n / n ^ z) (-(↑(Real.log n) * f n / n ^ s)) s := by
  rcases n.eq_zero_or_pos with rfl | hn
  · simp [hasDerivAt_const]
  rw [← neg_div, ← neg_mul, mul_comm, mul_div_assoc]
  simp_rw [div_eq_mul_inv, ← cpow_neg]
  refine HasDerivAt.const_mul (f n) ?_
  rw [mul_comm, ← mul_neg_one (Real.log n : ℂ), ← mul_assoc, ofReal_log n.cast_nonneg]
  exact (hasDerivAt_neg' s).const_cpow (Or.inl <| Nat.cast_ne_zero.mpr hn.ne')

/-- The derivative of the terms of an L-series. -/
lemma LSeriesTerm_deriv (f : ArithmeticFunction ℂ) (n : ℕ) (s : ℂ) :
    deriv (fun z ↦ f n / n ^ z) s = -(↑(Real.log n) * f n / n ^ s) :=
  (LSeriesTerm_hasDerivAt f n s).deriv

/-- The higher derivatives of the terms of an L-series. -/
lemma LSeriesTerm_iteratedDeriv (f : ArithmeticFunction ℂ) (m n : ℕ) (s : ℂ) :
    iteratedDeriv m (fun z ↦ f n / n ^ z) s = (-(↑(Real.log n))) ^ m * f n / n ^ s := by
  induction' m with m ih generalizing s
  · simp only [zero_eq, iteratedDeriv_zero, natCast_log, _root_.pow_zero, one_mul]
  · have ih' : iteratedDeriv m (fun z : ℂ ↦ f n / n ^ z) =
        fun s ↦ (-(Real.log n)) ^ m * f n / n ^ s :=
      funext ih
    simp only [iteratedDeriv_succ, ih', natCast_log, mul_div_assoc, deriv_const_mul_field',
      LSeriesTerm_deriv f n s, mul_neg, _root_.pow_succ, neg_mul]
    ring

/-- If `re z` is greater than the abscissa of absolute convergence of `f`, then the L-series
of `f` is differentiable with derivative the negative of the L-series of the point-wise
product of `log` with `f`. -/
lemma LSeries.hasDerivAt {f : ArithmeticFunction ℂ} {z : ℂ} (h : abscissaOfAbsConv f < z.re) :
    HasDerivAt (LSeries f) (- LSeries (pmul log f) z) z := by
  -- The L-series of `f` is summable at some real `x < re z`.
  obtain ⟨x, h', hf⟩ := LSeriesSummable_lt_re_of_abscissaOfAbsConv_lt_re h
  change HasDerivAt (fun s ↦ LSeries f s) ..
  simp only [LSeries, pmul_apply, toComplexArithmeticFunction_apply, log_apply, ← tsum_neg]
  -- We work in the right half-plane `re s > (x + re z)/2`.
  let S : Set ℂ := {s | (x + z.re) / 2 < s.re}
  have hop : IsOpen S := isOpen_lt continuous_const continuous_re
  have hpr : IsPreconnected S := (convex_halfspace_re_gt _).isPreconnected
  have hmem : z ∈ S := by
    simp only [Set.mem_setOf_eq]
    linarith only [h']
  -- To get a uniform summable bound for the derivative series, we use that we
  -- have summability of the L-series of `pmul log f` at `(x + z)/2`.
  have hx : (x : ℂ).re < ((x + z) / 2).re := by
    simp only [add_re, ofReal_re, div_ofNat_re, sub_re]
    linarith only [h']
  have hf' := hf.log_pmul_of_re_lt_re hx
  rw [LSeriesSummable, ← summable_norm_iff] at hf'
  -- Show that the terms have the correct derivative.
  have hderiv (n : ℕ) :
      ∀ s ∈ S, HasDerivAt (fun z ↦ f n / n ^ z) (-(↑(Real.log n) * f n / n ^ s)) s := by
    exact fun s _ ↦ LSeriesTerm_hasDerivAt f n s
  refine hasDerivAt_tsum_of_isPreconnected (F := ℂ) hf' hop hpr hderiv
    (fun n s hs ↦ ?_) hmem (hf.of_re_le_re <| ofReal_re x ▸ h'.le) hmem
  -- Show that the derivative series is uniformly bounded term-wise.
  rcases n.eq_zero_or_pos with rfl | hn
  · simp
  simp only [norm_neg, norm_div, norm_mul, pmul_apply, toComplexArithmeticFunction_apply, log_apply]
  refine div_le_div_of_le_left (mul_nonneg (norm_nonneg _) (norm_nonneg _))
    (norm_natCast_cpow_pos_of_pos hn _) <|
    norm_natCast_cpow_le_norm_natCast_cpow_of_pos hn <| le_of_lt ?_
  simpa only [add_re, ofReal_re, div_ofNat_re, sub_re] using hs

/-- If `re z` is greater than the abscissa of absolute convergence of `f`, then
the derivative of this L-series is the negative of the L-series of `pmul log f`. -/
lemma LSeries_deriv {f : ArithmeticFunction ℂ} {z : ℂ} (h : abscissaOfAbsConv f < z.re) :
    deriv (LSeries f) z = - LSeries (pmul log f) z :=
  (LSeries.hasDerivAt h).deriv

/-- The derivative of the L-series of `f` agrees with the negative of the L-series of
`pmul log f` on the right half-plane of absolute convergence. -/
lemma LSeries_deriv_eqOn {f : ArithmeticFunction ℂ} :
    {z | abscissaOfAbsConv f < z.re}.EqOn (deriv (LSeries f)) (- LSeries (pmul log f)) :=
  deriv_eqOn (isOpen_rightHalfPlane _) fun _ hz ↦ HasDerivAt.hasDerivWithinAt <|
    LSeries.hasDerivAt hz

/-- If `re z` is greater than the abscissa of absolute convergence of `f`, then
the `n`th derivative of this L-series is `(-1)^n` times the L-series of `pmul (ppow log n) f`. -/
lemma LSeries_iteratedDeriv {f : ArithmeticFunction ℂ} (n : ℕ) {z : ℂ}
    (h : abscissaOfAbsConv f < z.re) :
    iteratedDeriv n (LSeries f) z = (-1) ^ n * LSeries (pmul (ppow log n) f) z := by
  induction' n with n ih generalizing z
  · simp only [zero_eq, iteratedDeriv_zero, _root_.pow_zero, ppow_zero, zeta_pmul, one_mul]
  · have ih' : {z | abscissaOfAbsConv f < z.re}.EqOn (iteratedDeriv n (LSeries f))
        ((-1) ^ n * LSeries (pmul (ppow (↑log) n) f)) := by
      exact fun _ hs ↦ ih hs
    rw [iteratedDeriv_succ]
    have := derivWithin_congr ih' (ih h)
    simp_rw [derivWithin_of_isOpen (isOpen_rightHalfPlane _) h] at this
    rw [this]
    change deriv (fun z ↦ (-1) ^ n * LSeries (pmul (ppow (↑log) n) f) z) z = _
    rw [deriv_const_mul_field', _root_.pow_succ', mul_assoc, neg_one_mul]
    simp only [LSeries_deriv <| absicssaOfAbsConv_pmul_ppow_log.symm ▸ h, ppow_succ, pmul_assoc]

/-- The L-series of `f` is complex differentiable in its open half-plane of absolute
convergence. -/
lemma LSeries.differentiableOn {f : ArithmeticFunction ℂ} :
    DifferentiableOn ℂ (LSeries f) {z | abscissaOfAbsConv f < z.re} :=
  fun _ hz ↦ (LSeries.hasDerivAt hz).differentiableAt.differentiableWithinAt

/-!
### Multiplication of L-series
-/

open Set in
/-- The L-series of the convolution product `f * g` of two arithmetic functions `f` and `g`
equals the product of their L-series, assuming both L-series converge. -/
lemma LSeriesHasSum.mul {f g : ArithmeticFunction ℂ} {s a b : ℂ}
    (hf : LSeriesHasSum f s a) (hg : LSeriesHasSum g s b) :
    LSeriesHasSum (f * g) s (a * b) := by
  simp only [LSeriesHasSum, mul_apply, sum_eq_tsum_indicator, ← tsum_subtype]
  let m : ℕ × ℕ → ℕ := fun (n₁, n₂) ↦ n₁ * n₂
  have hsum := summable_mul_of_summable_norm hf.summable.norm hg.summable.norm
  convert (HasSum.mul hf hg hsum).tsum_fiberwise m with n
  rcases n.eq_zero_or_pos with rfl | hn
  · trans 0 -- show that both sides vanish when `n = 0`
    · -- by definition, the left hand sum is over the empty set
      rw [tsum_congr_set_coe (fun x ↦ f x.1 * g x.2) <|
            congrArg Finset.toSet divisorsAntidiagonal_zero]
      simp only [Finset.coe_sort_coe, tsum_empty, zero_div]
    · -- the right hand sum is over the union below, but in each term, one factor is always zero
      have hS : m ⁻¹' {0} = {0} ×ˢ univ ∪ (univ \ {0}) ×ˢ {0} := by
        ext
        simp only [m, mem_preimage, mem_singleton_iff, _root_.mul_eq_zero, mem_union, mem_prod,
          mem_univ, mem_diff]
        tauto
      let h : ℕ × ℕ → ℂ := fun x ↦ f x.1 / x.1 ^ s * (g x.2 / x.2 ^ s)
      rw [tsum_congr_set_coe h hS,
        tsum_union_disjoint (Disjoint.set_prod_left disjoint_sdiff_right ..)
          (hsum.subtype _) (hsum.subtype _),
        tsum_setProd_singleton_left 0 _ h, tsum_setProd_singleton_right _ 0 h]
      simp only [map_zero, zero_div, zero_mul, tsum_zero, mul_zero, add_zero]
  -- now `n > 0`
  have H : n.divisorsAntidiagonal = m ⁻¹' {n} := by
    ext x
    replace hn := hn.ne' -- for `tauto` below
    simp only [Finset.mem_coe, mem_divisorsAntidiagonal, m, mem_preimage, mem_singleton_iff]
    tauto
  rw [tsum_congr_set_coe (fun x ↦ f x.1 * g x.2) H, ← tsum_div_const]
  refine tsum_congr (fun x ↦ ?_)
  -- `rw [...]` does not work directly on the goal ("motive not type correct")
  conv =>
    enter [1, 2]
    rw [← mem_singleton_iff.mp <| mem_preimage.mp x.prop]
    simp only [m, Nat.cast_mul, natCast_mul_natCast_cpow]
  field_simp

/-- The L-series of the convolution product `f * g` of two arithmetic functions `f` and `g`
equals the product of their L-series, assuming both L-series converge. -/
lemma LSeries_mul {f g : ArithmeticFunction ℂ} {s : ℂ} (hf : LSeriesSummable f s)
    (hg : LSeriesSummable g s) :
    LSeries (f * g) s = LSeries f s * LSeries g s :=
  (LSeriesHasSum.mul hf.LSeriesHasSum hg.LSeriesHasSum).LSeries_eq

/-- The L-series of the convolution product `f * g` of two arithmetic functions `f` and `g`
equals the product of their L-series in their common half-plane of absolute convergence. -/
lemma LSeries_mul' {f g : ArithmeticFunction ℂ} {s : ℂ}
    (hf : abscissaOfAbsConv f < s.re) (hg : abscissaOfAbsConv g < s.re) :
    LSeries (f * g) s = LSeries f s * LSeries g s :=
  LSeries_mul (LSeriesSummable_of_abscissaOfAbsConv_lt_re hf)
    (LSeriesSummable_of_abscissaOfAbsConv_lt_re hg)

/-- The L-series of the convolution product `f * g` of two arithmetic functions `f` and `g`
is summable when both L-series are summable. -/
lemma LSeriesSummable_mul {f g : ArithmeticFunction ℂ} {s : ℂ} (hf : LSeriesSummable f s)
    (hg : LSeriesSummable g s) :
    LSeriesSummable (f * g) s :=
  (LSeriesHasSum.mul hf.LSeriesHasSum hg.LSeriesHasSum).LSeriesSummable

end ArithmeticFunction
