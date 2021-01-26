//
//  Created by David Knothe on 02.04.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "execute_cmd.h"

char* execute_cmd(const char* cmd) {
    void* fp = popen(cmd, "r");
    if (!fp) return NULL;

    int size = 255;
    char* buf = malloc((size + 1) * sizeof(char));
    memset(&buf[0], 0, sizeof(buf));

    char* current = buf;
    while (size > 1 && fgets(current, size, fp)) { // Read all lines
        size -= strlen(current);
        current += strlen(current);
    }

    return buf;
}
