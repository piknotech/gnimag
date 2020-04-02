//
//  Created by David Knothe on 02.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "execute_cmd.h"

char* execute_cmd(const char* cmd) {
    void* fp = popen(cmd, "r");

    int size = 256;
    char* buf = malloc(size * sizeof(char));
    memset(&buf[0], 0, sizeof(buf));

    char* current = buf;
    while (fgets(current, size, fp)) { // Read all lines
        current += strlen(current);
    }

    return buf;
}
