# Tools

This directory contains various development and content creation tools for the Ascension game.

## Skill Tree Creator

The Skill Tree Creator is a visual tool for designing and editing skill trees. It has been enhanced with database integration to manage skill tree nodes.

### Features

- **Visual Node Placement**: Place nodes from the database on a canvas
- **Node Connections**: Connect nodes to create skill tree relationships
- **Node Editing**: Edit node descriptions and properties
- **Database Integration**: Store and retrieve nodes and skill trees from the SQLite database
- **Node Management**: Select existing nodes from the database and add them to skill trees

### Database Integration

The tool now integrates with the game's SQLite database through two main tables:

**Nodes Table:**
```sql
CREATE TABLE nodes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon_name TEXT,
    node_type TEXT NOT NULL DEFAULT 'PASSIVE',
    trait_id INTEGER,
    skill_id INTEGER,
    attribute_bonuses JSON,
    FOREIGN KEY (trait_id) REFERENCES traits(id),
    FOREIGN KEY (skill_id) REFERENCES abilities(id)
);
```

**Skill Trees Table:**
```sql
CREATE TABLE skill_tree (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    data JSON NOT NULL,
    parents TEXT
);
```

### Using the Tool

1. **Launch the Tool**: Open `skill_tree_creator.tscn` in Godot
2. **Node Management Panel**: 
   - **Database Node Selector**: Choose from existing nodes in the database
   - **Add Button**: Add the selected database node to the skill tree
   - **Refresh Button**: Refresh the database node list
3. **Add Database Nodes**:
   - Select an existing node from the database dropdown
   - Click "Add Database Node" to add it to the skill tree
   - The node name is automatically populated from the database
4. **Visual Editor**:
   - Use Place mode to add nodes to the canvas
   - Use Connect mode to create connections between nodes
   - Use Edit mode to modify existing nodes
5. **Skill Tree Operations**:
   - Save skill trees to the database
   - Load existing skill trees from the database
   - Clear the current canvas

### Node Types

- **Passive**: Passive abilities that provide constant bonuses
- **Active**: Active abilities that can be used in combat
- **Improvement**: Nodes that enhance other abilities
- **Master Attribute**: Major attribute improvements
- **Attribute**: Standard attribute bonuses
- **Empty**: Placeholder nodes for future content

### Database Methods

The tool provides several database operations:

- `save_node()`: Create new nodes in the database
- `get_all_nodes()`: Retrieve all available nodes
- `get_node_by_id()`: Get specific node by ID
- `update_node()`: Modify existing nodes
- `delete_node()`: Remove nodes from database
- `get_nodes_by_trait()`: Find nodes associated with specific traits
- `get_nodes_by_skill()`: Find nodes associated with specific skills

### Sample Data

The database is automatically seeded with sample nodes including:
- Combat Mastery (with trait association and damage bonuses)
- Arcane Knowledge (with skill association and mana bonuses)
- Stealth Expert (with trait association and dodge bonuses)
- Leadership (standalone node with willpower bonuses)

### Technical Details

- Built with Godot 4.x
- Uses SQLite for persistent storage
- JSON fields for flexible attribute bonus storage
- Foreign key relationships with traits and abilities tables
- Automatic database initialization and seeding

## Map Seeder

A tool for creating and managing game maps with tile-based systems.

## Skill Tree Editor

The core visual editing component used by the Skill Tree Creator.

## Skill Node

Individual node components used in skill trees. 