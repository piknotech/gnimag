//
//  Created by David Knothe on 02.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

#ifndef execute_cmd_h
#define execute_cmd_h

/// Execute a shell command and return the result.
/// This is faster than the Swift-approach with Process/NSTask.
/// Attention: if not otherwise specified, stderr is directly forwarded to the parent process's stderr.
char* execute_cmd(const char* cmd);

#endif /* execute_cmd_h */
