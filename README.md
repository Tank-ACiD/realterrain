# realterrain v.0.0.2
A Minetest mod that brings real world Terrain into the game (using freely available DEM tiles). Any image can actually be used.

use any image, even color (only red channel is used if color):

![screenshot_126233205](https://cloud.githubusercontent.com/assets/12679496/8270171/b98d0144-178e-11e5-9a21-ddea2624fdb6.png)

Supplied heightmap and landcover files:

![screenshot_20151019_202537](https://cloud.githubusercontent.com/assets/12679496/10597094/fa84812a-769f-11e5-822e-d0aa8b7f6e6d.png)

In game settings via the Realterrain Remote tool:

![screenshot_20151019_191222](https://cloud.githubusercontent.com/assets/12679496/10596232/de5796d0-7696-11e5-9dce-c991fa395f75.png)

### Dependencies:
- Luarocks
- Luarocks imlib2 package
- Mod security disabled

### Next steps:

- in game map reset, admin priv for using the tool, kick all players on reset
- improve land cover system, red channel for roads, blue for water, green for vegetation
- allow for in-game assignment of colors to cover types
- allow for placement of buildings and other structures via .mts import
- allow DEMs to tile according to standard naming conventions, or explicitly
- allow in-game selection of image files?
- allow output of heightmap and land cover to image files

### Changelog
#### 0.0.2
- switched to lua-imlib2 for support of all filetypes and bit depths
- supports downloaded GeoTIFF DEM tiles
- improved landcover
- added a tool, Realterrain Remote, which allows for:
- in game settings for initial tweaking (still requires deleting map.sqlite in world folder for full refresh of map)
- changed orientation of map to top left corner
- code cleanup, smaller supplied image files, screenshot and description for mod screen

#### 0.0.1
- direct file reading of 8 bit tifs