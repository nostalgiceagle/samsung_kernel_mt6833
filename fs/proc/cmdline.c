// SPDX-License-Identifier: GPL-2.0
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <asm/setup.h>
#include <linux/string.h>

static char proc_cmdline[COMMAND_LINE_SIZE];

static void remove_flag(char *cmd, const char *flag)
{
    char *start_addr, *end_addr;
    while ((start_addr = strstr(cmd, flag))) {
        end_addr = strchr(start_addr, ' ');
        if (end_addr)
            memmove(start_addr, end_addr + 1, strlen(end_addr));
        else
            *(start_addr - 1) = '\0';
    }
}

static void remove_safetynet_flags(char *cmd)
{
    remove_flag(cmd, "androidboot.enable_dm_verity=");
    remove_flag(cmd, "androidboot.secboot=");
    remove_flag(cmd, "androidboot.veritymode=");
}

static int cmdline_proc_show(struct seq_file *m, void *v)
{
	seq_puts(m, proc_cmdline);
	seq_putc(m, '\n');
	return 0;
}

static int __init proc_cmdline_init(void)
{
    char *a1, *a2;

    /* SafetyNet bypass: show androidboot.verifiedbootstate=green */
    a1 = strstr(saved_command_line, "androidboot.verifiedbootstate=");
    if (a1) {
        a1 = strchr(a1, '=');
        a2 = strchr(a1, ' ');
        if (!a2)
           a2 = "";

        scnprintf(proc_cmdline, COMMAND_LINE_SIZE, "%.*sgreen%s",
                 (int)(a1 - saved_command_line + 1),
                 saved_command_line, a2);
    } else {
         strncpy(proc_cmdline, saved_command_line, COMMAND_LINE_SIZE);
    }

    /*
     * Remove various flags from command line seen by userspace
     * in order to pass SafetyNet CTS check.
     */
    remove_safetynet_flags(proc_cmdline);

    /*
     * In order to spoof Knox values to 0x0, From void to valid.
     */

    /* Spoof androidboot.boot.warranty_bit to 0 */
    a1 = strstr(proc_cmdline, "androidboot.boot.warranty_bit=");
    if (a1) {
        a1 = strchr(a1, '=');
        if (a1) {
            a1++;
            a2 = strchr(a1, ' ');
            if (a2) {
                memmove(a1 + 1, a2, strlen(a2) + 1);
                *a1 = '0';
            } else {
                strcpy(a1, "0");
            }
            strncat(proc_cmdline, " ro.boot.warranty_bit=0", COMMAND_LINE_SIZE - strlen(proc_cmdline) - 1);
        }
    }

    /* Spoof androidboot.warranty_bit to 0 */
    a1 = strstr(proc_cmdline, "androidboot.warranty_bit=");
    if (a1) {
        a1 = strchr(a1, '=');
        if (a1) {
            a1++;
            a2 = strchr(a1, ' ');
            if (a2) {
                memmove(a1 + 1, a2, strlen(a2) + 1);
                *a1 = '0';
            } else {
                strcpy(a1, "0");
            }
            strncat(proc_cmdline, " ro.warranty_bit=0", COMMAND_LINE_SIZE - strlen(proc_cmdline) - 1);
        }
    }

	proc_create_single("cmdline", 0, NULL, cmdline_proc_show);
	return 0;
}
fs_initcall(proc_cmdline_init);
