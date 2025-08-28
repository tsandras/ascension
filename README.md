# Ascension

A data-driven RPG character creation system built with Godot 4.4.

## 🎮 Project Overview

Ascension is an RPG featuring a comprehensive character creation system with attributes and abilities allocation. The project uses a clean, scalable architecture with database-driven design for easy content management.

## 🏗️ Architecture

### Project Structure
```
ascension/
├── scenes/
│   ├── character_creation/     # Character creation flow

│   │   ├── abilities_allocation.tscn
│   │   └── abilities_allocation.gd
│   └── ui/                    # Main UI scenes
│       ├── main_menu.tscn
│       └── main_menu.gd
├── core/
│   ├── managers/              # System managers
│   │   ├── database_manager.gd
│   │   ├── allocation_manager.gd
│   │   └── theme_manager.gd
│   └── ui/                    # UI utilities
│       ├── ui_manager.gd
│       └── ui_constants.gd
├── data/                      # Data files
│   ├── game_data.db
│   └── default_theme.tres
└── project.godot
```

### Key Systems

#### 📊 Database-Driven Design
- **SQLite Database**: `data/game_data.db` stores all game content
- **Tables**: `attributes` and `abilities` with configurable values
- **Dynamic UI**: All allocation screens generated from database data
- **No Hardcoded Content**: Easy to add/modify attributes and abilities

#### 🎯 Character Creation Flow
1. **Attributes Allocation**: 5 points to distribute among 6 attributes (base 0, max 6)
2. **Race Selection**: Choose from 4 races, each with unique traits and bonuses
3. **Background Selection**: Choose from 8 backgrounds, each with ability bonuses
4. **Trait System**: Visual trait icons with tooltips showing descriptions
5. **Validation**: Must spend all points and make all selections to proceed

#### 🎨 UI System
- **Constants-Based**: All UI sizes defined in `ui_constants.gd`
- **Responsive Design**: Scales to different screen sizes
- **Theme System**: Centralized styling via `default_theme.tres`
- **Utility Functions**: Common UI operations in `ui_manager.gd`

## 🛠️ Technical Requirements

### Engine
- **Godot 4.4+**
- **Forward Plus** rendering

### Dependencies
- **godot-sqlite**: SQLite database integration
  - Install via Godot Asset Library
  - Search for "SQLite" by "2shady4u"
  - Enable in Project Settings → Plugins

## 🚀 Setup Instructions

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd ascension
```

### 2. Install Dependencies
1. Open project in Godot 4.4+
2. Go to **AssetLib** tab
3. Search for **"SQLite"**
4. Install **"godot-sqlite"** by 2shady4u
5. Enable plugin in **Project → Project Settings → Plugins**

## 🔧 Configuration

### UI Scaling
All UI constants defined in `core/ui/ui_constants.gd`:
```gdscript
# Button sizes
const BUTTON_PLUS_MINUS = Vector2(50, 50)
const BUTTON_NAVIGATION = Vector2(150, 60)

# Container sizes  

const CONTAINER_ABILITIES_ALLOCATION = Vector2(800, 900)
```

### Screen Settings
- **Resolution**: 1280x720 (scales to fullscreen)
- **Stretch Mode**: canvas_items (UI responsive)
- **Window Mode**: Maximized, resizable

## 🗂️ File Dependencies

| File | Depends On |
|------|------------|
| All scenes | `core/ui/ui_manager.gd`, `core/ui/ui_constants.gd` |
| All managers | `core/managers/database_manager.gd` |
| Database operations | `addons/godot-sqlite/` plugin |
| UI styling | `data/default_theme.tres` |

---

*This project demonstrates scalable game architecture with data-driven design, suitable for larger RPG development.* 