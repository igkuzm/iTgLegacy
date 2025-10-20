//
//  sel.c
//  mtx
//
//  Created by Pavel Morozkin on 18.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include "../include/api.h"
#include "../include/buf.h"

sel_t sel_init(trl_t trl)
{
  sel_t sel;

  return sel;
}

buf_t_ sel_serialize_id(buf_t_ b)
{
  buf_t_ s;
	//buf_init(&s);
  s = api.buf.add(b.data, 4);

  return s;
}

buf_t_ sel_serialize_param(param_t p)
{
  buf_t_ s;
	//buf_init(&s);

  switch (p.type)
  {
    case TYPE_INT:
    {
      s = api.buf.add(p.value.data, 4);

      break;
    }
    case TYPE_INT128:
    {
      s = api.buf.add(p.value.data, 16);

      break;
    }
    case TYPE_INT256:
    {
      s = api.buf.add(p.value.data, 32);

      break;
    }
    case TYPE_LONG:
    {
      s = api.buf.add(p.value.data, 8);

      break;
    }
    case TYPE_VECTOR_LONG:
    {
      s = api.buf.add(p.value.data, p.value.size);

      break;
    }
    case TYPE_STRING:
    {
      s = api.sel.serialize_string(p.value);

      break;
    }
    case TYPE_ID:
    {
      s = api.buf.add(p.value.data, 4);

      break;
    }
		case TYPE_QX:
    {
      s = api.buf.add(p.value.data, p.value.size);

      break;
    }

    default:
    {
			printf("TYPE: %d\n", p.type);
      api.log.error("unknown type");

      break;
    }
  }

  return s;
}

param_t sel_deserialize_param(param_t p)
{
  buf_t_ s;
	//buf_init(&s);

  switch (p.type)
  {
    case TYPE_INT:
    {
      s = api.buf.add(p.value.data, 4);

      break;
    }
    case TYPE_INT128:
    {
      s = api.buf.add(p.value.data, 16);

      break;
    }
    case TYPE_INT256:
    {
      s = api.buf.add(p.value.data, 32);

      break;
    }
    case TYPE_LONG:
    {
      s = api.buf.add(p.value.data, 8);

      break;
    }
    case TYPE_VECTOR_LONG:
    case TYPE_VECTOR_MESSAGE:
    {
      s = api.sel.deserialize_vector(p);

      break;
    }
    case TYPE_STRING:
    {
      s = api.sel.deserialize_string(p.value);

      break;
    }
    case TYPE_ID:
    {
      s = api.buf.add(p.value.data, 4);

      break;
    }
    case TYPE_MESSAGE:
    {
      s = api.buf.add(p.value.data, p.value.size);

      break;
    }
    default:
    {
      api.log.error("unknown type");

      break;
    }
  }

  param_t rp;
  rp.type = p.type;
  rp.value = s;

  return rp;
}

buf_t_ sel_deserialize_string(buf_t_ b)
{
	/*buf_dump(b);*/
  buf_t_ s;
	//buf_init(&s);
  buf_t_ byte = api.buf.add(b.data, 4);
  int offset = byte.data[0];

  /*if (byte.data[0] <= 253 && !b.data[1 + offset] && !b.data[2 + offset] && !b.data[3 + offset]) {*/
  if (byte.data[0] <= 253) {
    ui32_t size = byte.data[0];
    s = api.buf.add(b.data + 1, size);
  } else if (byte.data[0] >= 254) {
    ui8_t start = 0xfe;
    buf_t_ s1 = api.buf.add((ui8_t *)&start, 1);
    buf_t_ s2 = api.buf.add(b.data, 1);

    if (!api.buf.cmp(s1, s2)) {
      api.log.error("can't deserialize string");
    }

    buf_t_ len_ = api.buf.add(b.data + 1, 3);
    len_.size = 4; // hack
    ui32_t len = api.buf.get_ui32(len_);
    b = api.buf.add(b.data + 4, b.size - 4);
    s = api.buf.add(b.data, len);
  } else {
    api.log.error("can't deserialize string");
  }

  return s;
}

buf_t_ sel_serialize_string(buf_t_ b)
{
  buf_t_ s = {};
	//buf_init(&s);
  ui32_t size = b.size;

  if (size <= 253) {
    s = api.buf.add((ui8_t *)&size, 1);
    s = api.buf.cat(s, b);
    int pad = (4 - (s.size % 4)) % 4;
    buf_t_ p = {};
		//buf_init(&p);
    p.size = pad;
    s = api.buf.cat(s, p);
  } else if (size >= 254) {
    ui8_t start = 0xfe;
    s = api.buf.add((ui8_t *)&start, 1);
    buf_t_ len = api.buf.add((ui8_t *)&size, 3);
    s = api.buf.cat(s, len);
    s = api.buf.cat(s, b);
    int pad = (4 - (s.size % 4)) % 4;

    if (pad) {
      buf_t_ p = {};
			//buf_init(&p);
      p.size = pad;
      s = api.buf.cat(s, p);
    }
  } else {
    api.log.error("can't serialize string");
  }

  return s;
}

buf_t_ sel_serialize(abstract_t a)
{
  buf_t_ b;
	//buf_init(&b);
  buf_t_ s = {};
	//buf_init(&s);

  for (ui32_t i = 0; i < a.size; ++i) {
    b = api.sel.serialize_param(a.params[i]);
    s = api.buf.cat(s, b);
    //api.buf.dump(b);
  }

  return s;
}

abstract_t sel_deserialize(buf_t_ b)
{
  abstract_t a;
  ui32_t id = api.buf.get_ui32(b);
  a.params[0].type = TYPE_ID;
  a.params[0].value = api.buf.add_ui32(id);
  // rem id
  b = api.buf.add(b.data + 4, b.size - 4);
  a.params[1].value = b;

  return a;
}

buf_t_ sel_deserialize_vector(param_t p)
{
  //api.buf.dump(p.value);
  buf_t_ d;
	//buf_init(&d);
  buf_t_ b = p.value;
  ui32_t id = api.buf.get_ui32(b);

  if (id != _id_Vector) {
    api.log.error("this is not vector id");
  }

  b = api.buf.add(b.data + 4, b.size - 4);
  ui32_t q = api.buf.get_ui32(b);

  if (!q) {
    api.log.info("empty container deserialized");
    buf_t_ e = {};
		//buf_init(&e);

    return e;
  }

  b = api.buf.add(b.data + 4, b.size - 4);
  /* Bad logic, ugly code. I will modify it. Sorry... */
  param_t p_[max_param_size];

  for (uint32_t i = 0; i < q; ++i) {
    switch (p.id)
    {
      case _id_resPQ:
      {
        p_[i].type = TYPE_LONG;
        p_[i].value = b;
        p_[i] = api.sel.deserialize_param(p_[i]);
        d = p_[i].value;

        break;
      }
      case _id_msg_container:
      {
        p_[i].type = TYPE_MESSAGE;
        p_[i].value = b;
        p_[i] = api.sel.deserialize_param(p_[i]);
        d = p_[i].value;

        break;
      }
      default: {
        break;
      }
    }
  }

  return d;
}
