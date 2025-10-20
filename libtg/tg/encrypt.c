#include "../tg/tg.h"
#include "../crypto/hsh.h"
#include "../crypto/cry.h"
#include <stdio.h>

buf_t tg_encrypt(tg_t *tg, buf_t b, bool enc)
{
	//ON_LOG(tg, "%s", __func__);
  buf_t e = {};
	buf_init(&e);

  if (enc) {
		// For MTProto 2.0, SHA1 is still used here, because
		// auth_key_id should identify the authorization key
		// used independently of the protocol version.
		buf_t key_hash = tg_hsh_sha1(tg->key);
		buf_t auth_key_id = 
			buf_add(key_hash.data + 12, 8);
		buf_free(key_hash);

	/* For MTProto 2.0, the algorithm for computing aes_key 
	 * and aes_iv from auth_key and msg_key is as follows.
	 * • msg_key_large = SHA256 (substr (auth_key, 88+x, 32) + 
	 *   plaintext + random_padding);
	 * • msg_key = substr (msg_key_large, 8, 16);
	 * • sha256_a = SHA256 (msg_key + substr (auth_key, x, 36));
	 * • sha256_b = SHA256 (substr (auth_key, 40+x, 36) + msg_key);
	 * • aes_key = substr (sha256_a, 0, 8) + 
	 *   substr (sha256_b, 8, 16) + substr (sha256_a, 24, 8);
	 * • aes_iv = substr (sha256_b, 0, 8) + 
	 * substr (sha256_a, 8, 16) + substr (sha256_b, 24, 8);
	 * where x = 0 for messages from client to server 
	 * and x = 8 for those from server to client. */

		//msg_key_large = SHA256 (substr (auth_key, 88+x, 32) 
		//+ plaintext + random_padding);
		buf_t msg_key_large_ = 
			buf_add(tg->key.data + 88, 32);
		msg_key_large_ = buf_cat(msg_key_large_, b);
		buf_t msg_key_large = tg_hsh_sha256(msg_key_large_);
		buf_free(msg_key_large_);

		// msg_key = substr (msg_key_large, 8, 16);
		buf_t msg_key = 
			buf_add(msg_key_large.data + 8, 16);
		buf_free(msg_key_large);

		//sha256_a = SHA256 (msg_key + substr (auth_key, x, 36));
		buf_t sha256_a_ = 
			buf_add(msg_key.data, msg_key.size);
		sha256_a_ = 
			buf_cat_data(sha256_a_, tg->key.data, 36);
		buf_t sha256_a = tg_hsh_sha256(sha256_a_);
		buf_free(sha256_a_);

		//sha256_b = SHA256 (substr (auth_key, 40+x, 36) + msg_key);
		buf_t sha256_b_ = 
			buf_add(tg->key.data + 40, 36);
		sha256_b_ = 
			buf_cat_data(sha256_b_, msg_key.data, msg_key.size);
		buf_t sha256_b = tg_hsh_sha256(sha256_b_);
		buf_free(sha256_b_);

		//aes_key = substr (sha256_a, 0, 8) 
		//+ substr (sha256_b, 8, 16) + substr (sha256_a, 24, 8);
		buf_t aes_key = buf_add(sha256_a.data, 8);
		aes_key = 
			buf_cat_data(aes_key, sha256_b.data + 8, 16);
		aes_key = 
			buf_cat_data(aes_key, sha256_a.data + 24, 8);

		//aes_iv = substr (sha256_b, 0, 8) + 
		//substr (sha256_a, 8, 16) + substr (sha256_b, 24, 8);
		buf_t aes_iv = buf_add(sha256_b.data, 8);
		aes_iv = 
			buf_cat_data(aes_iv, sha256_a.data + 8, 16);
		aes_iv = 
			buf_cat_data(aes_iv, sha256_b.data + 24, 8);
		
		// Encrypted Message: encrypted_data
		buf_t enc = tg_cry_aes_e(b, aes_key, aes_iv);
		buf_free(aes_key);
		buf_free(aes_iv);
		buf_free(sha256_a);
		buf_free(sha256_b);
		
		// Encrypted Message
		// auth_key_id msg_key encrypted_data
		// int64       int128  bytes
		e = buf_cat(e, auth_key_id);
		e = buf_cat(e, msg_key);
		e = buf_cat(e, enc);
		buf_free(auth_key_id);
		buf_free(msg_key);
		buf_free(enc);

	}else {
		e = buf_cat(e, b);	
	}

	//ON_LOG_BUF(tg, e, "%s: ", __func__);
  return e;
}

buf_t tg_decrypt(tg_t *tg, buf_t m, bool enc)
{
	//ON_LOG(tg, "%s", __func__);
  buf_t d;
	buf_init(&d);

	if (!m.size) {
    ON_LOG(tg, "%s: received nothing", __func__);
		return d;
  }

  if (enc){
		
		// Encrypted Message
		// auth_key_id msg_key encrypted_data
		// int64       int128  bytes
			
		// auth_key
		uint64_t auth_key_id = buf_get_ui64(m);
		// check matching
		buf_t key_hash = tg_hsh_sha1(tg->key);
		buf_t auth_key_id_ = buf_add(key_hash.data + 12, 8);
		if (auth_key_id != buf_get_ui64(auth_key_id_)){
			ON_ERR(tg, "%s: auth_key_id mismatch", __func__);
			buf_free(auth_key_id_);
			return d;
		}
		buf_free(auth_key_id_);
		auth_key_id = deserialize_ui64(&m);

		// msg_key
		buf_t msg_key = deserialize_buf(&m, 16);
		
		// check encrypted_data size
		if (m.size % 16 != 0){
			ON_ERR(tg, "(length %% AES_BLOCK_SIZE) != 0");	
			return d;
		}
		// encrypted_data
		//sha256_a = SHA256 (msg_key + substr (auth_key, x, 36));
		buf_t sha256_a_ = 
			buf_add(msg_key.data, msg_key.size);
		sha256_a_ = 
			buf_cat_data(sha256_a_, tg->key.data + 8, 36);
		buf_t sha256_a = tg_hsh_sha256(sha256_a_);
		buf_free(sha256_a_);

		//sha256_b = SHA256 (substr (auth_key, 40+x, 36) + msg_key);
		buf_t sha256_b_ = 
			buf_add(tg->key.data + 40+8, 36);
		sha256_b_ = 
			buf_cat(sha256_b_, msg_key);
		buf_t sha256_b = tg_hsh_sha256(sha256_b_);
		buf_free(sha256_b_);
		
		//aes_key = substr (sha256_a, 0, 8) 
		//+ substr (sha256_b, 8, 16) + substr (sha256_a, 24, 8);
		buf_t aes_key = buf_add(sha256_a.data, 8);
		aes_key = buf_cat_data(aes_key, sha256_b.data + 8, 16);
		aes_key = buf_cat_data(aes_key, sha256_a.data + 24, 8);
		
		//aes_iv = substr (sha256_b, 0, 8) + 
		//substr (sha256_a, 8, 16) + substr (sha256_b, 24, 8);
		buf_t aes_iv = buf_add(sha256_b.data, 8);
		aes_iv = buf_cat_data(aes_iv, sha256_a.data + 8, 16);
		aes_iv = buf_cat_data(aes_iv, sha256_b.data + 24, 8);
		
		d = tg_cry_aes_d(m, aes_key, aes_iv);

	} else{
		d = buf_cat(d, m);
	}

	//ON_LOG_BUF(tg, d, "%s: ", __func__);
  return d;
}
