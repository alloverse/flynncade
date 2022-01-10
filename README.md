# Flynncade

Yo. It's a VR arcade for Alloverse. Get it.

## Getting started

1. Install RetroArch: `sudo add-apt-repository ppa:libretro/stable && sudo apt-get update && sudo apt-get install retroarch`
2. Install the requires RetroArch cores: `sudo apt-get install libretro-nestopia libretro-genesisplusgx libretro-snes9x`
3. Compile the C parts of this library: `make`
4. `./allo/assist fetch` to get allonet

## Developing and running

Application sources are in `lua/`.

To start the app and connect it to an Alloplace for testing, run

```
./allo/assist run alloplace://nevyn.places.alloverse.com
```

## License

### Flynncade is MIT licensed

### Flynncade uses these licenses

"Magnavox 19" CRT TV - RR1938 W122" (https://skfb.ly/o6xw8) by amhyde is licensed under Creative Commons Attribution (http://creativecommons.org/licenses/by/4.0/).

"Snes Controller" (https://skfb.ly/6ZWq7) by Max de Jesus is licensed under Creative Commons Attribution (http://creativecommons.org/licenses/by/4.0/).
