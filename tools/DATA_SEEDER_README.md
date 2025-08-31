# Data Seeder Tool

A tool for importing game data from CSV files into the Godot game database. This tool handles the import of **nodes**, **traits**, **backgrounds**, and **features** with special handling for JSON-formatted fields.

## 🚨 Important Notes

### Warning 1: Reserved Names
- **`trait`** is a reserved name in Godot 4, so we use **`trait_id`** instead in the database schema.

### Warning 2: JSON Fields
- Fields like `{'intelligence': 1}` are **JSON-formatted** and will be automatically converted to valid JSON for database storage.
- **Single quotes are supported** for Google Sheets compatibility - the tool automatically converts them to double quotes.

## 📁 File Structure

```
tools/
├── data_seeder.gd          # Main data seeder logic
├── data_seeder_ui.gd       # User interface
├── data_seeder.tscn        # Scene file
└── data/
    ├── nodes.csv           # Skill tree nodes
    ├── traits.csv          # Character traits
    ├── backgrounds.csv     # Character backgrounds
    └── features.csv        # Character features
```

## 🗃️ CSV Format

### Nodes CSV (`nodes.csv`)
```csv
name,icon_name,node_type,attribute_bonuses,master_attribute_bonuses,ability_bonuses,trait_id,skill_id,description
strength,strength,ATTRIBUTE,{'strength': 1},{},{},NULL,NULL,Physical strength and power
intelligence,intelligence,ATTRIBUTE,{'intelligence': 1},{},{},NULL,NULL,Reasoning and learning ability
```

**Columns:**
- `name`: Node identifier
- `icon_name`: Icon asset name
- `node_type`: ATTRIBUTE, ABILITY, or MASTER_ATTRIBUTE
- `attribute_bonuses`: JSON dict of attribute bonuses
- `master_attribute_bonuses`: JSON dict of master attribute bonuses
- `ability_bonuses`: JSON dict of ability bonuses
- `trait_id`: Associated trait ID (or NULL)
- `skill_id`: Associated skill ID (or NULL)
- `description`: Human-readable description

### Traits CSV (`traits.csv`)
```csv
name,description,icon_name,attribute_bonuses,ability_bonuses,skill_bonuses,other_effects
Elf Blood,You have elven heritage,elf_blood,{'agility': 1},{'perception': 1},{'arcana': 1},Long lifespan
```

**Columns:**
- `name`: Trait identifier
- `description`: Human-readable description
- `icon_name`: Icon asset name
- `attribute_bonuses`: JSON dict of attribute bonuses
- `ability_bonuses`: JSON dict of ability bonuses
- `skill_bonuses`: JSON dict of skill bonuses
- `other_bonuses`: Special effects description

### Backgrounds CSV (`backgrounds.csv`)
```csv
name,description,attribute_bonuses,ability_bonuses,skill_bonuses,starting_equipment
Soldier,You served in the military,{'strength': 1, 'vitality': 1},{'athletics': 1},{'survival': 1},Weapon and armor
```

**Columns:**
- `name`: Background identifier
- `description`: Human-readable description
- `attribute_bonuses`: JSON dict of attribute bonuses
- `ability_bonuses`: JSON dict of ability bonuses
- `skill_bonuses`: JSON dict of skill bonuses
- `starting_equipment`: Starting equipment description

### Features CSV (`features.csv`)
```csv
name,description,icon_name,trait_id,attribute_bonuses,ability_bonuses,skill_bonuses,other_effects
Elf Blood,You have elven heritage,elf_blood,1,{'agility': 1},{'perception': 1},{'arcana': 1},Long lifespan
```

**Columns:**
- `name`: Feature identifier
- `description`: Human-readable description
- `icon_name`: Icon asset name
- `trait_id`: Associated trait ID
- `attribute_bonuses`: JSON dict of attribute bonuses
- `ability_bonuses`: JSON dict of ability bonuses
- `skill_bonuses`: JSON dict of skill bonuses
- `other_bonuses`: Special effects description

## 🔧 JSON Field Format

### Supported JSON Syntax
The tool automatically converts these formats to valid JSON:

**Single quotes (Google Sheets compatible):**
```csv
{'strength': 1, 'vitality': 1}
{'intelligence': 1}
{}
```

**Empty objects:**
```csv
{}
NULL
```

### JSON Field Types
- **`attribute_bonuses`**: Dictionary mapping attribute names to bonus values
- **`master_attribute_bonuses`**: Dictionary mapping master attribute names to bonus values
- **`ability_bonuses`**: Dictionary mapping ability names to bonus values
- **`skill_bonuses`**: Dictionary mapping skill names to bonus values
- **`other_bonuses`**: String description of special effects
- **`starting_equipment`**: String description of starting equipment

## 🚀 Usage

### 1. Open the Tool
- Open the `data_seeder.tscn` scene in Godot
- The tool will automatically connect to the DatabaseManager

### 2. Create Sample Data
- Click **"Create Sample CSV Files"** to generate sample CSV files
- Use **"Force Create Sample CSV Files"** to overwrite existing files

### 3. Import Data
- **Individual imports**: Use specific buttons for nodes, traits, backgrounds, or features
- **Bulk import**: Use **"Seed All Data from CSV"** to import everything at once

### 4. Clear Data
- Use **"Clear All Game Data"** to remove all imported data

## 🛠️ Technical Details

### Database Integration
- Connects to `DatabaseManager` singleton
- Uses SQLite database (`game_data.db`)
- Handles table creation and data insertion

### JSON Processing
- **Single quote conversion**: `{'key': value}` → `{"key": value}`
- **Float to integer conversion**: `1.0` → `1` (for whole numbers)
- **Error handling**: Graceful fallback for malformed JSON

### CSV Parsing
- **Simple comma splitting** for basic CSV parsing
- **Header detection** for automatic column mapping
- **NULL handling** for empty database fields

### Error Handling
- **File access errors**: Logs and continues
- **JSON parsing errors**: Logs and uses empty object fallback
- **Database errors**: Logs and continues with next record

## 📝 Example Workflow

1. **Prepare CSV files** with your game data
2. **Open the Data Seeder tool** in Godot
3. **Create sample files** if you need templates
4. **Import your data** using the appropriate buttons
5. **Verify** the data appears in your game

## 🔍 Debug Information

The tool provides detailed logging:
- CSV file reading progress
- JSON parsing results
- Database insertion status
- Error messages and warnings

## 🚨 Troubleshooting

### Common Issues

**"DatabaseManager not found"**
- Ensure the DatabaseManager singleton is running
- Check that the scene is properly loaded

**"No data found in CSV"**
- Verify CSV file exists in `tools/data/`
- Check CSV format and headers
- Ensure file is not empty

**JSON parsing errors**
- Verify JSON syntax in CSV cells
- Check for unmatched quotes or brackets
- Use the sample CSV files as templates

**Database errors**
- Check database file permissions
- Verify table schema exists
- Check for duplicate key constraints

## 📚 Dependencies

- **Godot 4.x**
- **SQLite plugin** (godot-sqlite)
- **DatabaseManager** singleton
- **FileAccess** and **DirAccess** for file operations

## 🔄 Version History

- **v1.0**: Initial release with CSV import functionality
- **v1.1**: Added JSON field handling and Google Sheets compatibility
- **v1.2**: Enhanced error handling and debug logging
