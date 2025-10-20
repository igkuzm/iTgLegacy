#include <algorithm>
#include <cmath>
#include <iostream>
#include <map>
#include <vector>
#include <stdint.h>

using namespace std;

long long absx(long long n)
{
  return n < 0 ? -n : n;
}

unsigned long long abs(unsigned long long n)
{
  return n;
}

template <class T>
bool even(const T & n)
{
  return (n & 1) == 0;
}

template <class T>
void bisect(T & n)
{
  n >>= 1;
}

template <class T>
void redouble(T & n)
{
  n <<= 1;
}

template <class T>
bool perfect_square(const T & n)
{
  T sq = (T) ceil(sqrt((double)n));

  return sq * sq == n;
}

template <class T>
T sq_root(const T & n)
{
  return (T) floor(sqrt((double) n));
}

template <class T>
unsigned bits_in_number(T n)
{
  if (n == 0) {
    return 1;
  }

  unsigned result = 0;

  while (n) {
    bisect(n);
    ++result;
  }

  return result;
}

template <class T>
bool test_bit(const T & n, unsigned k)
{
  return (n & (T(1) << k)) != 0;
}

template <class T>
void mulmod(T & a, T b, const T & n)
{
  a *= b;
  a %= n;
}

template <>
void mulmod(int & a, int b, const int & n)
{
  a = int((((long long)a) * b) % n);
}

template <>
void mulmod(unsigned & a, unsigned b, const unsigned & n)
{
  a = unsigned((((unsigned long long)a) * b) % n);
}

template <>
void mulmod(unsigned long long & a, unsigned long long b, const unsigned long long & n)
{
  if (a >= n) {
    a %= n;
  }

  if (b >= n) {
    b %= n;
  }

  unsigned long long res = 0;

  while (b) {
    if (!even(b)) {
      res += a;

      while (res >= n) {
        res -= n;
      }

      --b;
    } else {
      redouble(a);

      while (a >= n) {
        a -= n;
      }

      bisect(b);
    }
  }

  a = res;
}

template <>
void mulmod(long long & a, long long b, const long long & n)
{
  bool neg = false;

  if (a < 0) {
    neg = !neg;
    a = -a;
  }

  if (b < 0) {
    neg = !neg;
    b = -b;
  }

  unsigned long long aa = a;

  mulmod<unsigned long long> (aa, (unsigned long long)b, (unsigned long long)n);
  a = (long long)aa * (neg ? -1 : 1);
}

template <class T, class T2>
T powmod(T a, T2 k, const T & n)
{
  T res = 1;

  while (k) {
    if (!even(k)) {
      mulmod(res, a, n);
      --k;
    } else {
      mulmod(a, a, n);
      bisect(k);
    }
  }

  return res;
}

template <class T>
void transform_num(T n, T & p, T & q)
{
  T p_res = 0;

  while (even(n)) {
    ++p_res;
    bisect(n);
  }
  p = p_res;
  q = n;
}

template <class T, class T2>
T gcd(const T & a, const T2 & b)
{
  return (a == 0) ? b : gcd(b % a, a);
}

template <class T>
T jacobi(T a, T b)
{
#pragma warning (push)
#pragma warning (disable: 4146)
  if (a == 0) {
    return 0;
  }

  if (a == 1) {
    return 1;
  }

  if (a < 0) {
    if ((b & 2) == 0) {
      return jacobi(-a, b);
    } else {
      return - jacobi(-a, b);
    }
  }

  T e, a1;
  transform_num(a, e, a1);
  T s;

  if (even(e) || (b & 7) == 1 || (b & 7) == 7) {
    s = 1;
  } else {
    s = -1;
  }

  if ((b & 3) == 3 && (a1 & 3) == 3) {
    s = -s;
  }

  if (a1 == 1) {
    return s;
  }

  return s * jacobi(b % a1, a1);
#pragma warning (pop)
}

template <class T, class T2>
const std::vector<T> & get_primes(const T & b, T2 & pi)
{
  static std::vector<T> primes;
  static T counted_b;

  if (counted_b >= b) {
    pi = T2(std::upper_bound(primes.begin(), primes.end(), b) - primes.begin());
  } else {
    if (counted_b == 0) {
			primes.push_back(2);
			//primes.insert(primes.end(), 2);
      counted_b = 2;
    }

    T first = counted_b == 2 ? 3 : primes.back() + 2;

    for (T cur = first; cur <= b; ++++cur) {
      bool cur_is_prime = true;

      for (typename std::vector<T>::const_iterator iter = primes.begin(), end = primes.end(); iter != end; ++iter) {
        const T & div = *iter;

        if (div * div > cur) {
          break;
        }

        if (cur % div == 0) {
            cur_is_prime = false;

            break;
        }
      }
      if (cur_is_prime) {
				primes.push_back(cur);
				//primes.insert(primes.end(), cur);
      }
    }

    counted_b = b;
    pi = (T2) primes.size();
  }

  return primes;
}

template <class T, class T2>
T2 prime_div_trivial(const T & n, T2 m)
{
  if (n == 2 || n == 3) {
    return 1;
  }

  if (n < 2) {
    return 0;
  }

  if (even(n)) {
    return 2;
  }

  T2 pi;
  const vector<T2> & primes = get_primes(m, pi);

  for (typename std::vector<T2>::const_iterator iter = primes.begin(), end = primes.end(); iter != end; ++iter) {
    const T2 & div = *iter;

    if (div * div > n) {
      break;
    } else if (n % div == 0) {
      return div;
    }
  }

  if (n < m * m) {
    return 1;
  }

  return 0;
}

template <class T, class T2>
bool miller_rabin(T n, T2 b)
{
  if (n == 2) {
    return true;
  }

  if (n < 2 || even(n)) {
    return false;
  }

  if (b < 2) {
    b = 2;
  }

  for (T g; (g = gcd(n, b)) != 1; ++b) {
    if (n > g) {
      return false;
    }
  }

  T n_1 = n;
  --n_1;
  T p, q;
  transform_num(n_1, p, q);
  T rem = powmod(T(b), q, n);

  if (rem == 1 || rem == n_1) {
    return true;
  }

  for (T i = 1; i < p; i++) {
    mulmod(rem, rem, n);
    if (rem == n_1) {
      return true;
    }
  }

  return false;
}

template <class T, class T2>
bool lucas_selfridge(const T & n, T2 unused)
{
  if (n == 2) {
    return true;
  }

  if (n < 2 || even(n)) {
    return false;
  }

  if (perfect_square(n)) {
    return false;
  }

  T2 dd;

  for (T2 d_abs = 5, d_sign = 1; ; d_sign = -d_sign, ++++d_abs) {
    dd = d_abs * d_sign;
    T g = gcd(n, d_abs);

    if (1 < g && g < n) {
      return false;
    }

    if (jacobi(T(dd), n) == -1) {
      break;
    }
  }

  T2
  p = 1,
  q = (p * p - dd) / 4;
  T n_1 = n;
  ++n_1;
  T s, d;
  transform_num(n_1, s, d);
  T
  u = 1,
  v = p,
  u2m = 1,
  v2m = p,
  qm = q,
  qm2 = q * 2,
  qkd = q;

  for (unsigned bit = 1, bits = bits_in_number(d); bit < bits; bit++) {
    mulmod(u2m, v2m, n);
    mulmod(v2m, v2m, n);

    while (v2m < qm2) {
      v2m += n;
    }

    v2m -= qm2;
    mulmod(qm, qm, n);
    qm2 = qm;
    redouble(qm2);

    if (test_bit(d, bit)) {
      T t1, t2;
      t1 = u2m;
      mulmod(t1, v, n);
      t2 = v2m;
      mulmod(t2, u, n);
      T t3, t4;
      t3 = v2m;
      mulmod(t3, v, n);
      t4 = u2m;
      mulmod(t4, u, n);
      mulmod(t4, (T)dd, n);
      u = t1 + t2;

      if (!even(u)) {
        u += n;
      }

      bisect(u);
      u %= n;
      v = t3 + t4;

      if (!even(v)) {
        v += n;
      }

      bisect(v);
      v %= n;
      mulmod(qkd, qm, n);
    }
  }

  if (u == 0 || v == 0) {
    return true;
  }

  T qkd2 = qkd;
  redouble(qkd2);

  for (T2 r = 1; r < s; ++r) {
    mulmod(v, v, n);
    v -= qkd2;

    if (v < 0) {
      v += n;
    }

    if (v < 0) {
      v += n;
    }

    if (v >= n) {
      v -= n;
    }

    if (v >= n) {
      v -= n;
    }

    if (v == 0) {
      return true;
    }

    if (r < s - 1) {
      mulmod(qkd, qkd, n);
      qkd2 = qkd;
      redouble(qkd2);
    }
  }

  return false;
}

template <class T>
bool baillie_pomerance_selfridge_wagstaff(T n)
{
  int div = prime_div_trivial(n, 29);

  if (div == 1) {
    return true;
  }

  if (div > 1) {
    return false;
  }

  if (!miller_rabin(n, 2)) {
    return false;
  }

  return lucas_selfridge(n, 0);
}

template <class T>
bool isprime(T n)
{
  return baillie_pomerance_selfridge_wagstaff(n);
}

template <class T>
T pollard_p_1(T n)
{
  const int b = 13;
  const int q[] = { 2, 3, 5, 7, 11, 13 };

  T a = 5 % n;

  for (int j = 0; j < 10; j++) {
    while (gcd(a, n) != 1) {
      mulmod(a, a, n);
      a += 3;
      a %= n;
    }
    for (size_t i = 0; i < sizeof q / sizeof q[0]; i++) {
      int qq = q[i];

      T e = (T) floor(log((double)b) / log((double)qq));
      T aa = powmod(a, powmod((T)qq, e, n), n);

      if (aa == 0) {
        continue;
      }

      T g = gcd(aa - 1, n);

      if (1 < g && g < n) {
        return g;
      }
    }
  }

  return 1;
}

template <class T>
T pollard_rho(T n, unsigned iterations_count = 100000)
{
  T
  b0 = rand() % n,
  b1 = b0,
  g;
  mulmod(b1, b1, n);

  if (++b1 == n) {
    b1 = 0;
  }

  g = gcd(abs(b1 - b0), n);

  for (unsigned count = 0; count < iterations_count && (g == 1 || g == n); count++) {
    mulmod(b0, b0, n);

    if (++b0 == n) {
      b0 = 0;
    }

    mulmod(b1, b1, n);
    ++b1;
    mulmod(b1, b1, n);

    if (++b1 == n) {
      b1 = 0;
    }

    g = gcd(abs(b1 - b0), n);
  }

  return g;
}

template <class T>
T pollard_bent(T n, unsigned iterations_count = 19)
{
  T
  b0 = rand() % n,
  b1 = (b0 * b0 + 2) % n,
  a = b1;

  for (unsigned iteration = 0, series_len = 1; iteration < iterations_count; iteration++, series_len *= 2) {
    T g = gcd(b1 - b0, n);

    for (unsigned len = 0; len < series_len && (g == 1 && g == n); len++) {
      b1 = (b1 * b1 + 2) % n;
      g = gcd(abs(b1 - b0), n);
    }

    b0 = a;
    a = b1;

    if (g != 1 && g != n) {
      return g;
    }
  }

  return 1;
}

template <class T>
T pollard_monte_carlo(T n, unsigned m = 100)
{
  T b = rand() % (m - 2) + 2;

  static std::vector<T> primes;
  static T m_max;

  if (primes.empty()) {
		primes.push_back(3);
		//primes.insert(primes.end(), 3);
  }

  if (m_max < m) {
    m_max = m;

    for (T prime = 5; prime <= m; ++++prime) {
      bool is_prime = true;
      for (typename std::vector<T>::const_iterator iter = primes.begin(), end = primes.end(); iter != end; ++iter) {
        T div = *iter;

        if (div * div > prime) {
          break;
        }

        if (prime % div == 0) {
            is_prime = false;

            break;
        }
      }

      if (is_prime) {
				primes.push_back(prime);
				//primes.insert(primes.end(), prime);
      }
    }
  }

  T g = 1;

  for (size_t i = 0; i < primes.size() && g == 1; i++) {
    T cur = primes[i];

    while (cur <= n) {
      cur *= primes[i];
    }

    cur /= primes[i];
    b = powmod(b, cur, n);
    g = gcd(abs(b - 1), n);

    if (g == n) {
      g = 1;
    }
  }

  return g;
}

template <class T, class T2>
T ferma(const T & n, T2 unused)
{
  T2
  x = sq_root(n),
  y = 0,
  r = x * x - y * y - n;

  for (;;) {
    if (r == 0) {
      return x != y ? x - y : x + y;
    } else if (r > 0) {
      r -= y + y + 1;
      ++y;
    } else {
      r += x + x + 1;
      ++x;
    }
  }
}

template <class T, class T2>
void factorize(const T & n, std::map<T, unsigned> & result, T2 unused)
{
  if (n == 1) {
    // ..
  } else if (isprime(n)) {
    ++result[n];
  } else if (n < 1000 * 1000) {
    T div = prime_div_trivial(n, 1000);
    ++result[div];
    factorize(n / div, result, unused);
  } else {
    T div;
    div = pollard_monte_carlo(n);

    if (div == 1) {
      div = pollard_rho(n);
    }

    if (div == 1) {
      div = pollard_p_1(n);
    }

    if (div == 1) {
      div = pollard_bent(n);
    }

    if (div == 1) {
      div = ferma(n, unused);
    }

    factorize(div, result, unused);
    factorize(n / div, result, unused);
  }
}
#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

EXTERNC
void factor(uint64_t pq, uint32_t * p, uint32_t * q)
{
  typedef map <long long, unsigned> Map;
  Map m;

  factorize((long long)pq, m, (long long) 0);

  uint32_t r[2];

  for (uint32_t i = 0; i < m.size(); ++i) {
    Map::iterator it = m.begin();
    std::advance(it, i);
    r[i] = (uint32_t)it->first;
  }

  *p = r[0];
  *q = r[1];
}
