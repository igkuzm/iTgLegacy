/* Two-factor authentication
 *
 * Telegram uses the Secure Remote Password protocol version 6a 
 * to implement 2FA.
 *
 * Example implementation: tdlib.
 *
 * Checking the password with SRP 
 * To login to an account protected by a 2FA password or to 
 * perform some other actions (like changing channel owner), 
 * you will need to verify the user's knowledge of the current 
 * 2FA account password.
 * To do this, first the client needs to obtain SRP parameters 
 * and the KDF algorithm to use to check the validity of the 
 * password via account.getPassword method. For now, only 
 * the passwordKdfAlgoSHA256SHA256PBKDF2HMACSHA512iter100000SHA256ModPow
 * algorithm is supported, so we'll only explain that.
 *
 * Then, after the user provides a password, the client should 
 * generate an InputCheckPasswordSRP object using SRP and a 
 * specific KDF algorithm as shown below and pass it to 
 * appropriate method (e.g. auth.checkPassword in case of authorization).
 * 
 * This extension of the SRP protocol uses the password-based PBKDF2 
 * with 100000 iterations using sha512 (PBKDF2HMACSHA512iter100000).
 * PBKDF2 is used to additionally rehash the x parameter, 
 * obtained using a method similar to the one described in 
 * RFC 2945 (H(s | H ( I | password | I) | s) 
 * instead of H(s | H ( I | ":" | password)) (see below).
 *
 * Here, | denotes concatenation and + denotes the arithmetical
 * operator +. In all cases where concatenation of numbers 
 * passed to hashing functions is done, the numbers must be 
 * used in big-endian form, padded to 2048 bits; all math 
 * is modulo p. Instead of I, salt1 will be used (see SRP protocol).
 * Instead of s, salt2 will be used (see SRP protocol).
 *
 * The main hashing function H is sha256:
 * H(data) := sha256(data)
 *
 * The salting hashing function SH is defined as follows:
 * SH(data, salt) := H(salt | data | salt)
 *
 * The primary password hashing function is defined as follows:
 * PH1(password, salt1, salt2) := SH(SH(password, salt1), salt2)
 *
 * The secondary password hashing function is defined as follows:
 * PH2(password, salt1, salt2) := SH(pbkdf2(sha512, PH1(password, salt1, salt2), salt1, 100000), salt2) */

#include "tg.h"
#include <assert.h>
#include <openssl/bn.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "../crypto/hsh.h"
#include "../crypto/pbkdf2.h"

// H(data) := sha256(data)
#define H(data) tg_hsh_sha256(data)
 
// SH(data, salt) := H(salt | data | salt)
#define SH(data, salt) \
	({buf_t _buf = buf_new(); \
	  _buf = buf_cat(_buf, salt); \
	  _buf = buf_cat(_buf, data); \
	  _buf = buf_cat(_buf, salt); \
		buf_t _ret = H(_buf); \
		buf_free(_buf); \
		_ret;})
 
// PH1(password, salt1, salt2) := SH(SH(password, salt1), salt2)
#define PH1(password, salt1, salt2) \
	({buf_t _buf = SH(password, salt1); \
		buf_t _ret = SH(_buf, salt2); \
		buf_free(_buf); \
		_ret;})
 
// PH2(password, salt1, salt2) := 
// SH(pbkdf2(sha512, PH1(password, salt1, salt2), salt1, 100000), salt2)
#define PH2(password, salt1, salt2) \
	({buf_t _psw = buf_new_data((unsigned char*)password,strlen(password));\
		buf_t _ph1 = PH1(_psw, salt1, salt2); \
	  buf_t _buf = tg_pbkdf2_sha512(_ph1, salt1, 100000); \
		buf_t _ret = SH(_buf, salt2); \
		buf_free(_psw); \
		buf_free(_ph1); \
		buf_free(_buf); \
		_ret;})

static buf_t buf_new_bufs(buf_t a, buf_t b){
	buf_t c = buf_add_buf(a);
	c = buf_cat(c, b);
	return c;
}

static buf_t BN_bn2bin_size(BIGNUM *a, int exact_size){
	assert(exact_size <= BUFSIZ);
	// int num_size = get_num_bytes();
  int num_size = BN_num_bytes(a);
  if (exact_size == -1) {
    exact_size = num_size;
  } else {
		//CHECK(exact_size >= num_size);
		assert(exact_size >= num_size);
  }
  // string res(exact_size, '\0');
	buf_t res = buf_new();
  // BN_bn2bin(impl_->big_num, MutableSlice(res).ubegin() + (exact_size - num_size));
  BN_bn2bin(a, res.data + (exact_size - num_size));
	res.size = exact_size;
  return res;
}

#define buf_concat_sha256(__b1, __b2) \
	({buf_t __b = buf_new_bufs(__b1, __b2); \
	  buf_t __sh = tg_hsh_sha256(__b); \
		buf_free(__b); \
	  __sh; })
 
static buf_t tg_calc_password_hash(
		tg_t *tg, const char *password, buf_t salt1, buf_t salt2)
{
	ON_LOG(tg, "Begin password hash calculation");
	buf_t pas = buf_add((unsigned char*)password,
		 	strlen(password));
	//BufferSlice buf(32);
  //hash_sha256(password, client_salt, buf.as_mutable_slice());
  buf_t buf1 = SH(pas, salt1);
	buf_free(pas);

  // hash_sha256(buf.as_slice(), server_salt, buf.as_mutable_slice());
	buf_t buf2 = SH(buf1, salt2);
	buf_free(buf1);

	//BufferSlice hash(64);
  //pbkdf2_sha512(buf.as_slice(), client_salt, 100000, hash.as_mutable_slice());
	buf_t buf3 = tg_pbkdf2_sha512(buf2,
		 	salt1, 100000);
	buf_free(buf2);

  //hash_sha256(hash.as_slice(), server_salt, buf.as_mutable_slice());
	buf_t buf4 = SH(buf3, salt2);
	buf_free(buf3);

  ON_LOG(tg, "End password hash calculation");
  return buf4;
}

/*
static buf_t tg_calc_password_srp_hash(
		tg_t *tg, const char *password, buf_t salt1, buf_t salt2, 
		uint32_t g, buf_t p)
{
	ON_LOG(tg, "%s", __func__);
	
	buf_t hash = tg_calc_password_hash(tg, password, salt1, salt2);
	
	BIGNUM *p_bn = BN_new();
	BN_bin2bn(p.data, p.size, p_bn); 

	BIGNUM *g_bn = BN_new();
	BN_set_word(g_bn, g);
	
	BIGNUM *x_bn = BN_new();
	BN_bin2bn(hash.data, hash.size, x_bn); 

	BN_CTX *ctx = BN_CTX_new();	

	BIGNUM *v_bn = BN_new();
  assert(BN_mod_exp(v_bn, g_bn, x_bn, p_bn, ctx)); 

	buf_t result = buf_new();
	BN_bn2bin(v_bn, result.data);
	result.size = 256;
	
	return result;
}
*/

static InputCheckPasswordSRP tg_get_inputCheckPasswordSRP(
		tg_t *tg, const char *password, buf_t salt1, buf_t salt2, 
		uint32_t g, buf_t p, buf_t B, uint64_t id)
{
	ON_LOG_BUF(tg, B, "%s: B: ", __func__);
	ON_LOG(tg, "%s: g: %d", __func__, g);
	InputCheckPasswordSRP srp = buf_new();

	// auto p_bn = BigNum::from_binary(p);
	BIGNUM *p_bn = BN_bin2bn(p.data, p.size, NULL); 

	// auto B_bn = BigNum::from_binary(B);
	BIGNUM *B_bn = BN_bin2bn(B.data, B.size, NULL); 
	
	// auto zero = BigNum::from_decimal("0").move_as_ok();
	BIGNUM *zero = BN_new();
	BN_zero(zero);

	if (BN_cmp(zero, B_bn) != -1 ||
	    BN_cmp(B_bn, p_bn) != -1 ||
			B.size != 256)
	{
		ON_ERR(tg, "Receive invalid value of B: (%d): %s: %s", 
				B.size,
				BN_bn2dec(B_bn), BN_bn2dec(p_bn));
		return srp;
	}

	ON_LOG(tg, "Begin input password SRP hash calculation");

	// BigNum g_bn;
	// g_bn.set_value(g);
	// auto g_padded = g_bn.to_binary(256);
	BIGNUM *g_bn = BN_new();
	BN_set_word(g_bn, g);
	buf_t g_padded = BN_bn2bin_size(g_bn, 256);
	ON_LOG_BUF(tg, g_padded, "%s: g_padded: ", __func__);

	// auto x = calc_password_hash(password, client_salt, server_salt);
	// auto x_bn = BigNum::from_binary(x.as_slice());
	buf_t x = tg_calc_password_hash(tg, password, salt1, salt2);
	//buf_t x = PH2(password, salt1, salt2);
	BIGNUM *x_bn = BN_bin2bn(x.data, x.size, NULL);

	// BufferSlice a(2048 / 8);
  // Random::secure_bytes(a.as_mutable_slice());
  // auto a_bn = BigNum::from_binary(a.as_slice());
	buf_t a = buf_rand(2048/8);
	BIGNUM *a_bn = BN_bin2bn(a.data, a.size, NULL);
	//ON_LOG_BUF(tg, a, "%s: a: ", __func__);
	
	// BigNumContext ctx;
	BN_CTX *ctx = BN_CTX_new();	
  
	// BigNum A_bn;
  // BigNum::mod_exp(A_bn, g_bn, a_bn, p_bn, ctx);
  // string A = A_bn.to_binary(256);
	BIGNUM *A_bn = BN_new();
  assert(BN_mod_exp(A_bn, g_bn, a_bn, p_bn, ctx)); 
	buf_t A = BN_bn2bin_size(A_bn, 256);
	ON_LOG_BUF(tg, A, "%s: A: ", __func__);
	
	// string u = sha256(PSLICE() << A << B);
	buf_t u  = buf_concat_sha256(A, B);
	//ON_LOG_BUF(tg, u, "%s: u: ", __func__);
  
	// auto u_bn = BigNum::from_binary(u);
	BIGNUM *u_bn = BN_bin2bn(u.data, u.size, NULL);
  
	// string k = sha256(PSLICE() << p << g_padded);
  // auto k_bn = BigNum::from_binary(k);
	buf_t k  = buf_concat_sha256(p, g_padded);
	BIGNUM *k_bn = BN_bin2bn(k.data, k.size, NULL);
	//ON_LOG_BUF(tg, k, "%s: k: ", __func__);
	
  // BigNum v_bn;
  // BigNum::mod_exp(v_bn, g_bn, x_bn, p_bn, ctx);
	BIGNUM *v_bn = BN_new();
  assert(BN_mod_exp(v_bn, g_bn, x_bn, p_bn, ctx)); 
	
	// BigNum kv_bn;
  // BigNum::mod_mul(kv_bn, k_bn, v_bn, p_bn, ctx);
	BIGNUM *kv_bn = BN_new();
	assert(BN_mod_mul(kv_bn, k_bn, v_bn, p_bn, ctx));
	
	// BigNum t_bn;
  // BigNum::sub(t_bn, B_bn, kv_bn);
  // if (BigNum::compare(t_bn, zero) == -1) {
  //  BigNum::add(t_bn, t_bn, p_bn);
  // }
	BIGNUM *t_bn = BN_new();
  assert(BN_sub(t_bn, B_bn, kv_bn)); 
	if (BN_cmp(t_bn, zero) == -1){
		assert(BN_add(t_bn, t_bn, p_bn)); 
	}
	
  // BigNum exp_bn;
  // BigNum::mul(exp_bn, u_bn, x_bn, ctx);
  // BigNum::add(exp_bn, exp_bn, a_bn);
	BIGNUM *exp_bn = BN_new();
  assert(BN_mul(exp_bn, u_bn, x_bn, ctx)); 
	assert(BN_add(exp_bn, exp_bn, a_bn)); 
	
  // BigNum S_bn;
  // BigNum::mod_exp(S_bn, t_bn, exp_bn, p_bn, ctx);
  // string S = S_bn.to_binary(256);
	BIGNUM *S_bn = BN_new();
  assert(BN_mod_exp(S_bn, t_bn, exp_bn, p_bn, ctx)); 
	buf_t S = BN_bn2bin_size(S_bn, 256);
	ON_LOG_BUF(tg, S, "%s: S: ", __func__);
  
	// auto K = sha256(S);
	buf_t K = tg_hsh_sha256(S);
	ON_LOG_BUF(tg, K, "%s: K: ", __func__);

	// auto h1 = sha256(p);
  // auto h2 = sha256(g_padded);
	buf_t h1 = tg_hsh_sha256(p);
	buf_t h2 = tg_hsh_sha256(g_padded);
	ON_LOG_BUF(tg, h1, "%s: H1: ", __func__);
	ON_LOG_BUF(tg, h2, "%s: H2: ", __func__);
	
	// for (size_t i = 0; i < h1.size(); i++) {
  // h1[i] = static_cast<char>(static_cast<unsigned char>(h1[i]) ^ static_cast<unsigned char>(h2[i]));
  // }
	buf_t xor = buf_xor(h1, h2);

	buf_t salt1_hash = tg_hsh_sha256(salt1);
	buf_t salt2_hash = tg_hsh_sha256(salt2);

  // auto M = sha256(PSLICE() << h1 << sha256(client_salt) << sha256(server_salt) << A << B << K);
	buf_t M1_ = buf_new(); 
	M1_ = buf_cat(M1_, xor);
	M1_ = buf_cat(M1_, salt1_hash);
	M1_ = buf_cat(M1_, salt2_hash);
	M1_ = buf_cat(M1_, A);
	M1_ = buf_cat(M1_, B);
	M1_ = buf_cat(M1_, K);
	buf_t M1  = tg_hsh_sha256(M1_);
	buf_free(M1_);

	buf_free(h1);
	buf_free(h2);
	buf_free(xor);
	buf_free(salt1_hash);
	buf_free(salt2_hash);
	buf_free(K);
	buf_free(S);
	buf_free(g_padded);
	buf_free(u);
	buf_free(k);
	buf_free(x);

	BN_free(g_bn);
	BN_free(x_bn);
	BN_free(a_bn);
	BN_free(A_bn);
	BN_free(u_bn);
	BN_free(k_bn);
	BN_free(v_bn);
	BN_free(kv_bn);
	BN_free(t_bn);
	BN_free(exp_bn);
	BN_free(S_bn);

	BN_CTX_free(ctx);
	
	ON_LOG(tg, "End input password SRP hash calculation");

	buf_free(srp);
	srp = tl_inputCheckPasswordSRP(id, &A, &M1);

	buf_free(A);
	buf_free(M1);
	
	return srp;
}

static tl_account_password_t *tg_account_getPassword(tg_t *tg)
{
	tl_t *tl = NULL; 
	
	// get account.password
	buf_t account_getPassword = 
		tl_account_getPassword();
	tl = tg_send_query_sync(tg, &account_getPassword);
	buf_free(account_getPassword);
	
	if (tl == NULL){
		ON_ERR(tg, "%s: TL is NULL", __func__);
		return NULL;
	}

	if (tl->_id == id_rpc_error){
		// throw error
		tl_rpc_error_t *error = (tl_rpc_error_t *)tl;
		ON_ERR(tg, "%s: %s", __func__, error->error_message_.data);
		tl_free(tl);
		return NULL;
	}

	if (tl->_id != id_account_password){
		ON_ERR(tg, "%s: expected: account_password, but got: %s",
			 	__func__, TL_NAME_FROM_ID(tl->_id));
		tl_free(tl);
		return NULL;
	}

	return (tl_account_password_t *)tl;
}

tl_user_t *
tg_auth_check_password(tg_t *tg, const char *password){
	
	tl_t *tl = NULL; 

/* Client-side, the following parameters are extracted from 
 * the passwordKdfAlgoSHA256SHA256PBKDF2HMACSHA512iter100000SHA256ModPow
 * object, contained in the account.password object. */

	tl_account_password_t *account_password = 
		tg_account_getPassword(tg);
	if (!account_password)
		return NULL;

	// check algo
	if (account_password->current_algo_->_id !=
			id_passwordKdfAlgoSHA256SHA256PBKDF2HMACSHA512iter100000SHA256ModPow
			)
	{
		ON_ERR(tg, "not supported password algo");
		return NULL;
	}

	tl_passwordKdfAlgoSHA256SHA256PBKDF2HMACSHA512iter100000SHA256ModPow_t 
		*algo = 
		(tl_passwordKdfAlgoSHA256SHA256PBKDF2HMACSHA512iter100000SHA256ModPow_t *)
		account_password->current_algo_;

	InputCheckPasswordSRP srp = tg_get_inputCheckPasswordSRP(
			tg, password, algo->salt1_, algo->salt2_, 
			algo->g_, algo->p_, 
			account_password->srp_B_, account_password->srp_id_);	

	if (srp.size == 0){
		return NULL;
	}

	buf_t auth_check_password = 
		tl_auth_checkPassword(&srp);
	buf_free(srp);

	tl = tg_send_query_sync(tg, &auth_check_password);
	buf_free(auth_check_password);

	if (!tl){
		ON_ERR(tg, "%s: TL is NULL", __func__);
		return NULL;
	}

	if (tl->_id == id_rpc_error){
		tl_rpc_error_t *error = (tl_rpc_error_t *)tl;
		ON_ERR(tg, "%s: %s", __func__, error->error_message_.data);
		tl_free(tl);
		return NULL;
	}

	if (tl->_id != id_auth_authorization){
		ON_ERR(tg, "%s: expected auth_authorization but got: %s",
				__func__, TL_NAME_FROM_ID(tl->_id));
		tl_free(tl);
		return NULL;
	}

	//printf("GOOD PASSWORD!!!!\n");
	
	// save auth_key_id 
	auth_key_to_database(tg, tg->key);

	// save ip address
	ip_address_to_database(tg, tg->ip);
		
	tl_user_t *user = (tl_user_t *)((tl_auth_authorization_t *)tl)->user_;
	return user;
}
