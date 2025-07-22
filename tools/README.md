# Map Seeder Tool

This tool helps you create and test different hex tile configurations for your Godot game by reading data from CSV files instead of hardcoded values.

## Features

- **CSV-driven configuration**: Edit maps, tiles, and map layouts using simple CSV files
- **Sample data generation**: Automatically creates sample CSV files to get you started
- **Database integration**: Directly seeds your game's database with the CSV data
- **Export functionality**: Export current database state as seed functions for backup

## CSV File Structure

### maps.csv
```
name,width,height,description,starting_tileset_x,starting_tileset_y
Simple Map Test,9,9,A diverse world with forests, mountains, arid lands, and varied terrain in a 9x9 grid,0,0
Tutorial Forest,20,15,A small forest area perfect for learning the basics,0,0
```

### tiles.csv
```
type_name,initials,is_walkable,is_top_blocked,is_bottom_blocked,is_middle_blocked,time_to_cross,description
forest,F,true,false,false,false,1,Dense forest with trees
mountain,M,false,true,true,true,999,Tall impassable mountains
```

**Note**: Texture paths are automatically generated as `res://assets/tiles/tilev3_{type_name}.png`

### map_tiles.csv (Grid Format)
```
G,G,E,E,F,F,F,G,G
G,E,E,F,F,F,G,G,G
E,E,F,F,V,G,G,C,C
F,F,F,V,A,A,A,C,M
F,V,G,G,A,A,A,M,M
F,G,G,A,A,V,V,N,G
G,G,G,A,V,V,G,G,G
G,G,G,G,G,G,G,G,G
G,G,G,G,G,G,G,G,G
```

**Grid Format**: Each cell represents a tile position where:
- **Rows** = Y coordinates (top to bottom)
- **Columns** = X coordinates (left to right)
- **Cell values** = Tile initials (e.g., G=grassland, F=forest, M=mountain)

### abilities.csv
```
name,base_value,max_value,display_order,description
Scoundrel,0,6,1,Sneaking, thievery, and cunning
Warrior,0,6,2,One-handed weapon mastery
```

### skills.csv
```
name,ability_conditions,level,cost,tags,cast_conditions,effect,description
Fireball,"{""pyromancer"": 1}",1,"{""mana"": 10}",combat,spell,fire,combat,Deal 15 fire damage to target,A basic fire spell that deals damage to enemies
```

**Note**: Skills require specific abilities as prerequisites. The `ability_conditions` field contains JSON that specifies which abilities and levels are required.

## How to Use

1. **Open the tool**: Load `res://tools/map_seeder.tscn` in Godot
2. **Create sample files**: Click "Create Sample CSV Files" to generate initial CSV files
3. **Edit CSV files**: Modify the CSV files in `res://tools/data/` to create your desired maps
4. **Seed the database**: Click "Seed All from CSV" to apply your changes to the database
5. **Test in game**: Run your game to see the new map configurations

## CSV File Locations

- `res://tools/data/maps.csv` - Map definitions
- `res://tools/data/tiles.csv` - Tile type definitions  
- `res://tools/data/map_tiles.csv` - Map layout definitions
- `res://tools/data/abilities.csv` - Ability definitions
- `res://tools/data/skills.csv` - Skill definitions

## Tips for Creating Maps

### Tile Types
- Use descriptive names like `forest`, `mountain`, `grassland`
- Set `is_walkable` to `true` for passable tiles, `false` for obstacles
- Use `time_to_cross` of `1` for normal tiles, higher values for difficult terrain
- Set blocking flags (`is_top_blocked`, `is_bottom_blocked`, `is_middle_blocked`) to control pathfinding
- Texture paths are automatically generated as `res://assets/tiles/tilev3_{type_name}.png`

### Map Layouts (Grid Format)
- Each row represents a Y coordinate (top to bottom)
- Each column represents an X coordinate (left to right)
- Cell values are tile initials that must match tiles defined in `tiles.csv`
- The grid size determines the map dimensions

### Abilities
- Define the 12 core abilities that characters can develop
- Each ability has a base value, max value, and display order
- Abilities are prerequisites for skills

### Skills
- Skills require specific abilities as prerequisites
- The `ability_conditions` field contains JSON specifying required abilities and levels
- Skills have costs, tags, cast conditions, and effects

### Example: Creating a Forest Map
1. Add forest tiles to `tiles.csv`:
   ```
   dense_forest,DF,true,false,false,false,2,Dense forest
   light_forest,LF,true,false,false,false,1,Light forest
   ```

2. Add map definition to `maps.csv`:
   ```
   Forest Adventure,15,15,A mysterious forest with varying density
   ```

3. Add layout to `map_tiles.csv` (grid format):
   ```
   DF,LF,DF,LF,DF
   LF,DF,LF,DF,LF
   DF,LF,DF,LF,DF
   LF,DF,LF,DF,LF
   DF,LF,DF,LF,DF
   ```

## Export Functionality

The tool can export the current database state as GDScript seed functions. This is useful for:
- Backing up your configurations
- Sharing map designs with others
- Version control of your map data

Click "Export Seed Functions" to generate `res://tools/exported_seed_functions.gd`

### overlays.csv
```
name,initials,texture_path,description,display_order
Desert Landmark 1,D1,res://assets/overlays/landmark_desert_1.png,A mysterious desert landmark,1
Sample Landmark 1,S1,res://assets/overlays/landmark_sample_1.png,A mysterious landmark,6
```

**Overlay Codes in Map Tiles**: The `initials` field is used to match overlay codes in the map tiles CSV. For example:
- `"G1-D1"` = grassland tile with desert landmark 1
- `"F2-S1"` = forest tile with sample landmark 1
- `"G1-D1-S1"` = grassland tile with desert landmark 1 and sample landmark 1

## Integration with Database Manager

The tool integrates with your existing `DatabaseManager` autoload to:
- Read current database state
- Clear and reseed tables
- Export current configurations

This ensures your CSV changes are properly applied to your game's database system. 