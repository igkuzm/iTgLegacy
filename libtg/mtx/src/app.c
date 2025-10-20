//
//  app.c
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include "../include/api.h"

app_t app_open(char *ip, int port)
{
  app_t app;

  app.exit_code = 0;
  reset_shared_rc();
  app.scl = api.scl.open(ip, port);

  return app;
}

ui8_t app_run(app_t app)
{
  api.scl.run();

  return app.exit_code;
}

ui8_t app_close(app_t app)
{
  api.scl.close();

  return app.exit_code;
}
