# realterrain
a Minetest mod that brings real world Terrain into the game (using freely available DEM tiles)

![screenshot_51364970](https://cloud.githubusercontent.com/assets/12679496/8266202/46b5b892-16de-11e5-8bce-c3799cbace5c.png)

### Current status:
all this mod does right now is translates an 8-bit greyscale TIF image into a minetest map with no trees or biomes, or even any underground details -- no ores, no caves, nothing.

included is a large tile of DEM from central/southern British Columbia, converted into a mosaicked dem reduced to 8 bits. you must unzip it though, and change the first line in init.lua to reflect your chosen file. also included is an eyeball.

![screenshot_126233205](https://cloud.githubusercontent.com/assets/12679496/8270171/b98d0144-178e-11e5-9a21-ddea2624fdb6.png)

### Next steps:

handle 16-bit greyscales, indexed color (for land cover / biomes, rivers / roads, etc), RGB imagery for colorizing the map (mostly for fun, or instead of indexed color biome selection...), ascii-format files such as .dem, vector format files such as .shp, TINs, etc, and eventually tackle pulling vector data live from USGS, OSM, Google maps, including 3D buildings, etc.