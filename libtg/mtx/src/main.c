//
//  main.c
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include "../include/api.h"

// srl -- service layer
// trl -- transport layer
// sel -- serialization layer
// enl -- encrypt layer
// tml -- tg methods layer
// tgt -- tg types
// stk -- stack
// sil -- simple interm. layer
// scl -- stel client layer
// hdl -- header def. layer

int main()
{
  app_t app;

  api.log.info("Start.");

  app = api.app.open(_ip, _port);
  api.app.run(app);

  api.log.info("Finish.");

  return api.app.close(app);
}
