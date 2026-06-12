#include "config.h"

#ifdef __CONFIG__
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

extern bool should_use_hirestimer;
extern bool should_use_extended;
extern bool should_use_alpha;
extern bool should_use_cached_sprites;
extern bool should_draw_manabar;
extern bool should_redirect_network;
extern char network_redirect_host[256];
extern unsigned short network_redirect_login_port;

bool checkBool(char *buffer)
{
	if(stricmp(buffer, "1") == 0 || stricmp(buffer, "yes") == 0 || stricmp(buffer, "true") == 0)
		return true;

	return false;
}

static char* trim(char* buffer)
{
	while(*buffer && isspace((unsigned char)*buffer))
		buffer++;

	char* end = buffer + strlen(buffer);
	while(end > buffer && isspace((unsigned char)*(end - 1)))
		*(--end) = '\0';

	return buffer;
}

void loadConfig()
{
	should_use_hirestimer = false;
	should_use_extended = true;
	should_use_alpha = false;
	should_use_cached_sprites = true;
	should_draw_manabar = true;
	should_redirect_network = false;
	network_redirect_host[0] = '\0';
	network_redirect_login_port = 0;

	FILE* f = fopen("config.ini", "rb");
	if(!f)
		return;

	bool redirectConfigured = false;
	while(!feof(f))
	{
		char read_buffer[2048] = {0};
		char *buffer = fgets(read_buffer, sizeof read_buffer, f);
		if(!buffer)
			break;

		buffer = trim(buffer);
		if(buffer[0] != '#' && buffer[0] != '-' && buffer[0] != '\0')
		{
			char* pch = strchr(buffer, '=');
			if(pch)
			{
				*pch = '\0';
				char* key = trim(buffer);
				char* value = trim(pch + 1);
				if(stricmp(key, "hirestimer") == 0)
					should_use_hirestimer = checkBool(value);
				else if(stricmp(key, "extended") == 0)
					should_use_extended = checkBool(value);
				else if(stricmp(key, "alpha") == 0)
					should_use_alpha = checkBool(value);
				else if(stricmp(key, "cachesprites") == 0)
					should_use_cached_sprites = checkBool(value);
				else if(stricmp(key, "drawmanabar") == 0)
					should_draw_manabar = checkBool(value);
				else if(stricmp(key, "redirectconnections") == 0 || stricmp(key, "redirectlogin") == 0)
				{
					should_redirect_network = checkBool(value);
					redirectConfigured = true;
				}
				else if(stricmp(key, "loginhost") == 0 || stricmp(key, "serverhost") == 0)
				{
					strncpy(network_redirect_host, value, sizeof(network_redirect_host) - 1);
					network_redirect_host[sizeof(network_redirect_host) - 1] = '\0';
				}
				else if(stricmp(key, "loginport") == 0 || stricmp(key, "serverport") == 0)
				{
					int port = atoi(value);
					if(port > 0 && port <= 65535)
						network_redirect_login_port = (unsigned short)port;
				}
			}
		}
	}

	if(f)
		fclose(f);

	if(!redirectConfigured && network_redirect_host[0] != '\0')
		should_redirect_network = true;
}
#endif
