# realterrain v.0.0.3
A Minetest mod that brings real world Terrain into the game (using freely available DEM tiles). Any image can actually be used.

use any image, even color (only red channel is used if color):

![screenshot_126233205](https://cloud.githubusercontent.com/assets/12679496/8270171/b98d0144-178e-11e5-9a21-ddea2624fdb6.png)

Supplied heightmap and landcover files:

![biomes](https://cloud.githubusercontent.com/assets/12679496/10683908/fffbac4c-78fb-11e5-8190-4f0c0561b4b1.png)
![dem](https://cloud.githubusercontent.com/assets/12679496/10683910/00078544-78fc-11e5-9806-1c0786b3fa4e.png)
![roads](https://cloud.githubusercontent.com/assets/12679496/10683909/fffec6b6-78fb-11e5-9947-37de7a21d770.png)
![water](https://cloud.githubusercontent.com/assets/12679496/10683911/000b474c-78fc-11e5-93f8-0aeb228446be.png)

Biome painting (every 10% of grayscale is a new biome):

![screenshot_20151020_152358](https://cloud.githubusercontent.com/assets/12679496/10622832/c79896c6-773e-11e5-881f-e8e13b906ea1.png)

Rock strata:

![screenshot_20151022_202823](https://cloud.githubusercontent.com/assets/12679496/10683866/771561ac-78fb-11e5-8fb4-6e9d876fcc67.png)

Settings tool (Realterrain Remote)

![screenshot_20151020_141450](https://cloud.githubusercontent.com/assets/12679496/10622825/c2506d06-773e-11e5-81e3-7ac00c0733fa.png)

### Dependencies:
- Luarocks
- Luarocks magick package
- Mod security disabled

### Next steps:

- improve land cover system, add trees, make biomes better than just wool colors!
- allow for in-game assignment of biome values, (water depth? road and building values?)
- allow for placement of buildings and other structures via .mts import
- allow DEMs to tile according to standard naming conventions, or explicitly
- allow output of heightmap and land cover to image files

### Changelog
#### 0.0.3
- switched to luarocks "magick" library
- included a biome painting layer, broke the "cover" layer into roads and water layers
- added the files used to the settings tool
- added strata for under the ground
- in game map reset, admin priv for using the tool, kick all players on reset

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