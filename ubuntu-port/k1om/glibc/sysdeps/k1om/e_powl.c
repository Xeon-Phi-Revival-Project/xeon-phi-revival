/*
   K1OM lacks the later x87 compare/pop instructions used by the x86-64
   assembly implementation.  This C fallback preserves the K1OM 80-bit
   long-double calling convention and delegates finite magnitude evaluation
   to the existing long-double log and exp implementations.

   This XPR source is LGPL-2.1-or-later, matching the surrounding eglibc
   math implementation.  Numerical characterization remains required before
   this runtime is eligible for a public hardware image.
*/
#include <math.h>
#include <math_private.h>

static int
integer_is_odd (long double value)
{
  long double magnitude = value < 0.0L ? -value : value;
  return fmodl (magnitude, 2.0L) == 1.0L;
}

long double
__ieee754_powl (long double x, long double y)
{
  long double result;

  if (y == 0.0L || x == 1.0L)
    return 1.0L;
  if (x != x || y != y)
    return x + y;

  if (!__finitel (y))
    {
      long double magnitude = x < 0.0L ? -x : x;
      if (magnitude == 1.0L)
        return 1.0L;
      if (y > 0.0L)
        return magnitude > 1.0L ? y : 0.0L;
      return magnitude > 1.0L ? 0.0L : -y;
    }

  if (x == 0.0L)
    {
      int negative = signbit (x) && integer_is_odd (y);
      if (y < 0.0L)
        return negative ? -HUGE_VALL : HUGE_VALL;
      return negative ? -0.0L : 0.0L;
    }

  if (x < 0.0L)
    {
      long double integer_y = truncl (y);
      if (integer_y != y)
        return (x - x) / (x - x);
      result = expl (y * logl (-x));
      return integer_is_odd (integer_y) ? -result : result;
    }

  return expl (y * logl (x));
}

strong_alias (__ieee754_powl, __powl_finite)
