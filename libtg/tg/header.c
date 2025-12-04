#include "../tg/tg.h"
#include "transport.h"
#include <pthread.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <time.h>
#include <assert.h>
#ifdef __APPLE__
#include "darwin-posix-rt/darwin-posix-rt.h"
#endif

static void tg_my_clock_gettime(int clock_id, struct timespec * T)
{
  assert(clock_gettime(clock_id, T) >= 0);
}

static double tg_get_utime(int clock_id)
{
  struct timespec T;
  tg_my_clock_gettime(clock_id, &T);
  double res = T.tv_sec + (double) T.tv_nsec * 1e-9;
  return res;
}

static long long tg_get_current_time(tg_t *tg)
{
	long long ct = 
		(long long)((1LL << 32) * 
				tg_get_utime(CLOCK_REALTIME)) & -4;
	ct += tg->timediff;
	return ct;
}

buf_t tg_mtp_message(tg_t *tg, buf_t *payload, 
		uint64_t *msgid, bool content)
{
	/*ON_LOG(tg, "%s", __func__);*/
	//message msg_id:long seqno:int bytes:int body:Object = Message;
  buf_t msg = buf_new();
	
	// msg_id
	uint64_t msg_id = tg_get_current_time(tg);
	msg = buf_cat_ui64(msg, msg_id);	
	if (msgid)
		*msgid = msg_id;

	// seqno
	/* The seqno of a content-related message is thus
	  * msg.seqNo = (current_seqno*2)+1 (and after generating
	  * it, the local current_seqno counter must be
	  * incremented by
	  * 1), the seqno of a non-content related message is
	  * msg.seqNo = (current_seqno*2) (current_seqno must not
	  * be incremented by 1 after generation).*/

	// lock header for seqno
	int err = pthread_mutex_lock(&tg->seqnm);
	if (err){
		ON_ERR(tg, "%s: can't lock mutex: %d", __func__, err);
		return msg;
	}
	if (content)
		msg = buf_cat_ui32(msg, tg->seqn++ * 2 + 1);
	else {
		msg = buf_cat_ui32(msg, tg->seqn * 2);
	}
	pthread_mutex_unlock(&tg->seqnm);

	// bytes
	msg = buf_cat_ui32(msg, payload->size);	

	// body
	msg = buf_cat(msg, *payload);

	return msg;
}

buf_t tg_header(tg_t *tg, buf_t query, bool enc, 
		bool content, uint64_t *msgid)
{
	/*ON_LOG(tg, "%s", __func__);*/
  buf_t s = {};
	buf_init(&s);

  if (enc) {
	/* When receiving an MTProto message that is marked 
	 * as content-related by setting the least-significant 
	 * bit of the seqno, the receiving party must acknowledge 
	 * it in some way.
	 *
	 * When the receiving party is the client, this must 
	 * be done through msgs_ack constructors.
	 * 
	 * When the receiving party is the server, this is 
	 * usually done through msgs_ack constructors, but may 
	 * also be done using the reply of a method, or an 
	 * error, or some other way, as specified by the 
	 * documentation of each method or constructor.
	 *
	 * When a TCP transport is used, the content-relatedness 
	 * of constructors affects the server's behavior: the 
	 * server will resend not-yet acknowledged content-related 
	 * messages to a new connection if the current 
	 * connection is closed and then re-opened.
	 */
	if (*msgid)
		*msgid = 0;

	buf_t buf = buf_new();
	buf_t ack = tg_ack(tg);
	if (ack.size > 0){ // need to add acknolege
		//ON_LOG_BUF(tg, b, "SEND DATA:");
		/*ON_LOG_BUF(tg, ack, "SEND ACK:");*/
		content = false;
		// create container - do not use tl_generator -
		// container does not have vertor serialization in it
		buf_t msgs[2];
		uint64_t msg_id;
		msgs[0] = tg_mtp_message(tg, &query, 
				&msg_id, true);	
		msgs[1] = tg_mtp_message(tg, &ack, 
				NULL, false);	
		
		// add container id
		buf = buf_add_ui32(id_msg_container);

		// add size
		buf_t todrop = buf_new();
		int len = tg_to_drop(tg, &todrop);
		buf =  buf_cat_ui32(buf, 2+len);

		// add data
		buf =  buf_cat(buf,msgs[0]);
		buf =  buf_cat(buf,msgs[1]);

		// add tg_to_drop
		buf = buf_cat(buf, todrop);

		//ON_LOG_BUF(tg, b, "CONTAINER TO SEND: ");
		// set msgid
		if (msgid)
		 *msgid = msg_id;	
		
		buf_free(msgs[0]);
		buf_free(msgs[1]);
		buf_free(todrop);
	} else {
		// no need to ack
		buf = buf_cat(buf, query);
	}
	buf_free(ack);
		// salt  session_id message_id seq_no message_data_length  message_data padding12..1024
		// int64 int64      int64      int32  int32                bytes        bytes
		
		// salt
		s = buf_cat(s, tg->salt);
		
		//session_id
		s = buf_cat(s, tg->ssid);
		
		//message_id
		uint64_t _msgid = tg_get_current_time(tg);
		s = buf_cat_ui64(s, _msgid);
		if (msgid && *msgid == 0) // set msgid if not container
			*msgid = _msgid;
		
	 /* The seqno of a content-related message is thus
	  * msg.seqNo = (current_seqno*2)+1 (and after generating
	  * it, the local current_seqno counter must be
	  * incremented by
	  * 1), the seqno of a non-content related message is
	  * msg.seqNo = (current_seqno*2) (current_seqno must not
	  * be incremented by 1 after generation).*/
		//seq_no
		//s = buf_cat_ui32(s, tg->seqn);
		// lock header for seqno
		int err = pthread_mutex_lock(&tg->seqnm);
		if (err){
			ON_ERR(tg, "%s: can't lock mutex: %d", __func__, err);
			return s;
		}

		if (content)
			s = buf_cat_ui32(s, tg->seqn++ * 2 + 1);
		else {
			s = buf_cat_ui32(s, tg->seqn * 2);
		}
		
		pthread_mutex_unlock(&tg->seqnm);

		//message_data_length
		s = buf_cat_ui32(s, buf.size);
		
		//message_data
		s = buf_cat(s, buf);
		
		//padding
		uint32_t pad =  16 + (16 - (buf.size % 16)) % 16;
		s = buf_cat_rand(s, pad);

		buf_free(buf);

	} else {
		//auth_key_id = 0 message_id message_data_length message_data
		//int64           int64      int32               bytes

		//auth_key_id
		s = buf_cat_ui64(s, 0);
		
		//message_id
		s = buf_cat_ui64(s, tg_get_current_time(tg));
		
		//message_data_length
		s = buf_cat_ui32(s, query.size);
		
		// message_data
		s = buf_cat(s, query);
  }

	/*ON_LOG_BUF(tg, s, "%s: ", __func__);*/
  return s;
}

buf_t tg_deheader(tg_t *tg, buf_t b, bool enc)
{
	/*ON_LOG(tg, "%s", __func__);*/
	if (!b.size){
		ON_ERR(tg, "%s: got nothing", __func__);
		return b;
	}

  buf_t d;
	buf_init(&d);

  if (enc){
		// salt  session_id message_id seq_no message_data_length  message_data padding12..1024
		// int64 int64      int64      int32  int32                bytes        bytes
		
		// salt
		uint64_t salt = deserialize_ui64(&b);
		// update server salt
		tg->salt = buf_add_ui64(salt);
		
		// session_id
		uint64_t ssid = deserialize_ui64(&b);
		// check ssid
		if (ssid != buf_get_ui64(tg->ssid)){
			ON_ERR(tg, "%s: session id mismatch!", __func__);
			//return d;
		}
			
		// message_id
		uint64_t msg_id = deserialize_ui64(&b);
		// add message id to array
		tg_add_msgid(tg, msg_id);
		
		// seq_no
		uint32_t seq_no = deserialize_ui32(&b);

		// data len
		uint32_t msg_data_len = deserialize_ui32(&b);
		// set data len without padding
		b.size = msg_data_len;
		
  ON_LOG(tg, "%s: %d", __func__, __LINE__);
		d = buf_cat(d, b);
  
	} else {
	//auth_key_id = 0 message_id message_data_length message_data
	//int64           int64      int32               bytes
		
		// auth_key_id
		uint64_t auth_key_id = buf_get_ui64(b);
		if (auth_key_id != 0){
			ON_ERR(tg, 
					"%s: auth_key_id is not 0 for unencrypted message", __func__);
			return b;
		}
		auth_key_id = deserialize_ui64(&b);

		// message_id
		uint64_t msg_id = deserialize_ui64(&b);

		// message_data_length
		uint32_t msg_data_len = deserialize_ui32(&b);

		d = buf_cat(d, b);

		// check len matching
		if (msg_data_len != b.size){
			ON_LOG(tg, 
					"%s: msg_data_len mismatch: expected: %d, got: %d", 
					__func__, msg_data_len, b.size);
		}
	}
	/*ON_LOG_BUF(tg, d, "%s: ", __func__);*/
  return d;
}
