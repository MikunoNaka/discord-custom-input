# discord-custom-input
Merge two or more audio streams to share desktop audio on discord/any other program

## How to install
To download and make script executable:

```
curl -s https://raw.githubusercontent.com/MikunoNaka/discord-custom-input/main/discord_input.sh > discord_input.sh
chmod +x discord_input.sh
```

I recommend moving the script to your $PATH.

## How to use
Run the script with `./discord_input.sh` or add the script to $PATH to eliminate the `./`

Show help with `discord_input -h`

NOTE: You can configure the loopbacks created using pavucontrol.

### Arguments available
- Specify the number of sources/streams to merge together with `-n`
```
discord_input.sh -n 3   # merges 3 streams together
```
If not specified, it will ask you

- Pass the sources to loopback from with `-s`. you don't need to pass `-n` with this.
Interactive mode will be disabled
```
discord_input.sh -s bluez_sink.B8_69_C2_A6_32_96.handsfree_head_unit.monitor -s bluez_source.B8_69_C2_A6_32_96.handsfree_head_unit -S no
```

you can either use `pacmd-list-sources` or interactive (without `-s` flag) mode to see the source name. This flag is useful for use with keybindings, etc.


if you are using the `-s` flag, you can't use `-S ask`

- Automatically change discord's input if you are in a VC with `-S yes|no|ask`
```
discord_input.sh -S ask # default option, asks if you want to switch discord's input
discord_input.sh -S no  # don't switch discord's input
discord_input.sh -S yes # switch discord's input
```

- Change name of new virtual sink created with `-N`
```
discord_input.sh -N MySinkName
```
Helps avoid confusion if you are using multiple instances of this.

- Change description of new virtual sink with `-D`
```
discord_input.sh -D MySinkDescription
```

## Licence
Licenced under GNU General Public Licence

GNU GPL Licence: https://www.gnu.org/licenses/

Copyright (c) 2021 Vidhu Kant Sharma
